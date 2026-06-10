import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/gradient_button.dart';
import 'sign_in_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      displayName: _usernameCtrl.text.trim(),
    );
    if (ok && mounted) {
      // Pre-stash username in profile (the proxy provider rebinds CycleProvider
      // to the new uid once auth state changes).
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      final uid = auth.user?.uid;
      if (uid != null) {
        await context.read<CycleProvider>().ensureProfile(
              uid: uid,
              email: _emailCtrl.text.trim(),
              username: _usernameCtrl.text.trim(),
              displayName: _usernameCtrl.text.trim(),
            );
      }
    } else if (!ok && mounted) {
      _toast(auth.error ?? 'Sign up failed', error: true);
    }
  }

  Future<void> _google() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithGoogle();
    if (!ok && auth.error != null && mounted) _toast(auth.error!, error: true);
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create your account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A private, beautiful space — just for you.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'At least 3 characters';
                    }
                    if (v.contains(' ')) return 'No spaces, please';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Minimum 6 characters'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) =>
                      v != _passwordCtrl.text ? 'Passwords don\'t match' : null,
                ),
                const SizedBox(height: 28),
                GradientButton(
                  label: 'Get started',
                  loading: auth.busy,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: auth.busy ? null : _signUp,
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: Divider(
                          color: AppColors.primaryLight.withOpacity(0.5))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(color: AppColors.textTertiary)),
                  ),
                  Expanded(
                      child: Divider(
                          color: AppColors.primaryLight.withOpacity(0.5))),
                ]),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: auth.busy ? null : _google,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already a member? ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const SignInScreen()),
                      ),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
}
