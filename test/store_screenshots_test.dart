import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/theme/app_colors.dart';
import 'package:period_tracker/core/theme/app_theme.dart';
import 'package:period_tracker/models/theme_prefs.dart';
import 'package:period_tracker/providers/cycle_provider.dart';
import 'package:period_tracker/providers/theme_provider.dart';
import 'package:period_tracker/screens/home/calendar_tab.dart';
import 'package:period_tracker/screens/home/insights_tab.dart';
import 'package:period_tracker/screens/home/today_tab.dart';
import 'package:period_tracker/screens/theme_studio_screen.dart';
import 'package:period_tracker/widgets/theme_backdrop.dart';

/// Captures real Flutter UI (same widgets as the APK) into store_listing/screenshots.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CycleProvider cycle;
  late ThemeController theme;
  final outDir = Directory('store_listing/screenshots');

  setUp(() {
    outDir.createSync(recursive: true);
    cycle = CycleProvider();
    cycle.loadStoreDemo();
    theme = ThemeController();
    theme.syncFromProfile(
      themeId: cycle.profile!.themeId,
      themePrefs: cycle.profile!.themePrefs,
      phase: cycle.phaseFor(DateTime.now()),
    );
  });

  Future<void> pumpPhone(WidgetTester tester, Widget body, {int nav = 0}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>.value(value: theme),
          ChangeNotifierProvider<CycleProvider>.value(value: cycle),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.fromPrefs(theme.prefs),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 780),
              padding: EdgeInsets.only(top: 28, bottom: 16),
              devicePixelRatio: 3,
            ),
            child: ThemeBackdrop(
              child: RepaintBoundary(
                key: const ValueKey('store-shot'),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: body,
                  floatingActionButton: nav == 0
                      ? FloatingActionButton.extended(
                          onPressed: () {},
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          icon: const Icon(Icons.water_drop_rounded),
                          label: const Text('Log period',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        )
                      : null,
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: nav,
                    selectedItemColor: AppColors.primary,
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.spa_rounded), label: 'Today'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.calendar_today_rounded),
                          label: 'Calendar'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.insights_rounded),
                          label: 'Insights'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.person_rounded), label: 'You'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Avoid pumpAndSettle — repeating controllers can hang forever.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> save(WidgetTester tester, String fileName) async {
    final boundary = tester.renderObject(
      find.byKey(const ValueKey('store-shot')),
    ) as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${outDir.path}/$fileName');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('Wrote ${file.path} (${file.lengthSync()} bytes)');
  }

  testWidgets('capture Today (flower)', (tester) async {
    await theme.setCycleView(CycleViewStyle.flower);
    await pumpPhone(tester, const TodayTab());
    await save(tester, '01_today_flower.png');
  });

  testWidgets('capture Today (card)', (tester) async {
    await theme.setCycleView(CycleViewStyle.card);
    await pumpPhone(tester, const TodayTab());
    await save(tester, '02_today_card.png');
  });

  testWidgets('capture Calendar', (tester) async {
    await pumpPhone(tester, const CalendarTab(), nav: 1);
    await save(tester, '03_calendar.png');
  });

  testWidgets('capture Insights', (tester) async {
    await pumpPhone(tester, const InsightsTab(), nav: 2);
    await save(tester, '04_insights.png');
  });

  testWidgets('capture Theme studio', (tester) async {
    await pumpPhone(
      tester,
      ThemeStudioScreen(profile: cycle.profile!),
      nav: 3,
    );
    await save(tester, '05_theme_studio.png');
  });
}
