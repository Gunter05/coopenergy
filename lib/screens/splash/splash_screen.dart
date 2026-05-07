import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Attendre que Flutter soit prêt
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Écouter le premier événement de session
    final subscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
      if (!mounted) return;

      final session = data.session;
      if (session != null) {
        context.go('/home');
      } else {
        context.go('/auth');
      }
    });

    // Timeout de sécurité — si aucun événement après 3s, aller vers auth
    await Future.delayed(const Duration(seconds: 3));
    subscription.cancel();

    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    context.go(session != null ? '/home' : '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.solar_power, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'CoopEnergie',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coopératives solaires transparentes',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
