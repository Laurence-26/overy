import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cycle_provider.dart';
import 'providers/theme_provider.dart';
import 'models/cycle_prediction.dart';
import 'screens/home/home_shell.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/partner/partner_home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/auth/unsigned_auth_flow.dart';
import 'services/auth_service.dart';
import 'widgets/theme_backdrop.dart';

class CyclusApp extends StatelessWidget {
  const CyclusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProxyProvider<AuthProvider, CycleProvider>(
          create: (_) => CycleProvider(),
          update: (_, auth, cycle) {
            final c = cycle ?? CycleProvider();
            final uid = auth.user?.uid;
            if (uid != null) {
              c.bind(
                uid,
                email: auth.user?.email ?? '',
                username: auth.user?.username,
                displayName: auth.user?.displayName,
                partnerOnly: auth.partnerIntent,
              );
            } else if (!auth.busy) {
              c.unbind();
            }
            return c;
          },
        ),
      ],
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatefulWidget {
  const _ThemedApp();

  @override
  State<_ThemedApp> createState() => _ThemedAppState();
}

class _ThemedAppState extends State<_ThemedApp> with WidgetsBindingObserver {
  String? _syncedKey;
  CyclePhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final cycle = context.read<CycleProvider>();
      context
          .read<ThemeController>()
          .updateCyclePhase(cycle.phaseFor(DateTime.now()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    final cycle = context.watch<CycleProvider>();
    final profile = cycle.profile;
    final syncKey = profile == null
        ? null
        : '${profile.themeId}|${jsonEncode(profile.themePrefs)}';
    final phase = cycle.phaseFor(DateTime.now());

    if (syncKey != null && syncKey != _syncedKey) {
      _syncedKey = syncKey;
      _lastPhase = phase;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || profile == null) return;
        context.read<ThemeController>().syncFromProfile(
              themeId: profile.themeId,
              themePrefs: profile.themePrefs,
              phase: phase,
            );
      });
    } else if (_lastPhase != phase) {
      _lastPhase = phase;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ThemeController>().updateCyclePhase(phase);
      });
    }

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.fromPrefs(theme.prefs),
      debugShowCheckedModeBanner: false,
      home: const _Root(),
    );
  }
}

/// Routes between Welcome > ModeSelection > Home based on auth + profile state.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cycle = context.watch<CycleProvider>();

    if (auth.status == AuthStatus.unknown) return const SplashScreen();

    if (auth.user == null) {
      return const ThemeBackdrop(child: UnsignedAuthFlow());
    }

    if (cycle.profile == null) return const SplashScreen();

    final profile = cycle.profile;

    if (profile?.partnerOnlyMode == true) {
      return const ThemeBackdrop(child: PartnerHomeScreen());
    }

    if (profile?.setupComplete != true) {
      return const ThemeBackdrop(child: ModeSelectionScreen());
    }

    if (profile?.hasSeenTutorial != true) {
      return const ThemeBackdrop(child: TutorialScreen());
    }

    return const ThemeBackdrop(child: HomeShell());
  }
}
