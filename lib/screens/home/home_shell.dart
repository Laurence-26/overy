import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton.extended(
              onPressed: () => showLogPeriodSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.water_drop_rounded),
              label: const Text('Log'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.spa_outlined),
              activeIcon: Icon(Icons.spa_rounded),
              label: 'Today'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights_rounded),
              label: 'Insights'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
