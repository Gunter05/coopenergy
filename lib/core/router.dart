import 'package:coopenergy/core/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/cooperative/cooperative_list_screen.dart';
import '../screens/cooperative/cooperative_detail_screen.dart';
import '../screens/contribute/contribute_screen.dart';
import '../screens/vote/vote_screen.dart';
import '../screens/report/report_screen.dart';
import '../screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // En commentaire pour le prototype afin de faciliter la navigation
  // final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    // refreshListenable: GoRouterRefreshStream(
    //   supabase.auth.onAuthStateChange,
    // ),
    // redirect: (context, state) {
    //   final isAuth = supabase.auth.currentSession != null;
    //   final isOnAuthPage = state.matchedLocation == '/auth';
    //   final isOnSplash = state.matchedLocation == '/';
    //   final isOnOnboarding = state.matchedLocation == '/onboarding';

    //   if (isOnSplash || isOnOnboarding) return null;
    //   if (!isAuth && !isOnAuthPage) return '/auth';
    //   if (isAuth && isOnAuthPage) return '/home';
    //   return null;
    // },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/cooperatives', builder: (_, __) => const CooperativeListScreen()),
      GoRoute(
        path: '/cooperative/:id',
        builder: (context, state) => CooperativeDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/contribute', builder: (_, __) => const ContributeScreen()),
      GoRoute(path: '/votes', builder: (_, __) => const VoteScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

// Helper pour rafraîchir le router quand la session change
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
