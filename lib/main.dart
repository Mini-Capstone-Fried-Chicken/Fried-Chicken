import "package:campus_app/app/campus_app.dart";
import "package:clarity_flutter/clarity_flutter.dart";
import "package:campus_app/services/firebase/firebase_options.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

Future<void> main() async {
  const clarityProjectId = String.fromEnvironment("CLARITY_PROJECT_ID");
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') {
      rethrow;
    }
    Firebase.app();
  }

  final app = const CampusApp();
  final isMobileTarget = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  if (isMobileTarget && clarityProjectId.isNotEmpty) {
    runApp(
      ClarityWidget(
        app: app,
        clarityConfig: ClarityConfig(
          projectId: clarityProjectId,
          logLevel: kDebugMode ? LogLevel.Verbose : LogLevel.None,
        ),
      ),
    );
    return;
  }

  runApp(app);
}
