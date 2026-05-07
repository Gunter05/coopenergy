import 'package:coopenergy/services/blockchain_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/proposal.dart';

class VoteService {
  Future<List<Proposal>> fetchProposals(String coopId) async {
    final userId = supabase.auth.currentUser?.id;
    final data = await supabase
        .from('proposals')
        .select('*, profiles(display_name)')
        .eq('cooperative_id', coopId)
        .order('created_at', ascending: false);

    final proposals = (data as List).map((e) => Proposal.fromJson(e)).toList();

    // Récupérer les votes de l'utilisateur connecté
    if (userId != null && proposals.isNotEmpty) {
      final ids = proposals.map((p) => p.id).toList();
      final votes = await supabase
          .from('votes')
          .select('proposal_id, choice')
          .eq('user_id', userId)
          .inFilter('proposal_id', ids);

      final voteMap = <String, Map<String, String?>>{};
      for (final v in votes as List) {
        voteMap[v['proposal_id'] as String] = {
          'choice': v['choice'] as String,
          'tx_hash': v['tx_hash'] as String?,
        };
      }

      return proposals.map((p) {
        final vote = voteMap[p.id];
        final json = {
          'id': p.id,
          'cooperative_id': p.cooperativeId,
          'title': p.title,
          'description': p.description,
          'supplier': p.supplier,
          'estimated_cost': p.estimatedCost,
          'vote_deadline': p.voteDeadline.toIso8601String(),
          'status': p.status,
          'yes_count': p.yesCount,
          'no_count': p.noCount,
          'abstain_count': p.abstainCount,
          'result_tx_hash': p.resultTxHash,
          'created_at': p.createdAt.toIso8601String(),
          'my_vote': vote?['choice'],
          'my_vote_tx_hash': vote?['tx_hash'],
        };
        return Proposal.fromJson(json);
      }).toList();
    }

    return proposals;
  }

  Future<String> castVote({
    required String proposalId,
    required String coopId,
    required String choice,
    required BlockchainService blockchainService,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Non authentifié');

    // Convertir le choix texte en int pour Solidity
    final choiceInt = switch (choice) {
      'yes' => 0,
      'no' => 1,
      'abstain' => 2,
      _ => throw Exception('Choix invalide'),
    };

    // 1. Enregistrer le vote en BDD avec statut pending
    final vote = await supabase
        .from('votes')
        .insert({
          'proposal_id': proposalId,
          'user_id': userId,
          'choice': choice,
          'blockchain_status': 'pending',
        })
        .select()
        .single();

    final voteId = vote['id'] as String;

    // 2. Enregistrer sur blockchain
    final txHash = await blockchainService.castVote(
      proposalId: proposalId,
      choice: choiceInt,
    );

    // 3. Mettre à jour avec le hash
    await supabase.from('votes').update({
      'tx_hash': txHash,
      'blockchain_status': 'confirmed',
    }).eq('id', voteId);

    return txHash;
  }

  Future<String> createProposal({
    required String coopId,
    required String title,
    required String description,
    required String supplier,
    required double estimatedCost,
    required DateTime voteDeadline,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Non authentifié');

    final data = await supabase
        .from('proposals')
        .insert({
          'cooperative_id': coopId,
          'title': title,
          'description': description,
          'supplier': supplier,
          'estimated_cost': estimatedCost,
          'vote_deadline': voteDeadline.toIso8601String(),
          'created_by': userId,
        })
        .select()
        .single();

    return data['id'] as String;
  }
}

final voteServiceProvider = Provider<VoteService>((ref) => VoteService());

final proposalsProvider =
    FutureProvider.family<List<Proposal>, String>((ref, coopId) {
  return ref.watch(voteServiceProvider).fetchProposals(coopId);
});
