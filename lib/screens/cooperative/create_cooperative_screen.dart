import 'package:coopenergy/services/cooperative_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../services/member_service.dart';

class CreateCooperativeScreen extends ConsumerStatefulWidget {
  const CreateCooperativeScreen({super.key});

  @override
  ConsumerState<CreateCooperativeScreen> createState() =>
      _CreateCooperativeScreenState();
}

class _CreateCooperativeScreenState
    extends ConsumerState<CreateCooperativeScreen> {
  int _currentStep = 0;

  // ── Étape 1 — Infos de base ──────────────────────────
  final _step1Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _deadline;

  // ── Étape 2 — Membres ────────────────────────────────
  final _searchCtrl = TextEditingController();
  final List<MemberSearchResult> _selectedMembers = [];
  List<MemberSearchResult> _contactsWithAccount = [];
  MemberSearchResult? _searchResult;
  bool _searchLoading = false;
  bool _contactsLoading = false;
  String? _searchError;

  // ── Étape 3 — Confirmation ───────────────────────────
  bool _isCreating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────

  Future<void> _loadContacts() async {
    setState(() => _contactsLoading = true);
    try {
      final service = ref.read(memberServiceProvider);
      final results = await service.searchFromContacts();
      setState(() => _contactsWithAccount = results);
    } finally {
      setState(() => _contactsLoading = false);
    }
  }

  Future<void> _searchMember() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searchLoading = true;
      _searchResult = null;
      _searchError = null;
    });

    try {
      final service = ref.read(memberServiceProvider);
      final result = await service.searchByEmailOrPhone(query);
      setState(() {
        _searchResult = result;
        _searchError =
            result == null ? 'Aucun compte trouvé pour "$query"' : null;
      });
    } finally {
      setState(() => _searchLoading = false);
    }
  }

  void _addMember(MemberSearchResult member) {
    if (_selectedMembers.any((m) => m.userId == member.userId)) return;
    setState(() {
      _selectedMembers.add(member);
      _searchCtrl.clear();
      _searchResult = null;
    });
  }

  void _removeMember(String userId) {
    setState(() => _selectedMembers.removeWhere((m) => m.userId == userId));
  }

  Future<void> _createCooperative() async {
    setState(() => _isCreating = true);
    try {
      final service = ref.read(cooperativeServiceProvider);
      final coopId = await service.createCooperative(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        goalAmount: double.parse(
            _amountCtrl.text.replaceAll(' ', '').replaceAll(',', '.')),
        deadline: _deadline,
        memberUserIds: _selectedMembers.map((m) => m.userId).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coopérative créée avec succès ! 🎉'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // go remplace la pile — pas de retour possible vers le formulaire
        context.go('/cooperative/$coopId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // ── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Nouvelle coopérative',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: primaryGreen,
              ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          controlsBuilder: _buildControls,
          steps: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
          ],
        ),
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (!_step1Key.currentState!.validate()) return;
      setState(() => _currentStep = 1);
      _loadContacts(); // charger contacts quand on arrive à l'étape 2
    } else if (_currentStep == 1) {
      setState(() => _currentStep = 2);
    } else {
      _createCooperative();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0)
      setState(() => _currentStep--);
    else
      context.pop();
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    final isLast = _currentStep == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isCreating ? null : details.onStepContinue,
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLast ? 'Créer la coopérative' : 'Continuer',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: details.onStepCancel,
              child: Text(_currentStep == 0 ? 'Annuler' : 'Retour'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Étape 1 — Informations de base ───────────────────

  Step _buildStep1() {
    return Step(
      title: const Text('Informations',
          style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Nom, objectif et montant cible'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step1Key,
        child: Column(
          children: [
            // Nom
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDeco(
                label: 'Nom de la coopérative',
                icon: Icons.groups_outlined,
                hint: 'Ex : Coop Soleil Yaoundé',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Le nom est obligatoire'
                  : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: _inputDeco(
                label: 'Description (optionnelle)',
                icon: Icons.description_outlined,
                hint: 'Décris l\'objectif du groupe...',
              ),
            ),
            const SizedBox(height: 16),

            // Montant cible
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDeco(
                label: 'Montant cible (FCFA)',
                icon: Icons.savings_outlined,
                hint: 'Ex : 150000',
                suffix: 'FCFA',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Le montant est obligatoire';
                final amount =
                    double.tryParse(v.replaceAll(' ', '').replaceAll(',', '.'));
                if (amount == null || amount <= 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date limite
            GestureDetector(
              onTap: _pickDeadline,
              child: InputDecorator(
                decoration: _inputDeco(
                  label: 'Date limite (optionnelle)',
                  icon: Icons.calendar_today_outlined,
                ),
                child: Text(
                  _deadline != null
                      ? DateFormat('d MMMM yyyy', 'fr_FR').format(_deadline!)
                      : 'Sélectionner une date',
                  style: TextStyle(
                    color: _deadline != null ? darkText : Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  // ── Étape 2 — Membres ────────────────────────────────

  Step _buildStep2() {
    return Step(
      title:
          const Text('Membres', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Invite des membres ou commence seul'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Membres sélectionnés
          if (_selectedMembers.isNotEmpty) ...[
            const Text(
              'Membres invités',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedMembers
                  .map(
                    (m) => Chip(
                      avatar: CircleAvatar(
                        backgroundColor: primaryGreen,
                        child: Text(
                          m.displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      label: Text(m.displayName),
                      onDeleted: () => _removeMember(m.userId),
                      deleteIconColor: Colors.red,
                      backgroundColor: lightGreen,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Recherche manuelle
          const Text(
            'Rechercher par email ou téléphone',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchCtrl,
                  decoration: _inputDeco(
                    label: 'Email ou numéro',
                    icon: Icons.search,
                    hint: 'exemple@email.com ou +237...',
                  ),
                  onFieldSubmitted: (_) => _searchMember(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searchLoading ? null : _searchMember,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _searchLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),

          // Résultat de recherche
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _searchError!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          if (_searchResult != null)
            _buildMemberTile(_searchResult!, fromSearch: true),

          const SizedBox(height: 20),

          // Contacts du répertoire (Android/iOS uniquement)
          if (!_contactsLoading && _contactsWithAccount.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.contacts_outlined,
                    color: primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Contacts avec un compte (${_contactsWithAccount.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...(_contactsWithAccount
                .where(
                    (c) => !_selectedMembers.any((m) => m.userId == c.userId))
                .map((c) => _buildMemberTile(c))),
          ],
          if (_contactsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ),

          const SizedBox(height: 12),

          // Info — continuer sans membres
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: primaryGreen, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tu peux aussi continuer sans inviter de membres '
                    'et les ajouter plus tard depuis le détail.',
                    style: TextStyle(fontSize: 13, color: primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(MemberSearchResult member,
      {bool fromSearch = false}) {
    final isSelected = _selectedMembers.any((m) => m.userId == member.userId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? lightGreen : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primaryGreen : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryGreen,
          child: Text(
            member.displayName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          member.phone ?? member.email ?? '',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: primaryGreen)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: primaryGreen),
                onPressed: () => _addMember(member),
              ),
        onTap: isSelected
            ? () => _removeMember(member.userId)
            : () => _addMember(member),
      ),
    );
  }

  // ── Étape 3 — Confirmation ───────────────────────────

  Step _buildStep3() {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final amount = double.tryParse(
            _amountCtrl.text.replaceAll(' ', '').replaceAll(',', '.')) ??
        0;

    return Step(
      title: const Text('Confirmation',
          style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Vérifie et crée ta coopérative'),
      isActive: _currentStep >= 2,
      state: StepState.indexed,
      content: Column(
        children: [
          _buildConfirmRow(
            icon: Icons.groups_outlined,
            label: 'Nom',
            value: _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim(),
          ),
          if (_descCtrl.text.trim().isNotEmpty)
            _buildConfirmRow(
              icon: Icons.description_outlined,
              label: 'Description',
              value: _descCtrl.text.trim(),
            ),
          _buildConfirmRow(
            icon: Icons.savings_outlined,
            label: 'Montant cible',
            value: '${fmt.format(amount)} FCFA',
          ),
          _buildConfirmRow(
            icon: Icons.calendar_today_outlined,
            label: 'Échéance',
            value: _deadline != null
                ? DateFormat('d MMMM yyyy', 'fr_FR').format(_deadline!)
                : 'Aucune',
          ),
          _buildConfirmRow(
            icon: Icons.person_add_outlined,
            label: 'Membres invités',
            value: _selectedMembers.isEmpty
                ? 'Aucun (tu seras seul membre)'
                : '${_selectedMembers.length} membre(s) : '
                    '${_selectedMembers.map((m) => m.displayName).join(', ')}',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentGreen.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, color: primaryGreen, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La création sera enregistrée sur blockchain '
                    'pour garantir la traçabilité.',
                    style: TextStyle(fontSize: 13, color: primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: primaryGreen),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  // ── Helper décoration champ ───────────────────────────

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    String? hint,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: Icon(icon, color: primaryGreen),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
