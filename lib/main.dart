import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";

import "firebase_options.dart";
import "screens/indoor/indoor_page.dart";
import "screens/login_page.dart";
import "widgets/main_app.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Map<String, String> indoorAssetsById = {
    // SVGs
    "MB-1": "assets/indoor_svg/MB-1.svg",
    "MB-S2": "assets/indoor_svg/MB-S2.svg",
    "Hall-8": "assets/indoor_svg/Hall-8.svg",
    "Hall-9": "assets/indoor_svg/Hall-9.svg",
    "VE-1": "assets/indoor_svg/VE-1.svg",
    "VE-2": "assets/indoor_svg/VE-2.svg",
    "VL-1": "assets/indoor_svg/VL-1.svg",
    "VL-2": "assets/indoor_svg/VL-2.svg",
    "h8": "assets/indoor_svg/h8.svg",

    // PNGs
    "CC1": "assets/indoor_svg/CC1.png",
    "Hall-1": "assets/indoor_svg/Hall-1.png",
    "Hall-2": "assets/indoor_svg/Hall-2.png",
    "LB-2": "assets/indoor_svg/LB-2.png",
    "LB-3": "assets/indoor_svg/LB-3.png",
    "LB-4": "assets/indoor_svg/LB-4.png",
    "LB-5": "assets/indoor_svg/LB-5.png",
  };

  String? _findAssetPath(String id) {
    final direct = indoorAssetsById[id];
    if (direct != null) return direct;

    final lower = id.toLowerCase();
    for (final entry in indoorAssetsById.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Campus Guide",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF76263D)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user != null) {
            return const MainApp(isLoggedIn: true);
          }
          return const SignInPage();
        },
      ),
      onGenerateRoute: (settings) {
        final name = settings.name ?? "/";

        // Home
        if (name == "/") {
          return MaterialPageRoute(builder: (_) => const SignInPage());
        }

        // Optional legacy route: just opens MB-1
        if (name == "/indoor-map") {
          final assetPath = _findAssetPath("MB-1");
          if (assetPath == null) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("MB-1 asset not found")),
              ),
            );
          }
          return MaterialPageRoute(
            builder: (_) => IndoorPage(id: "MB-1", assetPath: assetPath),
          );
        }

        if (name.startsWith("/indoor/")) {
          final id = name.replaceFirst("/indoor/", "").trim();
          final assetPath = _findAssetPath(id);

          if (assetPath == null || assetPath.isEmpty) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Indoor map not found")),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (_) => IndoorPage(id: id, assetPath: assetPath),
          );
        }

        // fallback
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text("404"))),
        );
      },
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      width: 200,
      height: 200, 
      "assets/images/logo.png",
      width: 180,
      height: 180,
      fit: BoxFit.contain,
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF76263D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final bool isLoggedIn;

  const HomePage({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.50,
              child: Image.asset(
                "assets/images/concordia.png",
                fit: BoxFit.cover,
                color: const Color(0xFF76263D).withOpacity(0.45),
                colorBlendMode: BlendMode.darken,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: <Widget>[
                  const Text(
                    "Welcome to Campus",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "your go-to map on campus",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 14),
                  const AppLogo(),
                  const SizedBox(height: 14),

                  AppButton(
                    text: "Get started",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, "/indoor/MB-1"),
                    child: const Text("Test Indoor Map (MB-1)"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
