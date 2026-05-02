import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'progress_bar.dart';
import 'status_badge.dart';

class CooperativeCard extends StatelessWidget {
  final String name;
  final String objective;
  final double collectedAmount;
  final double targetAmount;
  final int memberCount;
  final String status;
  final VoidCallback onTap;

  const CooperativeCard({
    super.key,
    required this.name,
    required this.objective,
    required this.collectedAmount,
    required this.targetAmount,
    required this.memberCount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = collectedAmount / targetAmount;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                      name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  StatusBadge(
                    label: status,
                    type: status == 'Actif' ? BadgeType.success : BadgeType.info,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                objective,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ProgressBar(
                progress: progress,
                label: 'Collecté',
                trailing: '${(progress * 100).toInt()}%',
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(
                    icon: Icons.payments_outlined,
                    label: '${collectedAmount.toInt()} XOF',
                  ),
                  _InfoItem(
                    icon: Icons.people_outline,
                    label: '$memberCount membres',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
