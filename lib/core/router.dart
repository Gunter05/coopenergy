import 'package:coopenergy/core/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/cooperative/create_cooperative_screen.dart';
import '../screens/cooperative/cooperative_detail_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/cooperative/cooperative_list_screen.dart';
import '../screens/contribute/contribute_screen.dart';
import '../screens/vote/vote_screen.dart';
import '../screens/report/report_screen.dart';
import '../screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _SupabaseAuthNotifier(),
    redirect: (context, state) {
      final uri = Uri.base;
      final hasOAuthParams =
          uri.queryParameters.containsKey('access_token') ||
          uri.queryParameters.containsKey('code');
      if (hasOAuthParams) return null;

      final session = supabase.auth.currentSession;
      final isAuth  = session != null;
      final loc     = state.matchedLocation;

      if (loc == '/' || loc == '/onboarding') return null;
      if (!isAuth && loc != '/auth') return '/auth';
      if (isAuth  && loc == '/auth') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      
      // Coopératives
      GoRoute(path: '/cooperatives', builder: (_, __) => const CooperativeListScreen()),
      GoRoute(
        path: '/cooperative/create',
        builder: (_, __) => const CreateCooperativeScreen(),
      ),
      GoRoute(
        path: '/cooperative/:id',
        builder: (_, state) => CooperativeDetailScreen(
          coopId: state.pathParameters['id']!,
        ),
      ),

      // Autres
      GoRoute(path: '/contribute', builder: (_, __) => const ContributeScreen()),
      GoRoute(path: '/vote', builder: (_, __) => const VoteScreen()),
      GoRoute(path: '/report', builder: (_, __) => const ReportScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

class _SupabaseAuthNotifier extends ChangeNotifier {
  _SupabaseAuthNotifier() {
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn  ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.tokenRefreshed) {
        notifyListeners();
      }
    });
  }
}
