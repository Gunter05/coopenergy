import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/supabase_client.dart';
import '../../services/cooperative_service.dart';
import '../../services/blockchain_service.dart';
import '../../models/cooperative.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  final String coopId;
  const ContributeScreen({super.key, required this.coopId});

  @override
  ConsumerState<ContributeScreen> createState() =>
      _ContributeScreenState();
}

class _ContributeScreenState
    extends ConsumerState<ContributeScreen> {

  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String _paymentMethod = 'mobile_money';

  // États
  bool   _isLoading     = false;
  String _status        = 'idle'; // idle | saving | blockchain | done | error
  String? _txHash;
  String? _errorMessage;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // ── Action principale ─────────────────────────────────
  Future<void> _contribute(Cooperative coop) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(
        _amountCtrl.text.replaceAll(' ', '').replaceAll(',', '.'));

    setState(() {
      _isLoading    = true;
      _status       = 'saving';
      _errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser!.id;

      // 1. Enregistrer en base de données
      final contrib = await supabase
          .from('contributions')
          .insert({
            'cooperative_id':   widget.coopId,
            'user_id':          userId,
            'amount':           amount,
            'payment_method':   _paymentMethod,
            'blockchain_status':'pending',
          })
          .select()
          .single();

      final contribId = contrib['id'] as String;

      // 2. Enregistrer sur blockchain
      setState(() => _status = 'blockchain');

      final txHash = await ref
          .read(blockchainServiceProvider)
          .recordContribution(
            coopId: widget.coopId,
            amount: amount,
          );

      // 3. Mettre à jour avec le hash blockchain
      await supabase
          .from('contributions')
          .update({
            'tx_hash':          txHash,
            'blockchain_status':'confirmed',
          })
          .eq('id', contribId);

      setState(() {
        _txHash  = txHash;
        _status  = 'done';
        _isLoading = false;
      });

      // Rafraîchir les données du dashboard
      ref.invalidate(myCooperativesProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(recentActivityProvider);

    } catch (e) {
      setState(() {
        _status       = 'error';
        _errorMessage = _parseError(e.toString());
        _isLoading    = false;
      });
    }
  }

  String _parseError(String e) {
    if (e.contains('insufficient funds')) {
      return 'Fonds blockchain insuffisants. Contacte l\'équipe.';
    }
    if (e.contains('network')) {
      return 'Erreur réseau. Vérifie ta connexion.';
    }
    return 'Une erreur est survenue. Réessaie.';
  }

  // ── Build ─────────────────────────────────────────────
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
            body: Center(
              child: Text('Coopérative introuvable'),
            ),
          );
        }
        return _buildScaffold(coop);
      },
    );
  }

  Widget _buildScaffold(Cooperative coop) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          'Cotiser',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _status == 'done'
          ? _buildSuccessView(coop)
          : _buildFormView(coop),
    );
  }

  // ── Formulaire ────────────────────────────────────────
  Widget _buildFormView(Cooperative coop) {
    final fmt = NumberFormat('#,##0', 'fr_FR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          // Carte coopérative
          Container(
            padding: const EdgeInsets.all(16),
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
                Row(children: [
                  const Icon(
                    Icons.solar_power,
                    color: primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      coop.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (coop.progressPercent / 100)
                        .clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                            primaryGreen),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${fmt.format(coop.currentAmount)} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    Text(
                      '${coop.progressPercent.toStringAsFixed(1)}%'
                      ' sur ${fmt.format(coop.goalAmount)} FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Formulaire
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Montant
                const Text(
                  'Montant à cotiser',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'FCFA',
                    suffixStyle: const TextStyle(
                      fontSize: 16,
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: const Icon(
                      Icons.savings_outlined,
                      color: primaryGreen,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 2,
                      ),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Saisis un montant';
                    }
                    final amount = double.tryParse(v
                        .replaceAll(' ', '')
                        .replaceAll(',', '.'));
                    if (amount == null || amount <= 0) {
                      return 'Montant invalide';
                    }
                    if (amount > 1000000) {
                      return 'Montant trop élevé';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Raccourcis montants
                Wrap(
                  spacing: 8,
                  children: [5000, 10000, 25000, 50000]
                      .map((v) => ActionChip(
                            label: Text(
                              '${fmt.format(v)} F',
                              style: const TextStyle(
                                fontSize: 12,
                                color: primaryGreen,
                              ),
                            ),
                            backgroundColor: lightGreen,
                            side: BorderSide(
                              color: accentGreen.withOpacity(0.3),
                            ),
                            onPressed: () => _amountCtrl.text =
                                v.toString(),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 20),

                // Méthode de paiement
                const Text(
                  'Méthode de paiement',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodSelector(),

                const SizedBox(height: 24),

                // Info blockchain
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Ta cotisation sera enregistrée sur '
                        'Polygon blockchain — traçable et '
                        'immuable pour toujours.',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // Bouton confirmer
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _contribute(coop),
                    child: _isLoading
                        ? _buildLoadingState()
                        : const Text(
                            'Confirmer la cotisation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Message d'erreur
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFB71C1C),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFB71C1C),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final labels = {
      'saving':     'Enregistrement...',
      'blockchain': 'Envoi sur blockchain...',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          labels[_status] ?? 'Traitement...',
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    final methods = [
      ('mobile_money', Icons.phone_android, 'Mobile Money'),
      ('cash',         Icons.payments_outlined, 'Espèces'),
      ('other',        Icons.more_horiz, 'Autre'),
    ];
    return Row(
      children: methods.map((m) {
        final isSelected = _paymentMethod == m.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _paymentMethod = m.$1),
            child: Container(
              margin: EdgeInsets.only(
                right: m.$1 != 'other' ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected ? primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? primaryGreen
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(children: [
                Icon(
                  m.$2,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey[600],
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  m.$3,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey[600],
                  ),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Vue succès ────────────────────────────────────────
  Widget _buildSuccessView(Cooperative coop) {
    final amount = double.tryParse(
          _amountCtrl.text
              .replaceAll(' ', '')
              .replaceAll(',', '.'),
        ) ??
        0;
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final shortHash = _txHash != null
        ? '${_txHash!.substring(0, 10)}...${_txHash!.substring(_txHash!.length - 8)}'
        : '';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Icône succès
            Container(
              width: 100, height: 100,
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Cotisation enregistrée !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${fmt.format(amount)} FCFA ajoutés à ${coop.name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Carte hash blockchain
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryGreen.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.link,
                        color: primaryGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Preuve blockchain',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shortHash,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Réseau : Polygon Amoy Testnet',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bouton PolygonScan
                  if (_txHash != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(
                          ref
                            .read(blockchainServiceProvider)
                            .explorerUrl(_txHash!),
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode
                                .externalApplication,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: primaryGreen,
                      ),
                      label: const Text(
                        'Voir sur PolygonScan',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: primaryGreen,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Boutons navigation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    context.go('/cooperative/${coop.id}'),
                child: const Text(
                  'Voir la coopérative',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retour au dashboard',
                  style: TextStyle(color: primaryGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
