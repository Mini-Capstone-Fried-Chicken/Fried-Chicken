import 'package:campus_app/features/calendar/services/google_calendar_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

class FakeAuthClient extends AuthClient {
  bool closed = false;

  @override
  void close() {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeGoogleSignInClientAuthorization extends Fake
    implements GoogleSignInClientAuthorization {
  final AuthClient? clientToReturn;

  FakeGoogleSignInClientAuthorization({this.clientToReturn});

  @override
  AuthClient? authClient({required List<String> scopes}) {
    return clientToReturn;
  }
}

class FakeGoogleSignedInUserGateway implements GoogleSignedInUserGateway {
  GoogleSignInClientAuthorization? authorizationToReturn;
  bool authorizeScopesCalled = false;
  List<String>? authorizeScopesArgs;
  List<String>? authorizationForScopesArgs;

  FakeGoogleSignedInUserGateway({this.authorizationToReturn});

  @override
  Future<GoogleSignInClientAuthorization?> authorizationForScopes(
    List<String> scopes,
  ) async {
    authorizationForScopesArgs = scopes;
    return authorizationToReturn;
  }

  @override
  Future<void> authorizeScopes(List<String> scopes) async {
    authorizeScopesCalled = true;
    authorizeScopesArgs = scopes;
  }

  @override
  AuthClient? authClientFromAuthorization(
    GoogleSignInClientAuthorization authorization, {
    List<String>? scopes,
  }) {
    if (authorization is FakeGoogleSignInClientAuthorization) {
      return authorization.clientToReturn;
    }
    return null;
  }
}

class FakeGoogleSignInGateway implements GoogleSignInGateway {
  bool initializeCalled = false;
  bool authenticateCalled = false;
  bool attemptRestoreCalled = false;
  bool signOutCalled = false;
  bool disconnectCalled = false;

  String? lastClientId;
  String? lastServerClientId;
  List<String>? lastScopeHint;

  GoogleSignedInUserGateway? accountToReturn;
  bool returnNullAttempt = false;

  @override
  Future<void> initialize({String? clientId, String? serverClientId}) async {
    initializeCalled = true;
    lastClientId = clientId;
    lastServerClientId = serverClientId;
  }

  @override
  Future<GoogleSignedInUserGateway?> authenticate({
    required List<String> scopeHint,
  }) async {
    authenticateCalled = true;
    lastScopeHint = scopeHint;
    return accountToReturn;
  }

  @override
  Future<GoogleSignedInUserGateway?> attemptLightweightAuthentication() async {
    attemptRestoreCalled = true;
    return returnNullAttempt ? null : accountToReturn;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }
}

void main() {
  group('GoogleCalendarAuthService', () {
    late FakeGoogleSignInGateway fakeGateway;
    late GoogleCalendarAuthService service;

    setUp(() {
      fakeGateway = FakeGoogleSignInGateway();
      service = GoogleCalendarAuthService(signInGateway: fakeGateway);
    });

    test('initialize only runs once', () async {
      await service.initialize(serverClientId: 'abc');
      await service.initialize(serverClientId: 'def');

      expect(fakeGateway.initializeCalled, isTrue);
      expect(fakeGateway.lastServerClientId, 'abc');
    });

    test('signIn returns false when account is null', () async {
      fakeGateway.accountToReturn = null;

      final result = await service.signIn();

      expect(result, isFalse);
      expect(fakeGateway.initializeCalled, isTrue);
      expect(fakeGateway.authenticateCalled, isTrue);
      expect(fakeGateway.lastScopeHint, GoogleCalendarAuthService.scopes);
    });

    test(
      'signIn returns true and authorizes scopes when account exists',
      () async {
        final fakeUser = FakeGoogleSignedInUserGateway();
        fakeGateway.accountToReturn = fakeUser;

        final result = await service.signIn();

        expect(result, isTrue);
        expect(fakeUser.authorizeScopesCalled, isTrue);
        expect(fakeUser.authorizeScopesArgs, GoogleCalendarAuthService.scopes);
      },
    );

    test(
      'restorePreviousSignIn returns false when no account is restored',
      () async {
        fakeGateway.returnNullAttempt = true;

        final result = await service.restorePreviousSignIn();

        expect(result, isFalse);
        expect(fakeGateway.attemptRestoreCalled, isTrue);
      },
    );

    test(
      'restorePreviousSignIn authorizes scopes when authorization is null',
      () async {
        final fakeUser = FakeGoogleSignedInUserGateway(
          authorizationToReturn: null,
        );
        fakeGateway.accountToReturn = fakeUser;

        final result = await service.restorePreviousSignIn();

        expect(result, isTrue);
        expect(fakeGateway.attemptRestoreCalled, isTrue);
        expect(fakeUser.authorizeScopesCalled, isTrue);
        expect(
          fakeUser.authorizationForScopesArgs,
          GoogleCalendarAuthService.scopes,
        );
      },
    );

    test(
      'restorePreviousSignIn does not re-authorize when authorization exists',
      () async {
        final fakeUser = FakeGoogleSignedInUserGateway(
          authorizationToReturn: FakeGoogleSignInClientAuthorization(),
        );
        fakeGateway.accountToReturn = fakeUser;

        final result = await service.restorePreviousSignIn();

        expect(result, isTrue);
        expect(fakeUser.authorizeScopesCalled, isFalse);
      },
    );

    test(
      'getAuthenticatedClient returns null when no user is signed in',
      () async {
        final client = await service.getAuthenticatedClient();

        expect(client, isNull);
      },
    );

    test(
      'getAuthenticatedClient returns null when authorization is null',
      () async {
        final fakeUser = FakeGoogleSignedInUserGateway(
          authorizationToReturn: null,
        );
        fakeGateway.accountToReturn = fakeUser;

        await service.signIn();
        final client = await service.getAuthenticatedClient();

        expect(client, isNull);
      },
    );

    test(
      'getAuthenticatedClient returns auth client when authorization exists',
      () async {
        final fakeClient = FakeAuthClient();
        final fakeAuthorization = FakeGoogleSignInClientAuthorization(
          clientToReturn: fakeClient,
        );
        final fakeUser = FakeGoogleSignedInUserGateway(
          authorizationToReturn: fakeAuthorization,
        );
        fakeGateway.accountToReturn = fakeUser;

        await service.signIn();
        final client = await service.getAuthenticatedClient();

        expect(client, same(fakeClient));
      },
    );

    test('signOut clears user and calls gateway signOut', () async {
      await service.signOut();

      expect(fakeGateway.signOutCalled, isTrue);
    });

    test('disconnect clears user and calls gateway disconnect', () async {
      await service.disconnect();

      expect(fakeGateway.disconnectCalled, isTrue);
    });
  });
}
