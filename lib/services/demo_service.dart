import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import 'cooperative_service.dart';
import 'vote_service.dart';

class DemoService {
  final CooperativeService _cooperativeService;
  final VoteService _voteService;

  DemoService(this._cooperativeService, this._voteService);

  Future<void> seedDemoData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Créer une coopérative phare
    final coopId = await _cooperativeService.createCooperative(
      name: 'Solaire Lomé Centre',
      description: 'Projet pilote d\'électrification du marché central de Lomé par mini-réseau solaire.',
      goalAmount: 1500000,
      deadline: DateTime.now().add(const Duration(days: 30)),
    );

    // 2. Ajouter quelques cotisations fictives (non-blockchain pour la rapidité du seed)
    await supabase.from('contributions').insert([
      {
        'cooperative_id': coopId,
        'user_id': userId,
        'amount': 250000,
        'payment_method': 'mobile_money',
        'blockchain_status': 'confirmed',
        'tx_hash': '0x${List.generate(64, (i) => 'abcdef0123456789'[ (i % 16) ]).join()}',
      },
      {
        'cooperative_id': coopId,
        'user_id': userId,
        'amount': 50000,
        'payment_method': 'cash',
        'blockchain_status': 'confirmed',
        'tx_hash': '0x${List.generate(64, (i) => '1234567890abcdef'[ (i % 16) ]).join()}',
      },
    ]);

    // 3. Créer des propositions de vote
    await _voteService.createProposal(
      coopId: coopId,
      title: 'Achat Batteries Lithium 10kWh',
      description: 'Système de stockage pour assurer la fourniture d\'énergie la nuit.',
      supplier: 'EcoWatt Togo',
      estimatedCost: 850000,
      voteDeadline: DateTime.now().add(const Duration(days: 7)),
    );

    await _voteService.createProposal(
      coopId: coopId,
      title: 'Installation Panneaux 400W',
      description: 'Lot de 20 panneaux monocristallins haute performance.',
      supplier: 'SolarGroup SARL',
      estimatedCost: 400000,
      voteDeadline: DateTime.now().add(const Duration(days: 14)),
    );
  }
}

final demoServiceProvider = Provider<DemoService>((ref) {
  return DemoService(
    ref.watch(cooperativeServiceProvider),
    ref.watch(voteServiceProvider),
  );
});
