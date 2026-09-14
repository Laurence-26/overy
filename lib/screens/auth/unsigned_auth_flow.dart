import 'package:flutter/material.dart';

import '../welcome_screen.dart';

/// Nested navigator for Welcome > Get started / Sign in / Partner.
///
/// Kept off the root stack so that when [_Root] switches to the signed-in
/// home, these screens are disposed automatically. Popping them on the root
/// navigator used to land on a Welcome page that was no longer routed by
/// auth state - which looked like the app was stuck.
class UnsignedAuthFlow extends StatelessWidget {
  const UnsignedAuthFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const WelcomeScreen(),
        );
      },
    );
  }
}
