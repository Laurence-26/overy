import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/gradient_button.dart';

class SignUpScreen extends StatefulWidget {
  /// When true, marks the new account as partnerOnlyMode after sign-up so the
  /// user lands on PartnerHomeScreen instead of the cycle-mode setup.
  final bool asPartner;

  const SignUpScreen({super.key, this.asPartner = false});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _hasPopped = false;
  AuthProvider? _auth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (_auth != auth) {
      _auth?.removeListener(_onAuthChanged);
      _auth = auth;
      _auth!.addListener(_onAuthChanged);
      _onAuthChanged();
    }
  }

  Future<void> _onAuthChanged() async {
    if (!mounted || _hasPopped) return;
    if (_auth!.status != AuthStatus.signedIn) return;
    _hasPopped = true;
    await _markPartnerIfNeeded();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text,
    );
    if (!ok && mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Sign up failed'),
        backgroundColor: AppColors.error,
      ));
    }
    // Navigation handled by the listener.
  }

  /// After successful sign-up via the "Sign in as partner" flow, mark the
  /// profile so _Root routes to PartnerHomeScreen.
  Future<void> _markPartnerIfNeeded() async {
    if (!widget.asPartner) return;
    final cycle = context.read<CycleProvider>();
    for (var i = 0; i < 20; i++) {
      if (cycle.profile != null) break;
      await Future.delayed(const Duration(milliseconds: 150));
    }
    final profile = cycle.profile;
    if (profile == null) return;
    await cycle.updateProfile(profile.copyWith(
      partnerOnlyMode: true,
      setupComplete: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.asPartner
                      ? 'Create a partner account'
                      : 'Create account',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.asPartner
                      ? 'Sign up to follow your partner\'s cycle. We\'ll ask for their invite code next.'
                      : 'Begin your personalized cycle journey',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Sign up',
                  loading: auth.busy,
                  onPressed: auth.busy ? null : _signUp,
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'By creating an account you agree to our Terms & Privacy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
