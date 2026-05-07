import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../core/theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  // ── Contrôleurs ──────────────────────────────────────
  late final TabController _tabController;
  final _emailLoginCtrl = TextEditingController();
  final _passwordLoginCtrl = TextEditingController();
  final _nameSignupCtrl = TextEditingController();
  final _emailSignupCtrl = TextEditingController();
  final _passwordSignupCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _phoneSignupCtrl = TextEditingController();

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showLoginPass = false;
  bool _showSignupPass = false;
  bool _showConfirmPass = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _errorMessage = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailLoginCtrl.dispose();
    _passwordLoginCtrl.dispose();
    _nameSignupCtrl.dispose();
    _emailSignupCtrl.dispose();
    _passwordSignupCtrl.dispose();
    _confirmPassCtrl.dispose();
    _phoneSignupCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────

  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        email: _emailLoginCtrl.text.trim(),
        password: _passwordLoginCtrl.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _errorMessage = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmail(
        email: _emailSignupCtrl.text.trim(),
        password: _passwordSignupCtrl.text,
        displayName: _nameSignupCtrl.text.trim(),
        phone: _phoneSignupCtrl.text.trim(),
      );
      if (mounted) {
        _showSuccessSnack('Compte créé avec succès !');
        context.go('/home');
      }
    } catch (e) {
      setState(() => _errorMessage = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      // La redirection est gérée automatiquement par le router
    } catch (e) {
      setState(() => _errorMessage = _parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailLoginCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Entre ton email pour réinitialiser.');
      return;
    }
    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(email);
      if (mounted) _showSuccessSnack('Email de réinitialisation envoyé !');
    } catch (e) {
      setState(() => _errorMessage = _parseError(e.toString()));
    }
  }

  // ── Helpers ──────────────────────────────────────────

  String _parseError(String error) {
    if (error.contains('Invalid login credentials'))
      return 'Email ou mot de passe incorrect.';
    if (error.contains('Email not confirmed'))
      return 'Confirme ton email avant de te connecter.';
    if (error.contains('User already registered'))
      return 'Un compte existe déjà avec cet email.';
    if (error.contains('Password should be'))
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    if (error.contains('network'))
      return 'Problème de connexion réseau. Réessaie.';
    return 'Une erreur est survenue. Réessaie.';
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.solar_power,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'CoopEnergie',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Coopératives solaires transparentes',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTabBar(),
            const SizedBox(height: 24),
            if (_errorMessage != null) _buildErrorBanner(),
            SizedBox(
              height: 420,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginForm(),
                  _buildSignupForm(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: primaryGreen,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Connexion'),
          Tab(text: 'Inscription'),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB71C1C), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close, size: 18, color: Color(0xFFB71C1C)),
          ),
        ],
      ),
    );
  }

  // ── Formulaire Connexion ──────────────────────────────

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _emailLoginCtrl,
            label: 'Adresse email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordLoginCtrl,
            label: 'Mot de passe',
            icon: Icons.lock_outline,
            obscureText: !_showLoginPass,
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showLoginPass ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _showLoginPass = !_showLoginPass),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetPassword,
              child: const Text(
                'Mot de passe oublié ?',
                style: TextStyle(color: primaryGreen, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPrimaryButton(
            label: 'Se connecter',
            onPressed: _isLoading ? null : _signIn,
          ),
        ],
      ),
    );
  }

  // ── Formulaire Inscription ────────────────────────────

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _nameSignupCtrl,
            label: 'Nom complet',
            icon: Icons.person_outline,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Entre ton nom' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneSignupCtrl,
            label: 'Numéro de téléphone (optionnel)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null; // optionnel
              final cleaned = v.replaceAll(RegExp(r'[\s\-\+]'), '');
              if (cleaned.length < 8) return 'Numéro invalide';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailSignupCtrl,
            label: 'Adresse email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordSignupCtrl,
            label: 'Mot de passe',
            icon: Icons.lock_outline,
            obscureText: !_showSignupPass,
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showSignupPass ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _showSignupPass = !_showSignupPass),
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPassCtrl,
            label: 'Confirmer le mot de passe',
            icon: Icons.lock_outline,
            obscureText: !_showConfirmPass,
            validator: (v) => v != _passwordSignupCtrl.text
                ? 'Les mots de passe ne correspondent pas'
                : null,
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPass ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _showConfirmPass = !_showConfirmPass),
            ),
          ),
          const SizedBox(height: 16),
          _buildPrimaryButton(
            label: "S'inscrire",
            onPressed: _isLoading ? null : _signUp,
          ),
        ],
      ),
    );
  }

  // ── Composants réutilisables ──────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou continuer avec',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        icon: Image.network(
          'https://www.google.com/favicon.ico',
          width: 20,
          height: 20,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.g_mobiledata, size: 24),
        ),
        label: const Text(
          'Continuer avec Google',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ── Validateurs ──────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Entre ton email';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Email invalide';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Entre ton mot de passe';
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }
}
