import "package:flutter/material.dart";

import "screens/indoor/indoor_page.dart";
import "screens/login_page.dart";

void main() {
  const bool isLoggedIn = true;
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF800020)),
        useMaterial3: true,
      ),
      initialRoute: "/",
      onGenerateRoute: (settings) {
        final name = settings.name ?? "/";

        // Home
        if (name == "/") {
          return MaterialPageRoute(
            builder: (_) => HomePage(isLoggedIn: isLoggedIn),
          );
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
          builder: (_) => const Scaffold(
            body: Center(child: Text("404")),
          ),
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

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF800020),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
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
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.50,
              child: Image.asset(
                "assets/images/concordia.png",
                fit: BoxFit.cover,
                color: const Color(0xFF800020).withOpacity(0.45),
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
