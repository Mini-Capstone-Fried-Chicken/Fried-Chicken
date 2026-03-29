import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;

abstract class GoogleSignedInUserGateway {
  Future<GoogleSignInClientAuthorization?> authorizationForScopes(
    List<String> scopes,
  );

  Future<void> authorizeScopes(List<String> scopes);

  AuthClient? authClientFromAuthorization(
    GoogleSignInClientAuthorization authorization, {
    List<String>? scopes,
  });
}

abstract class GoogleSignInGateway {
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
  });

  Future<GoogleSignedInUserGateway?> authenticate({
    required List<String> scopeHint,
  });

  Future<GoogleSignedInUserGateway?> attemptLightweightAuthentication();

  Future<void> signOut();

  Future<void> disconnect();
}

class _GoogleSignedInUserAdapter implements GoogleSignedInUserGateway {
  final GoogleSignInAccount _account;

  _GoogleSignedInUserAdapter(this._account);

  @override
  Future<GoogleSignInClientAuthorization?> authorizationForScopes(
    List<String> scopes,
  ) {
    return _account.authorizationClient.authorizationForScopes(scopes);
  }

  @override
  Future<void> authorizeScopes(List<String> scopes) {
    return _account.authorizationClient.authorizeScopes(scopes);
  }

  @override
  AuthClient? authClientFromAuthorization(
    GoogleSignInClientAuthorization authorization, {
    List<String>? scopes,
  }) {
    return authorization.authClient(scopes: scopes ?? const []);
  }
}

class DefaultGoogleSignInGateway implements GoogleSignInGateway {
  final GoogleSignIn _signIn = GoogleSignIn.instance;

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
  }) {
    return _signIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
  }

  @override
  Future<GoogleSignedInUserGateway?> authenticate({
    required List<String> scopeHint,
  }) async {
    final account = await _signIn.authenticate(scopeHint: scopeHint);
    return _GoogleSignedInUserAdapter(account);
  }

  @override
  Future<GoogleSignedInUserGateway?> attemptLightweightAuthentication() async {
    final future = _signIn.attemptLightweightAuthentication();
    final account = future == null ? null : await future;
    if (account == null) return null;
    return _GoogleSignedInUserAdapter(account);
  }

  @override
  Future<void> signOut() {
    return _signIn.signOut();
  }

  @override
  Future<void> disconnect() {
    return _signIn.disconnect();
  }
}

class GoogleCalendarAuthService {
  GoogleCalendarAuthService({
    GoogleSignInGateway? signInGateway,
  }) : _signInGateway = signInGateway ?? DefaultGoogleSignInGateway();

  static final GoogleCalendarAuthService instance = GoogleCalendarAuthService();

  static const List<String> scopes = [
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  static const String webServerClientId =
      '749522791928-hfsass6fssn6k82g5qiauseoaqmmvgod.apps.googleusercontent.com';

  final GoogleSignInGateway _signInGateway;
  GoogleSignedInUserGateway? _currentUser;
  bool _initialized = false;

  Future<void> initialize({
    String? clientId,
    String? serverClientId,
  }) async {
    if (_initialized) return;

    await _signInGateway.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    _initialized = true;
  }

  Future<bool> restorePreviousSignIn() async {
    await initialize(serverClientId: webServerClientId);

    final account = await _signInGateway.attemptLightweightAuthentication();
    _currentUser = account;

    if (account == null) return false;

    final authorization = await account.authorizationForScopes(scopes);

    if (authorization == null) {
      await account.authorizeScopes(scopes);
    }

    return true;
  }

  Future<bool> signIn() async {
    await initialize(serverClientId: webServerClientId);

    final account = await _signInGateway.authenticate(
      scopeHint: scopes,
    );

    _currentUser = account;
    if (account == null) return false;

    await account.authorizeScopes(scopes);
    return true;
  }

  Future<AuthClient?> getAuthenticatedClient() async {
    final user = _currentUser;
    if (user == null) return null;

    final authorization = await user.authorizationForScopes(scopes);

    if (authorization == null) return null;

    return user.authClientFromAuthorization(
      authorization,
      scopes: scopes,
    );
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _signInGateway.signOut();
  }

  Future<void> disconnect() async {
    _currentUser = null;
    await _signInGateway.disconnect();
  }
}