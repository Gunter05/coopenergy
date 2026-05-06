import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/cooperative.dart';

class CooperativeService {
  // ── Lecture ─────────────────────────────────────────

  // Récupère toutes les coopératives de l'utilisateur connecté
  Future<List<Cooperative>> fetchMyCooperatives() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('cooperative_summary')
        .select()
        .order('created_at', ascending: false);

    return (data as List).map((e) => Cooperative.fromJson(e)).toList();
  }

  // Stream temps réel — se met à jour à chaque cotisation
  Stream<List<Cooperative>> watchMyCooperatives() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return supabase
        .from('cooperatives')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => Cooperative.fromJson(e)).toList());
  }

  // Récupère une coopérative par son ID
  Future<Cooperative?> fetchById(String coopId) async {
    final data = await supabase
        .from('cooperative_summary')
        .select()
        .eq('id', coopId)
        .maybeSingle();

    if (data == null) return null;
    return Cooperative.fromJson(data);
  }

  // ── Statistiques globales pour le dashboard ──────────

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return {};

    // Total collecté sur toutes mes coopératives
    final contribs = await supabase
        .from('contributions')
        .select('amount')
        .eq('user_id', userId);

    double totalContributed = 0;
    for (final c in contribs as List) {
      totalContributed += (c['amount'] as num).toDouble();
    }

    // Nombre de coopératives actives
    final coops = await supabase
        .from('cooperative_members')
        .select('cooperative_id')
        .eq('user_id', userId);

    // Votes en attente
    final openProposals = await supabase
        .from('proposals')
        .select('id')
        .eq('status', 'open')
        .gt('vote_deadline', DateTime.now().toIso8601String());

    return {
      'total_contributed': totalContributed,
      'active_coops': (coops as List).length,
      'pending_votes': (openProposals as List).length,
    };
  }

  // ── Activité récente ─────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchRecentActivity() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await supabase
        .from('contributions')
        .select('amount, created_at, cooperatives(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(5);

    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<String> createCooperative({
    required String name,
    required String description,
    required double goalAmount,
    DateTime? deadline,
    List<String> memberUserIds = const [],
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Non authentifié');

    // 1. Créer la coopérative
    final coop = await supabase
        .from('cooperatives')
        .insert({
          'name': name,
          'description': description.isEmpty ? null : description,
          'goal_amount': goalAmount,
          'deadline': deadline?.toIso8601String().split('T')[0],
          'created_by': userId,
        })
        .select()
        .single();

    final coopId = coop['id'] as String;

    // 2. Ajouter le créateur comme admin
    await supabase.from('cooperative_members').insert({
      'cooperative_id': coopId,
      'user_id': userId,
      'role': 'admin',
    });

    // 3. Ajouter les membres invités
    if (memberUserIds.isNotEmpty) {
      await supabase.from('cooperative_members').insert(
            memberUserIds
                .map((id) => {
                      'cooperative_id': coopId,
                      'user_id': id,
                      'role': 'member',
                    })
                .toList(),
          );
    }

    return coopId;
  }
}

// ── Providers ────────────────────────────────────────────

final cooperativeServiceProvider =
    Provider<CooperativeService>((ref) => CooperativeService());

final myCooperativesProvider = StreamProvider<List<Cooperative>>((ref) {
  return ref.watch(cooperativeServiceProvider).watchMyCooperatives();
});

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(cooperativeServiceProvider).fetchDashboardStats();
});

final recentActivityProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(cooperativeServiceProvider).fetchRecentActivity();
});
