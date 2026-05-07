import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/cooperative.dart';
import '../../models/contribution.dart';
import '../../models/proposal.dart';
import '../../services/cooperative_service.dart';
import '../../services/contribution_service.dart';
import '../../services/vote_service.dart';
import '../../services/blockchain_service.dart';
import '../../core/supabase_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/blockchain_service.dart';

class CooperativeDetailScreen extends ConsumerStatefulWidget {
  final String coopId;
  const CooperativeDetailScreen({super.key, required this.coopId});

  @override
  ConsumerState<CooperativeDetailScreen> createState() =>
      _CooperativeDetailScreenState();
}

class _CooperativeDetailScreenState
    extends ConsumerState<CooperativeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _members = [];
  bool _membersLoading = true;
  String? _isVoting;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final data =
        await ref.read(cooperativeServiceProvider).fetchMembers(widget.coopId);
    if (mounted)
      setState(() {
        _members = data;
        _membersLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(cooperativeProvider(widget.coopId)).when(
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: primaryGreen),
            ),
          ),
          error: (e, _) => Scaffold(
            body: Center(child: Text('Erreur : $e')),
          ),
          data: (coop) {
            if (coop == null) {
              return const Scaffold(
                body: Center(child: Text('Coopérative introuvable')),
              );
            }
            return _buildScaffold(coop);
          },
        );
  }

  Widget _buildScaffold(Cooperative coop) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(coop),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(coop),
                  _buildContributionsTab(),
                  _buildVotesTab(coop),
                  _buildReportTab(coop),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(coop),
    );
  }

  // ── SliverAppBar ──────────────────────────────────────

  SliverAppBar _buildSliverAppBar(Cooperative coop) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final progress = (coop.progressPercent / 100).clamp(0.0, 1.0);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/home'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryGreen, accentGreen],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    coop.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${coop.memberCount} membres · '
                    '${coop.contributionCount} cotisations',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${fmt.format(coop.currentAmount)} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${coop.progressPercent.toStringAsFixed(1)}% '
                        'sur ${fmt.format(coop.goalAmount)} FCFA',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── TabBar ────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: primaryGreen,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryGreen,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Général'),
          Tab(text: 'Cotisations'),
          Tab(text: 'Votes'),
          Tab(text: 'Rapport'),
        ],
      ),
    );
  }

  // ── FAB contextuel ────────────────────────────────────

  Widget? _buildFAB(Cooperative coop) {
    final labels = ['Cotiser', 'Cotiser', 'Proposer', null];
    final icons = [
      Icons.add_card,
      Icons.add_card,
      Icons.how_to_vote_outlined,
      null,
    ];
    final actions = [
      () => context.push('/contribute/${coop.id}'),
      () => context.push('/contribute/${coop.id}'),
      () => _showCreateProposalSheet(coop),
      null,
    ];

    return ListenableBuilder(
      listenable: _tabController,
      builder: (_, __) {
        final i = _tabController.index;
        if (labels[i] == null) return const SizedBox();
        return FloatingActionButton.extended(
          onPressed: actions[i],
          backgroundColor: primaryGreen,
          icon: Icon(icons[i], color: Colors.white),
          label: Text(
            labels[i]!,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 1 — VUE GÉNÉRALE
  // ══════════════════════════════════════════════════════

  Widget _buildOverviewTab(Cooperative coop) {
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: () async {
        await _loadMembers();
        ref.invalidate(contributionsProvider(widget.coopId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Description
          if (coop.description != null && coop.description!.isNotEmpty) ...[
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('À propos',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 8),
                  Text(coop.description!,
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // KPI cards
          Row(children: [
            Expanded(
                child: _buildMiniKpi(
              label: 'Collecté',
              value: '${fmt.format(coop.currentAmount)} F',
              icon: Icons.savings_outlined,
              color: primaryGreen,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildMiniKpi(
              label: 'Restant',
              value: '${fmt.format(coop.remaining)} F',
              icon: Icons.track_changes_outlined,
              color: const Color(0xFFE65100),
            )),
          ]),
          const SizedBox(height: 12),

          // Deadline
          if (coop.deadline != null)
            _buildCard(
              child: Row(children: [
                Icon(Icons.calendar_today_outlined,
                    color: coop.isDeadlinePassed ? Colors.red : primaryGreen,
                    size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Échéance',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      DateFormat('d MMMM yyyy', 'fr_FR').format(coop.deadline!),
                      style: TextStyle(
                        color: coop.isDeadlinePassed
                            ? Colors.red
                            : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ]),
            ),

          const SizedBox(height: 16),

          // Membres
          const Text('Membres',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
          const SizedBox(height: 8),
          _membersLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primaryGreen))
              : _buildMembersList(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_members.isEmpty) {
      return _buildCard(
        child: Center(
          child:
              Text('Aucun membre', style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }
    return _buildCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _members.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
        itemBuilder: (_, i) {
          final m = _members[i];
          final p = m['profiles'] as Map<String, dynamic>?;
          final name = p?['display_name'] ?? p?['email'] ?? 'Membre';
          final role = m['role'] as String? ?? 'member';
          final isMe = p?['id'] == supabase.auth.currentUser?.id;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryGreen,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (isMe) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Moi',
                      style: TextStyle(
                          fontSize: 10,
                          color: primaryGreen,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
            subtitle: Text(
              p?['phone'] ?? p?['email'] ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: role == 'admin' ? lightGreen : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role == 'admin' ? 'Admin' : 'Membre',
                style: TextStyle(
                  fontSize: 11,
                  color: role == 'admin' ? primaryGreen : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 2 — COTISATIONS
  // ══════════════════════════════════════════════════════

  Widget _buildContributionsTab() {
    final contribsAsync = ref.watch(contributionsProvider(widget.coopId));
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return contribsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (contribs) {
        if (contribs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.savings_outlined,
            title: 'Aucune cotisation',
            subtitle: 'Sois le premier à cotiser !',
          );
        }

        final total = contribs.fold(0.0, (s, c) => s + c.amount);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Total
            _buildCard(
              color: lightGreen,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total collecté',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: primaryGreen)),
                  Text(
                    '${fmt.format(total)} FCFA',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Liste
            _buildCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contribs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 56),
                itemBuilder: (_, i) {
                  final c = contribs[i];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.isConfirmed ? lightGreen : Colors.orange[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        c.isConfirmed
                            ? Icons.check_circle_outline
                            : Icons.access_time,
                        color: c.isConfirmed ? primaryGreen : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      c.memberName ?? 'Membre',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMM yyyy · HH:mm', 'fr_FR')
                              .format(c.createdAt),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                        if (c.txHash != null)
                          Text(
                            'TX: ${c.txHash!.substring(0, 10)}...',
                            style: const TextStyle(
                              fontSize: 10,
                              color: primaryGreen,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                    trailing: Text(
                      '+${fmt.format(c.amount)} F',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        fontSize: 15,
                      ),
                    ),
                    isThreeLine: c.txHash != null,
                  );
                },
              ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 3 — VOTES
  // ══════════════════════════════════════════════════════

  Widget _buildVotesTab(Cooperative coop) {
    final proposalsAsync = ref.watch(proposalsProvider(widget.coopId));

    return proposalsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      ),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (proposals) {
        if (proposals.isEmpty) {
          return _buildEmptyState(
            icon: Icons.how_to_vote_outlined,
            title: 'Aucune proposition',
            subtitle: 'Propose un achat pour démarrer un vote.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: proposals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _buildProposalCard(proposals[i]),
        );
      },
    );
  }

  Widget _buildProposalCard(Proposal proposal) {
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(proposal.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )),
                      if (proposal.supplier != null)
                        Text(proposal.supplier!,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                _buildProposalBadge(proposal),
              ],
            ),
          ),

          // Coût + deadline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              if (proposal.estimatedCost != null) ...[
                Icon(Icons.attach_money, size: 16, color: Colors.grey[500]),
                Text('${fmt.format(proposal.estimatedCost)} FCFA',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(width: 16),
              ],
              Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
              Text(
                  proposal.isOpen
                      ? 'Clôture : ${DateFormat('d MMM', 'fr_FR').format(proposal.voteDeadline)}'
                      : 'Clôturé',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ]),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Résultats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildVoteBar(
                  label: 'Pour',
                  count: proposal.yesCount,
                  percent: proposal.yesPercent,
                  color: primaryGreen,
                ),
                const SizedBox(height: 8),
                _buildVoteBar(
                  label: 'Contre',
                  count: proposal.noCount,
                  percent: proposal.noPercent,
                  color: Colors.red,
                ),
                const SizedBox(height: 8),
                _buildVoteBar(
                  label: 'Abstention',
                  count: proposal.abstainCount,
                  percent: proposal.totalVotes == 0
                      ? 0
                      : (proposal.abstainCount / proposal.totalVotes * 100),
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          // Boutons de vote
          if (proposal.isOpen) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: proposal.hasVoted
                  ? _buildAlreadyVoted(proposal.myVote!, proposal.myVoteTxHash)
                  : _buildVoteButtons(proposal),
            ),
          ],

          // Hash blockchain
          if (proposal.resultTxHash != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'TX: ${proposal.resultTxHash!.substring(0, 20)}...',
                style: const TextStyle(
                  fontSize: 10,
                  color: primaryGreen,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVoteBar({
    required String label,
    required int count,
    required double percent,
    required Color color,
  }) {
    return Row(children: [
      SizedBox(
        width: 80,
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        '$count (${percent.toStringAsFixed(0)}%)',
        style: TextStyle(
            fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
      ),
    ]);
  }

  Widget _buildVoteButtons(Proposal proposal) {
    final isVotingThis = _isVoting == proposal.id;

    if (isVotingThis) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: primaryGreen,
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Enregistrement sur blockchain...',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Row(children: [
      _buildVoteBtn(
        label: '👍 Pour',
        choice: 'yes',
        color: primaryGreen,
        proposalId: proposal.id,
      ),
      const SizedBox(width: 8),
      _buildVoteBtn(
        label: '👎 Contre',
        choice: 'no',
        color: Colors.red,
        proposalId: proposal.id,
      ),
      const SizedBox(width: 8),
      _buildVoteBtn(
        label: '🤝 Abstention',
        choice: 'abstain',
        color: Colors.orange,
        proposalId: proposal.id,
      ),
    ]);
  }

  Widget _buildVoteBtn({
    required String label,
    required String choice,
    required Color color,
    required String proposalId,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _castVote(proposalId, choice),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAlreadyVoted(String choice, String? txHash) {
    final labels = {
      'yes': ('👍 Tu as voté Pour', primaryGreen),
      'no': ('👎 Tu as voté Contre', Colors.red),
      'abstain': ('🤝 Tu t\'es abstenu', Colors.orange),
    };
    final entry = labels[choice]!;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: (entry.$2 as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (entry.$2 as Color).withOpacity(0.3),
            ),
          ),
          child: Text(
            entry.$1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: entry.$2 as Color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        if (txHash != null && txHash.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final url = Uri.parse(
                ref.read(blockchainServiceProvider).explorerUrl(txHash),
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(
                  url,
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: Text(
              'TX: ${txHash.substring(0, 10)}... '
              '↗ Voir sur PolygonScan',
              style: const TextStyle(
                fontSize: 11,
                color: primaryGreen,
                fontFamily: 'monospace',
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProposalBadge(Proposal proposal) {
    final config =
        proposal.isOpen ? ('Ouvert', primaryGreen) : ('Clôturé', Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (config.$2 as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.$1,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: config.$2 as Color,
        ),
      ),
    );
  }

  Future<void> _castVote(String proposalId, String choice) async {
    setState(() => _isVoting = proposalId);

    try {
      final txHash = await ref.read(voteServiceProvider).castVote(
            proposalId: proposalId,
            coopId: widget.coopId,
            choice: choice,
            blockchainService: ref.read(blockchainServiceProvider),
          );

      // Rafraîchir les propositions
      ref.invalidate(proposalsProvider(widget.coopId));

      // Ouvrir le bottom sheet de succès
      if (mounted) {
        _showVoteSuccess(txHash, choice);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_parseVoteError(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVoting = null);
    }
  }

  String _parseVoteError(String e) {
    if (e.contains('Deja vote') || e.contains('duplicate key'))
      return 'Tu as déjà voté sur cette proposition.';
    if (e.contains('network')) return 'Erreur réseau. Vérifie ta connexion.';
    return 'Erreur lors du vote. Réessaie.';
  }

  // ══════════════════════════════════════════════════════
  // ONGLET 4 — RAPPORT
  // ══════════════════════════════════════════════════════

  Widget _buildReportTab(Cooperative coop) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final contribsAsync = ref.watch(contributionsProvider(widget.coopId));
    final proposalsAsync = ref.watch(proposalsProvider(widget.coopId));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPI financiers
        _buildCard(
          color: lightGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Résumé financier',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildReportRow(
                'Objectif',
                '${fmt.format(coop.goalAmount)} FCFA',
              ),
              _buildReportRow(
                'Collecté',
                '${fmt.format(coop.currentAmount)} FCFA',
              ),
              _buildReportRow(
                'Restant',
                '${fmt.format(coop.remaining)} FCFA',
              ),
              _buildReportRow(
                'Progression',
                '${coop.progressPercent.toStringAsFixed(1)} %',
              ),
              _buildReportRow('Membres', '${coop.memberCount}'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Timeline unifiée cotisations + votes
        const Text(
          'Historique blockchain',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: darkText,
          ),
        ),
        const SizedBox(height: 8),

        // Combiner cotisations et votes en une seule timeline
        contribsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryGreen),
          ),
          error: (e, _) => Text('Erreur : $e'),
          data: (contribs) => proposalsAsync.when(
            loading: () => _buildTimeline(contribs, []),
            error: (_, __) => _buildTimeline(contribs, []),
            data: (proposals) => _buildTimeline(contribs, proposals),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildTimeline(
    List<Contribution> contribs,
    List<Proposal> proposals,
  ) {
    // Construire une liste unifiée d'événements triés par date
    final events = <Map<String, dynamic>>[];

    // Ajouter les cotisations
    for (final c in contribs) {
      events.add({
        'type': 'contribution',
        'date': c.createdAt,
        'label': 'Cotisation — ${c.memberName ?? 'Membre'}',
        'sublabel': null,
        'amount': c.amount,
        'txHash': c.txHash,
        'status': c.blockchainStatus,
        'color': primaryGreen,
        'icon': Icons.arrow_upward,
      });
    }

    // Ajouter les votes clôturés avec hash résultat
    for (final p in proposals) {
      if (p.resultTxHash != null) {
        events.add({
          'type': 'vote_result',
          'date': p.voteDeadline,
          'label': 'Résultat vote — ${p.title}',
          'sublabel': '${p.yesCount} Pour · '
              '${p.noCount} Contre · '
              '${p.abstainCount} Abstention',
          'amount': null,
          'txHash': p.resultTxHash,
          'status': 'confirmed',
          'color': const Color(0xFF0D47A1),
          'icon': Icons.how_to_vote_outlined,
        });
      }
    }

    // Trier par date décroissante
    events.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (events.isEmpty) {
      return _buildCard(
        child: Center(
          child: Text(
            'Aucun événement enregistré.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
    }

    final fmt = NumberFormat('#,##0', 'fr_FR');

    return _buildCard(
      padding: EdgeInsets.zero,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (_, i) {
          final e = events[i];
          final color = e['color'] as Color;
          final txHash = e['txHash'] as String?;
          final isLast = i == events.length - 1;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot + ligne
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        e['icon'] as IconData,
                        color: color,
                        size: 18,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.grey[200],
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label + montant
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              e['label'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (e['amount'] != null)
                            Text(
                              '+${fmt.format(e['amount'])} F',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),

                      // Sous-label (résultat vote)
                      if (e['sublabel'] != null)
                        Text(
                          e['sublabel'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),

                      // Date
                      Text(
                        DateFormat('d MMM yyyy · HH:mm', 'fr_FR')
                            .format(e['date'] as DateTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),

                      // Hash cliquable
                      if (txHash != null && txHash.isNotEmpty)
                        GestureDetector(
                          onTap: () async {
                            final url = Uri.parse(
                              ref
                                  .read(blockchainServiceProvider)
                                  .explorerUrl(txHash),
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link,
                                  size: 12,
                                  color: primaryGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'TX: ${txHash.substring(0, 10)}'
                                  '...${txHash.substring(txHash.length - 6)}'
                                  '  ↗ PolygonScan',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: primaryGreen,
                                    fontFamily: 'monospace',
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.orange[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'En attente de confirmation...',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: darkText)),
        ],
      ),
    );
  }

  // ── Sheet création proposition ────────────────────────

  void _showCreateProposalSheet(Cooperative coop) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final supplCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 3));
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouvelle proposition',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Titre *', border: OutlineInputBorder()),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: supplCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Fournisseur', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Coût estimé (FCFA)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => loading = true);
                            try {
                              await ref
                                  .read(voteServiceProvider)
                                  .createProposal(
                                    coopId: coop.id,
                                    title: titleCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    supplier: supplCtrl.text.trim(),
                                    estimatedCost: double.tryParse(costCtrl.text
                                            .replaceAll(' ', '')) ??
                                        0,
                                    voteDeadline: deadline,
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              ref.invalidate(proposalsProvider(widget.coopId));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Proposition créée ! 🗳️'),
                                    backgroundColor: primaryGreen,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } finally {
                              setModalState(() => loading = false);
                            }
                          },
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)
                        : const Text('Soumettre la proposition',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ────────────────────────────────────────

  Widget _buildCard({
    required Widget child,
    EdgeInsets? padding,
    Color color = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMiniKpi({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: darkText)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  void _showVoteSuccess(String txHash, String choice) {
    final labels = {
      'yes': ('👍 Vote Pour enregistré !', primaryGreen),
      'no': ('👎 Vote Contre enregistré !', Colors.red),
      'abstain': ('🤝 Abstention enregistrée !', Colors.orange),
    };
    final entry = labels[choice]!;
    final color = entry.$2 as Color;
    final short =
        '${txHash.substring(0, 10)}...${txHash.substring(txHash.length - 8)}';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.how_to_vote, color: color, size: 32),
            ),
            const SizedBox(height: 16),

            Text(
              entry.$1,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ton vote est enregistré sur Polygon blockchain.\n'
              'Il est immuable et vérifiable publiquement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Hash
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Hash de transaction',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    short,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Réseau : Polygon Amoy Testnet',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bouton PolygonScan
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(
                    ref.read(blockchainServiceProvider).explorerUrl(txHash),
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: primaryGreen,
                ),
                label: const Text(
                  'Vérifier sur PolygonScan',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Fermer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
