import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/gradient_button.dart';

class SignUpScreen extends StatefulWidget {
  final bool asPartner;

  const SignUpScreen({super.key, this.asPartner = false});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameCtrl.text.trim();
    final ok = await auth.signUp(
      email: '',
      password: _passwordCtrl.text,
      displayName: name,
      username: name,
      asPartner: widget.asPartner,
    );
    if (!mounted) return;
    if (ok) {
      final uid = auth.user?.uid;
      if (uid != null) {
        await context.read<CycleProvider>().ensureProfile(
              uid: uid,
              email: auth.user?.email ?? '',
              username: name,
              displayName: name,
              partnerOnly: widget.asPartner,
            );
      }
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text(auth.error ?? 'Could not create profile'),
      backgroundColor: AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.asPartner
                      ? 'Create a partner profile'
                      : 'Create your space',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  widget.asPartner
                      ? 'On this phone only. Next you\'ll enter her 6-digit PIN.'
                      : 'Private to this device - no internet required.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                SizedBox(height: 32),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Please enter your name'
                      : null,
                ),
                SizedBox(height: 14),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 4)
                      ? 'Minimum 4 characters'
                      : null,
                ),
                SizedBox(height: 24),
                GradientButton(
                  label: 'Create profile',
                  loading: auth.busy,
                  onPressed: auth.busy ? null : _signUp,
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
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
