import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

// ── Provider global de session ──────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  // Écoute les changements d'auth et se reconstruit automatiquement
  ref.watch(authStateProvider);
  return supabase.auth.currentUser;
});

// ── Service Auth ─────────────────────────────────────────
class AuthService {
  // Connexion Email + Mot de passe
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Inscription Email + Mot de passe
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? phone,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': displayName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    // Mettre à jour le profil avec le numéro si fourni
    if (response.user != null && phone != null && phone.isNotEmpty) {
      await supabase
          .from('profiles')
          .update({'phone': phone, 'display_name': displayName}).eq(
              'id', response.user!.id);
    }

    return response;
  }

  // Connexion Google
  Future<bool> signInWithGoogle() async {
    return await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.coopenergy://login-callback',
    );
  }

  // Mot de passe oublié
  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  // Déconnexion
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Utilisateur courant
  User? get currentUser => supabase.auth.currentUser;

  // Session active ?
  bool get isAuthenticated => currentUser != null;
}

// Provider du service
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
