import "package:campus_app/app/campus_app.dart";
import "package:campus_app/features/settings/app_settings.dart";
import "package:campus_app/services/firebase/firebase_options.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";

Future<void> main() async {
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
  await AppSettingsController.restore();
  runApp(const CampusApp());
}
