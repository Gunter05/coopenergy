import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rapports & Transparence')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Résumé Financier', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            _buildFinancialGrid(context),
            const SizedBox(height: 32),
            Text('Audit Blockchain', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            _buildAuditList(context),
            const SizedBox(height: 32),
            _buildExportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(label: 'Total Collecté', value: '1.2M XOF', color: AppColors.primary),
        _StatCard(label: 'Total Engagé', value: '450K XOF', color: AppColors.secondary),
        _StatCard(label: 'Solde Restant', value: '750K XOF', color: AppColors.accent),
        _StatCard(label: 'Rendement Est.', value: '+8%', color: AppColors.success),
      ],
    );
  }

  Widget _buildAuditList(BuildContext context) {
    final transactions = [
      {'id': '0x7a2...4f9', 'type': 'Cotisation', 'amount': '+5 000 XOF', 'status': 'Confirmé'},
      {'id': '0x3b1...8e2', 'type': 'Achat Matériel', 'amount': '-250 000 XOF', 'status': 'Confirmé'},
      {'id': '0x9c4...1d5', 'type': 'Vote Validé', 'amount': 'N/A', 'status': 'Confirmé'},
    ];

    return Column(
      children: transactions.map((tx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx['type']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(tx['id']!, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                tx['amount']!,
                style: TextStyle(
                  color: tx['amount']!.startsWith('+') ? AppColors.success : AppColors.textMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: AppColors.secondary, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rapport Complet PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Janvier 2026 • 2.4 MB', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
