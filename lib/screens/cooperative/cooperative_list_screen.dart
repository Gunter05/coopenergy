import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/cooperative_service.dart';
import '../../models/cooperative.dart';

class CooperativeListScreen extends ConsumerWidget {
  const CooperativeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coopsAsync = ref.watch(myCooperativesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Mes Coopératives',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/cooperative/create'),
          ),
        ],
      ),
      body: coopsAsync.when(
        data: (coops) => coops.isEmpty
            ? _buildEmptyState(context)
            : _buildList(context, coops),
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryGreen),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Erreur lors du chargement : $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Cooperative> coops) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: coops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final coop = coops[index];
        return _buildCoopCard(context, coop);
      },
    );
  }

  Widget _buildCoopCard(BuildContext context, Cooperative coop) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final progress = (coop.progressPercent / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => context.push('/cooperative/${coop.id}'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.solar_power,
                    color: primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coop.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(
                        '${coop.memberCount} membres · ${coop.contributionCount} cotisations',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(coop.status),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${fmt.format(coop.currentAmount)} FCFA',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                Text(
                  '${coop.progressPercent.toStringAsFixed(1)} % sur ${fmt.format(coop.goalAmount)} FCFA',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final config = {
      'active': {'label': 'Actif', 'color': primaryGreen},
      'completed': {'label': 'Complété', 'color': const Color(0xFF0D47A1)},
      'cancelled': {'label': 'Annulé', 'color': Colors.red},
    };
    final c = config[status] ?? {'label': status, 'color': Colors.grey};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (c['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        c['label'] as String,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: c['color'] as Color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.solar_power_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              'Aucune coopérative',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous ne faites partie d\'aucune coopérative pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/cooperative/create'),
              child: const Text('Créer une coopérative'),
            ),
          ],
        ),
      ),
    );
  }
}
