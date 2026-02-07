import "package:campus_app/app/campus_app.dart";
import "package:campus_app/services/firebase/firebase_options.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CampusApp());
}
