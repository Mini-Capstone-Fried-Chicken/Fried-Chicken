import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' show AuthClient;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleCalendarAuthService {
  GoogleCalendarAuthService();

  static final GoogleCalendarAuthService instance = GoogleCalendarAuthService();

  static const List<String> scopes = [
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  static const String webServerClientId =
      '749522791928-hfsass6fssn6k82g5qiauseoaqmmvgod.apps.googleusercontent.com';

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  bool _initialized = false;

  Future<void> initialize({
    String? clientId,
    String? serverClientId,
  }) async {
    if (_initialized) return;

    await _signIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    _initialized = true;
  }

  Future<bool> restorePreviousSignIn() async {
    await initialize(serverClientId: webServerClientId);

    final account = await _signIn.attemptLightweightAuthentication();
    _currentUser = account;

    if (account == null) return false;

    final authorization =
        await account.authorizationClient.authorizationForScopes(scopes);

    if (authorization == null) {
      await account.authorizationClient.authorizeScopes(scopes);
    }

    return true;
  }

  Future<bool> signIn() async {
    await initialize(serverClientId: webServerClientId);

    final account = await _signIn.authenticate(
      scopeHint: scopes,
    );

    _currentUser = account;
    if (account == null) return false;

    await account.authorizationClient.authorizeScopes(scopes);
    return true;
  }

  Future<AuthClient?> getAuthenticatedClient() async {
    final user = _currentUser;
    if (user == null) return null;

    final authorization =
        await user.authorizationClient.authorizationForScopes(scopes);

    if (authorization == null) return null;

    return authorization.authClient(scopes: scopes);
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _signIn.signOut();
  }

  Future<void> disconnect() async {
    _currentUser = null;
    await _signIn.disconnect();
  }
}