import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/vote_card.dart';

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votes en cours')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 2,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: VoteCard(
              title: index == 0 ? 'Achat Panneaux LG 400W' : 'Choix du Fournisseur B',
              description: index == 0
                  ? 'Proposition d\'achat de 20 panneaux solaires LG pour la phase 2.'
                  : 'Sélection du fournisseur local pour l\'installation technique.',
              price: index == 0 ? '450 000 XOF' : '150 000 XOF',
              supplier: index == 0 ? 'Solaire Plus SARL' : 'Energy Service Togo',
              deadline: DateTime.now().add(const Duration(days: 3)),
              hasVoted: index == 1,
              onVote: () => _showVoteOptions(context, index == 0),
            ),
          );
        },
      ),
    );
  }

  void _showVoteOptions(BuildContext context, bool canVote) {
    if (!canVote) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez déjà voté pour cette proposition.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exprimez votre vote',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              const Text('Chaque membre dispose d\'une voix égale.'),
              const SizedBox(height: 32),
              _VoteOption(
                label: 'Oui, j\'approuve',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              _VoteOption(
                label: 'Non, je refuse',
                icon: Icons.cancel_rounded,
                color: AppColors.error,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              _VoteOption(
                label: 'Je m\'abstiens',
                icon: Icons.remove_circle_rounded,
                color: AppColors.textSecondary,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _VoteOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _VoteOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surface),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.surface),
          ],
        ),
      ),
    );
  }
}
