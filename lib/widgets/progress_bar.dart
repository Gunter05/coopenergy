import 'package:flutter/material.dart';
import '../core/theme.dart';

class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final String? trailing;

  const ProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label != null || trailing != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF26C281)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
