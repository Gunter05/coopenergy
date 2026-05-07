import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/cooperative_service.dart';
import '../../models/cooperative.dart';
import '../cooperative/cooperative_list_screen.dart';
import '../report/report_screen.dart';
import '../profile/profile_screen.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final coopsAsync = ref.watch(myCooperativesProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final activityAsync = ref.watch(recentActivityProvider);

    final firstName = user?.userMetadata?['full_name']
            ?.toString()
            .split(' ')
            .first ??
        user?.email?.split('@').first ??
        'là';

    final List<Widget> _tabs = [
      _buildHomeContent(context, firstName, coopsAsync, statsAsync, activityAsync),
      const CooperativeListScreen(),
      const ReportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryGreen,
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Coops',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment_rounded),
              label: 'Rapport',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
      // FAB — Créer une coopérative (uniquement sur l'onglet Home)
      floatingActionButton: _currentIndex == 0 
        ? FloatingActionButton.extended(
            onPressed: () => context.push('/cooperative/create'),
            backgroundColor: primaryGreen,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nouvelle',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        : null,
    );
  }

  Widget _buildHomeContent(
    BuildContext context, 
    String firstName,
    AsyncValue<List<Cooperative>> coopsAsync,
    AsyncValue<Map<String, dynamic>> statsAsync,
    AsyncValue<List<Map<String, dynamic>>> activityAsync,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context, ref),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: () async {
          ref.invalidate(myCooperativesProvider);
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentActivityProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(firstName),
              const SizedBox(height: 20),
              statsAsync.when(
                data: (stats) => _buildStatsRow(stats),
                loading: () => _buildStatsLoading(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Mes coopératives'),
              const SizedBox(height: 12),
              coopsAsync.when(
                data: (coops) => coops.isEmpty
                    ? _buildEmptyCoops(context)
                    : _buildCoopsList(context, coops),
                loading: () => _buildCoopsLoading(),
                error: (e, _) => _buildError(e.toString()),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Activité récente'),
              const SizedBox(height: 12),
              activityAsync.when(
                data: (activity) => activity.isEmpty
                    ? _buildEmptyActivity()
                    : _buildActivityList(activity),
                loading: () => _buildActivityLoading(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.solar_power, size: 24),
          const SizedBox(width: 8),
          const Text(
            'CoopEnergie',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Se déconnecter',
          onPressed: () async {
            await ref.read(authServiceProvider).signOut();
            if (context.mounted) context.go('/auth');
          },
        ),
      ],
    );
  }

  // ── Salutation ────────────────────────────────────────

  Widget _buildGreeting(String firstName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $firstName 👋',
          style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  // ── Stats KPI ─────────────────────────────────────────

  Widget _buildStatsRow(Map<String, dynamic> stats) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.savings_outlined,
          label: 'Total cotisé',
          value: '${fmt.format(stats['total_contributed'] ?? 0)} F',
          color: primaryGreen,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.groups_outlined,
          label: 'Coopératives',
          value: '${stats['active_coops'] ?? 0}',
          color: const Color(0xFF0D47A1),
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          icon: Icons.how_to_vote_outlined,
          label: 'Votes ouverts',
          value: '${stats['pending_votes'] ?? 0}',
          color: const Color(0xFFE65100),
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoading() {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
          height: 90,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      )),
    );
  }

  // ── Boutons rapides ───────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionChip(
          icon: Icons.add_card,
          label: 'Cotiser',
          onTap: () => context.push('/cooperatives'),
        ),
        const SizedBox(width: 10),
        _buildActionChip(
          icon: Icons.how_to_vote,
          label: 'Voter',
          onTap: () => context.push('/vote'),
        ),
        const SizedBox(width: 10),
        _buildActionChip(
          icon: Icons.assessment_outlined,
          label: 'Rapport',
          onTap: () => context.push('/report'),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentGreen.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: primaryGreen, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Liste coopératives ────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.bold, color: darkText,
      ),
    );
  }

  Widget _buildCoopsList(BuildContext context, List<Cooperative> coops) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildCoopCard(context, coops[i]),
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
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Header
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.solar_power, color: primaryGreen, size: 24,
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
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      Text(
                        '${coop.memberCount} membres · '
                        '${coop.contributionCount} cotisations',
                        style: TextStyle(
                          fontSize: 12, color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(coop.status),
              ],
            ),

            const SizedBox(height: 16),

            // Barre de progression
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

            // Montants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${fmt.format(coop.currentAmount)} FCFA',
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                Text(
                  '${coop.progressPercent.toStringAsFixed(1)} % '
                  'sur ${fmt.format(coop.goalAmount)} FCFA',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            // Deadline si elle existe
            if (coop.deadline != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: coop.isDeadlinePassed
                        ? Colors.red
                        : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Échéance : ${DateFormat('d MMM yyyy', 'fr_FR')
                        .format(coop.deadline!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: coop.isDeadlinePassed
                          ? Colors.red
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final config = {
      'active':    {'label': 'Actif',    'color': primaryGreen},
      'completed': {'label': 'Complété', 'color': const Color(0xFF0D47A1)},
      'cancelled': {'label': 'Annulé',   'color': Colors.red},
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
          fontSize: 11, fontWeight: FontWeight.bold,
          color: c['color'] as Color,
        ),
      ),
    );
  }

  Widget _buildEmptyCoops(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.solar_power_outlined,
              size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucune coopérative pour l\'instant',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crée ta première coopérative ou rejoins\nun groupe existant.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/cooperative/create'),
            icon: const Icon(Icons.add),
            label: const Text('Créer une coopérative'),
          ),
        ],
      ),
    );
  }

  Widget _buildCoopsLoading() {
    return Column(
      children: List.generate(2, (i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
      )),
    );
  }

  // ── Activité récente ──────────────────────────────────

  Widget _buildActivityList(List<Map<String, dynamic>> activity) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activity.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
        itemBuilder: (_, i) {
          final item = activity[i];
          final amount = (item['amount'] as num).toDouble();
          final date = DateTime.parse(item['created_at']);
          final coopName = item['cooperatives']?['name'] ?? 'Coopérative';

          return ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_upward, color: primaryGreen, size: 20,
              ),
            ),
            title: Text(
              'Cotisation — $coopName',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              DateFormat('d MMM yyyy · HH:mm', 'fr_FR').format(date),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: Text(
              '+${fmt.format(amount)} F',
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          'Aucune activité récente.',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildActivityLoading() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB71C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFB71C1C)),
            ),
          ),
        ],
      ),
    );
  }
}
