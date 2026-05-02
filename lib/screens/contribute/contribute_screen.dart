import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/app_input.dart';
import '../../widgets/primary_button.dart';

class ContributeScreen extends StatefulWidget {
  const ContributeScreen({super.key});

  @override
  State<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends State<ContributeScreen> {
  String _selectedMethod = 'T-Money';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contribuer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faire une cotisation',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre contribution sera enregistrée sur la blockchain pour une transparence totale.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            const AppInput(
              label: 'Montant (XOF)',
              hint: 'Ex: 5000',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.payments_outlined,
            ),
            const SizedBox(height: 32),
            Text(
              'Méthode de paiement',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethod('T-Money', 'Togo Cellulaire'),
            const SizedBox(height: 12),
            _buildPaymentMethod('Moov Money', 'Moov Africa'),
            const SizedBox(height: 40),
            _buildSummary(context),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Confirmer le paiement',
              onPressed: () => _showSuccessDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(String name, String provider) {
    final isSelected = _selectedMethod == name;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surface,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.phone_android_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(provider, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Sous-total', value: '5 000 XOF'),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Frais réseau', value: '50 XOF'),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Total à payer',
            value: '5 050 XOF',
            isBold: true,
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.success,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Paiement Réussi !',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre cotisation a été validée et enregistrée sur la blockchain.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hash: 0x7a2...4f9',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Retour à l\'accueil',
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow(
      {required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
