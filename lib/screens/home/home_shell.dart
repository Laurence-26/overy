import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/tracking_mode.dart';
import '../../providers/cycle_provider.dart';
import '../day_detail_screen.dart';
import '../log/log_period_sheet.dart';
import 'calendar_tab.dart';
import 'insights_tab.dart';
import 'profile_tab.dart';
import 'today_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    TodayTab(),
    CalendarTab(),
    InsightsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final cycle = context.watch<CycleProvider>();
    final mode = cycle.trackingMode ?? TrackingMode.period;
    final accent = switch (mode) {
      TrackingMode.period => AppColors.primary,
      TrackingMode.conception => AppColors.fertile,
      TrackingMode.pregnancy => AppColors.accent,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                if (mode == TrackingMode.period) {
                  showLogPeriodSheet(context);
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DayDetailScreen(date: DateTime.now()),
                  ));
                }
              },
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: const StadiumBorder(),
              icon: Icon(switch (mode) {
                TrackingMode.period => Icons.water_drop_rounded,
                TrackingMode.conception => Icons.favorite_rounded,
                TrackingMode.pregnancy => Icons.edit_note_rounded,
              }),
              label: Text(
                mode.logFabLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            )
          : null,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                accent.withOpacity(0.08),
                Colors.white.withOpacity(0.72),
              ),
              border: Border(
                top: BorderSide(color: accent.withOpacity(0.14)),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              selectedItemColor: accent,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              items: [
                BottomNavigationBarItem(
                    icon: Icon(Icons.spa_outlined),
                    activeIcon: Icon(Icons.spa_rounded),
                    label: mode == TrackingMode.pregnancy ? 'Today' : 'Today'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today_outlined),
                    activeIcon: Icon(Icons.calendar_today_rounded),
                    label: 'Calendar'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.insights_outlined),
                    activeIcon: Icon(Icons.insights_rounded),
                    label: mode == TrackingMode.conception
                        ? 'Fertility'
                        : 'Insights'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'You'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
