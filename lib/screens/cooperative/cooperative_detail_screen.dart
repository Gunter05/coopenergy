import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/status_badge.dart';

class CooperativeDetailScreen extends StatelessWidget {
  final String id;

  const CooperativeDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Solaire Miabe J1',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.primary),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Icon(
                      Icons.solar_power_rounded,
                      size: 250,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StatusBadge(label: 'Actif', type: BadgeType.success),
                      Text(
                        'Créé le 12/01/2026',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Objectif de la coopérative',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Installation de 50 panneaux solaires haute performance pour alimenter 20 foyers du quartier Miabe J1. Ce projet vise à réduire la dépendance au réseau électrique instable et à promouvoir l\'énergie propre.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _buildFinancialSummary(context),
                  const SizedBox(height: 32),
                  _buildTabSection(context),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    label: 'Cotiser maintenant',
                    onPressed: () => context.push('/contribute'),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Voter sur les propositions',
                    isSecondary: true,
                    onPressed: () => context.push('/votes'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const ProgressBar(
            progress: 0.75,
            label: 'Progression de la collecte',
            trailing: '750 000 / 1 000 000 XOF',
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FinancialItem(label: 'Membres', value: '42', icon: Icons.people_outline),
              _FinancialItem(label: 'Engagé', value: '450K XOF', icon: Icons.shopping_bag_outlined),
              _FinancialItem(label: 'Reste', value: '250K XOF', icon: Icons.account_balance_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Membres'),
              Tab(text: 'Historique'),
              Tab(text: 'Documents'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: TabBarView(
              children: [
                _buildMemberList(context),
                _buildHistoryList(context),
                _buildDocumentList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(BuildContext context) {
    final members = ['Koffi A.', 'Awa D.', 'Moussa B.', 'Jean K.', 'Sarah L.'];
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(child: Text(members[index][0])),
          title: Text(members[index]),
          subtitle: Text(index == 0 ? 'Admin' : 'Membre'),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.add_circle_outline, color: AppColors.success),
          title: Text('Cotisation de 10 000 XOF'),
          subtitle: Text('Il y a 2 jours'),
        ),
        ListTile(
          leading: Icon(Icons.how_to_vote, color: AppColors.warning),
          title: Text('Vote ouvert: Choix fournisseur'),
          subtitle: Text('Il y a 3 jours'),
        ),
      ],
    );
  }

  Widget _buildDocumentList(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
          title: Text('Statuts de la coopérative'),
          trailing: Icon(Icons.download_rounded),
        ),
        ListTile(
          leading: Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
          title: Text('Rapport financier Janvier'),
          trailing: Icon(Icons.download_rounded),
        ),
      ],
    );
  }
}

class _FinancialItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _FinancialItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
