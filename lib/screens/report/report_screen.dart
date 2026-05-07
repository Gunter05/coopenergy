import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../services/cooperative_service.dart';
import '../../services/blockchain_service.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final auditAsync = ref.watch(detailedAuditLogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Rapport & Transparence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(detailedAuditLogProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Résumé financier
              const _SectionTitle(title: 'Résumé Financier'),
              const SizedBox(height: 12),
              statsAsync.when(
                data: (stats) => _buildFinancialGrid(context, stats),
                loading: () => const _LoadingPlaceholder(height: 160),
                error: (e, _) => Text('Erreur : $e'),
              ),

              const SizedBox(height: 24),

              // Audit Blockchain
              const _SectionTitle(title: 'Audit Blockchain (Polygon)'),
              const SizedBox(height: 12),
              auditAsync.when(
                data: (log) => log.isEmpty
                    ? _buildEmptyAudit()
                    : _buildAuditList(context, ref, log),
                loading: () => const _LoadingPlaceholder(height: 300),
                error: (e, _) => Text('Erreur : $e'),
              ),

              const SizedBox(height: 32),

              // Export
              _buildExportCard(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialGrid(BuildContext context, Map<String, dynamic> stats) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final total = (stats['total_contributed'] ?? 0);
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          label: 'Total Cotisé',
          value: '${fmt.format(total)} F',
          icon: Icons.savings_outlined,
          color: primaryGreen,
        ),
        _StatCard(
          label: 'Projets Actifs',
          value: '${stats['active_coops'] ?? 0}',
          icon: Icons.solar_power_outlined,
          color: const Color(0xFF0D47A1),
        ),
        _StatCard(
          label: 'Votes Ouverts',
          value: '${stats['pending_votes'] ?? 0}',
          icon: Icons.how_to_vote_outlined,
          color: const Color(0xFFE65100),
        ),
        _StatCard(
          label: 'Score Impact',
          value: 'A+',
          icon: Icons.auto_awesome,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAuditList(BuildContext context, WidgetRef ref, List<Map<String, dynamic>> log) {
    return Column(
      children: log.map((item) {
        final date = item['date'] as DateTime;
        final hash = item['hash'] as String?;
        final shortHash = hash != null 
          ? '${hash.substring(0, 8)}...${hash.substring(hash.length - 6)}'
          : 'En attente...';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: item['type'] == 'Cotisation' 
                  ? lightGreen 
                  : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['type'] == 'Cotisation' 
                  ? Icons.add_card 
                  : Icons.how_to_vote,
                color: item['type'] == 'Cotisation' 
                  ? primaryGreen 
                  : const Color(0xFF1976D2),
                size: 20,
              ),
            ),
            title: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMM yyyy · HH:mm', 'fr_FR').format(date),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
                if (hash != null)
                  Text(
                    'TX: $shortHash',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item['amount'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item['is_positive'] == true 
                      ? primaryGreen 
                      : darkText,
                  ),
                ),
                if (hash != null)
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(
                        ref.read(blockchainServiceProvider).explorerUrl(hash)
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyAudit() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Aucun audit disponible', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Tes transactions blockchain apparaîtront ici.', 
               style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.3),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rapport d\'impact PDF',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Génère un rapport certifié de tes investissements.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {}, // À implémenter plus tard
            icon: const Icon(Icons.download_for_offline, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label, 
    required this.value, 
    required this.icon, 
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;
  const _LoadingPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: CircularProgressIndicator(color: primaryGreen)),
    );
  }
}
