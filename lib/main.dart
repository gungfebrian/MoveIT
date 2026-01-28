import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile/screens/home_page.dart';
import 'package:mobile/screens/onboarding_page.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/theme/app_theme.dart';
// Perbaikan: pastikan mengarah ke nama file yang dihasilkan FlutterFire CLI
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase menggunakan DefaultFirebaseOptions dari firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MoveIt',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // Gunakan AuthWrapper untuk menentukan halaman awal
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder mendengarkan perubahan status otentikasi
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika sedang menunggu status (misalnya saat aplikasi baru dibuka)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            ),
          );
        }

        // Jika user sudah login (snapshot memiliki data)
        if (snapshot.hasData) {
          return const HomePage();
        }

        // Jika user belum login
        return const OnboardingScreen();
      },
    );
  }
}
