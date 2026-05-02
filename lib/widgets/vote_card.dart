import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'primary_button.dart';
import 'status_badge.dart';

class VoteCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String supplier;
  final DateTime deadline;
  final bool hasVoted;
  final VoidCallback onVote;

  const VoteCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.supplier,
    required this.deadline,
    required this.hasVoted,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                StatusBadge(
                  label: hasVoted ? 'Déjà voté' : 'À voter',
                  type: hasVoted ? BadgeType.success : BadgeType.warning,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Prix estimé', value: price),
            _DetailRow(label: 'Fournisseur', value: supplier),
            _DetailRow(
              label: 'Date limite',
              value: '${deadline.day}/${deadline.month}/${deadline.year}',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: hasVoted ? 'Voir les résultats' : 'Voter maintenant',
              onPressed: onVote,
              isSecondary: hasVoted,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
