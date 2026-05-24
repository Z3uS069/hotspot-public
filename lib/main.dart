import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/superadmin/super_admin_dashboard.dart';
import 'screens/user/user_shell.dart';
import 'screens/admin/pending_approval_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const HotspotApp());
}

final supabase = Supabase.instance.client;

class HotspotApp extends StatelessWidget {
  const HotspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotspot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
        ColorScheme.fromSeed(seedColor: const Color(0xFF5B5BFF)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF111111),
      body: Center(
        child: CircularProgressIndicator(
            color: Color(0xFFDEFF6E), strokeWidth: 2),
      ),
    );
  }
}