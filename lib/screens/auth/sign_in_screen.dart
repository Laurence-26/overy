import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/gradient_button.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  /// When true, after a successful sign-in we mark the user's profile as
  /// partnerOnlyMode = true and skip the cycle-mode setup. The user will land
  /// on PartnerHomeScreen instead.
  final bool asPartner;

  const SignInScreen({super.key, this.asPartner = false});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
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
      // Cover the rare case where we're already signed in when this screen
      // mounts (e.g. fast re-auth).
      _onAuthChanged();
    }
  }

  /// Fires every time AuthProvider notifies. When the auth state flips to
  /// signedIn, write partner mode if needed then pop all auth screens off
  /// the stack so _Root takes over. Robust to the Activity-recreation case
  /// during Google sign-in where the previous in-flight handler's `mounted`
  /// flag becomes unreliable.
  Future<void> _onAuthChanged() async {
    if (!mounted || _hasPopped) return;
    final auth = _auth!;
    if (auth.status != AuthStatus.signedIn) return;
    _hasPopped = true;
    await _markPartnerIfNeeded();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(_emailCtrl.text, _passwordCtrl.text);
    if (!ok && mounted) {
      _showError(auth.error ?? 'Sign in failed');
    }
    // Navigation is handled by the listener.
  }

  Future<void> _google() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!ok && auth.error != null && mounted) {
      _showError(auth.error!);
    }
    // Navigation is handled by the listener.
  }

  /// If this sign-in was launched as "Sign in as partner", flip the
  /// partnerOnlyMode flag on the profile so _Root routes to PartnerHomeScreen.
  /// We poll briefly for the profile to load before writing — it's set by
  /// ensureProfile() in the proxy provider.
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child:
                      const Icon(Icons.spa_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.asPartner
                      ? 'Sign in as a partner'
                      : 'Welcome back',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.asPartner
                      ? 'Connect with your partner to follow their cycle. We\'ll ask for their invite code next.'
                      : 'Sign in to continue tracking your cycle',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (widget.asPartner) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(children: [
                      Icon(Icons.favorite_rounded, color: AppColors.accent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Partner mode: you\'ll see their cycle, not your own.',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email or username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Enter your email or username'
                      : null,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      if (_emailCtrl.text.isEmpty) {
                        _showError('Enter your email first');
                        return;
                      }
                      await context
                          .read<AuthProvider>()
                          .sendPasswordReset(_emailCtrl.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Password reset email sent if account exists.'),
                          ),
                        );
                      }
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: 'Sign in',
                  loading: auth.busy,
                  onPressed: auth.busy ? null : _signIn,
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: AppColors.primaryLight.withOpacity(0.5))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: AppColors.textTertiary)),
                  ),
                  Expanded(child: Divider(color: AppColors.primaryLight.withOpacity(0.5))),
                ]),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: auth.busy ? null : _google,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No account? ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SignUpScreen(asPartner: widget.asPartner),
                        ),
                      ),
                      child: const Text(
                        'Create one',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
