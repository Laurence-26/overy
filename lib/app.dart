import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cycle_provider.dart';
import 'screens/home/home_shell.dart';
import 'screens/mode_selection_screen.dart';
import 'screens/partner/partner_home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';

class CyclusApp extends StatelessWidget {
  const CyclusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        // CycleProvider is rebound to the current uid whenever auth changes.
        ChangeNotifierProxyProvider<AuthProvider, CycleProvider>(
          create: (_) => CycleProvider(),
          update: (_, auth, cycle) {
            final c = cycle ?? CycleProvider();
            final uid = auth.user?.uid;
            if (uid != null) {
              c.bind(uid);
              c.ensureProfile(
                uid: uid,
                email: auth.user?.email ?? '',
                displayName: auth.user?.displayName,
              );
            } else {
              c.unbind();
            }
            return c;
          },
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const _Root(),
      ),
    );
  }
}

/// Routes between Welcome → ModeSelection → Home based on auth + profile state.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cycle = context.watch<CycleProvider>();

    // Still resolving auth state
    if (auth.status == AuthStatus.unknown) return const SplashScreen();

    // Signed-out → welcome (which leads to sign-up / sign-in)
    if (auth.status == AuthStatus.signedOut) return const WelcomeScreen();

    // Signed in but profile + cycles still loading
    if (cycle.loading && cycle.profile == null) return const SplashScreen();

    final profile = cycle.profile;

    // Partner-only mode: skip the regular setup + home shell entirely.
    // PartnerHomeScreen handles both "not linked yet" and "linked" states.
    if (profile?.partnerOnlyMode == true) {
      return const PartnerHomeScreen();
    }

    // No tracking mode chosen yet, or setup not complete → mode selection
    if (profile?.setupComplete != true) {
      return const ModeSelectionScreen();
    }

    // First-time visitors land on the tutorial; veterans go straight to home.
    // The tutorial sets hasSeenTutorial=true on Skip / finish.
    if (profile?.hasSeenTutorial != true) {
      return const TutorialScreen();
    }

    return const HomeShell();
  }
}
