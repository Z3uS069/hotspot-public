import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/supabase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/superadmin/super_admin_dashboard.dart';
import 'screens/user/user_shell.dart';
import 'screens/admin/pending_approval_screen.dart';
import 'utils/auth_guard.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, dynamic>> _getRouteData(String userId) async {
    Map<String, dynamic>? userRow;
    for (int attempt = 0; attempt < 4; attempt++) {
      try {
        userRow = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', userId)
            .maybeSingle(); // null if not found — never throws
      } catch (_) {
        userRow = null;
      }
      if (userRow != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Still nothing after retries — safe fallback
    if (userRow == null) {
      return {'role': 'user', 'space': <String, dynamic>{}};
    }

    final role = userRow['role'] as String? ?? 'user';

    // Space admin — fetch their space verification status too
    if (role == 'space_admin') {
      try {
        final spaces = await Supabase.instance.client
            .from('spaces')
            .select('id, name, address, is_verified, is_active')
            .eq('admin_id', userId)
            .limit(1);

        final spaceList = spaces as List;
        return {
          'role': role,
          'space': spaceList.isNotEmpty
              ? spaceList[0] as Map<String, dynamic>
              : <String, dynamic>{},
        };
      } catch (_) {
        // Space row not ready yet — pending screen handles empty space
        return {'role': role, 'space': <String, dynamic>{}};
      }
    }

    return {'role': role, 'space': <String, dynamic>{}};
  }

  Future<void> _saveFcmToken(String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();
      if (token == null) return;
      await Supabase.instance.client
          .from('user_fcm_tokens')
          .upsert({
        'user_id': userId,
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      debugPrint('FCM token saved');
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Foreground notification listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          'Foreground notification: ${message.notification?.title}');
    });

    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final session = snapshot.data?.session;
        if (session == null || isValidatingCredentials) {
          return const LoginScreen();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _getRouteData(session.user.id),
          builder: (context, routeSnap) {
            if (routeSnap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (routeSnap.hasError || routeSnap.data == null) {
              return const LoginScreen();
            }

            final role  = routeSnap.data!['role'] as String;
            final space = routeSnap.data!['space'] as Map<String, dynamic>;

            _saveFcmToken(session.user.id);

            if (role == 'super_admin') {
              return const SuperAdminDashboard();
            }

            if (role == 'space_admin') {
              if (space.isEmpty) {
                // Space row doesn't exist yet — show pending
                return const PendingApprovalScreen(space: {});
              }
              if (space['is_verified'] == true) {
                return const AdminDashboardScreen();
              }
              // Pending or rejected
              return PendingApprovalScreen(space: space);
            }

            return const UserShell();
          },
        );
      },
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