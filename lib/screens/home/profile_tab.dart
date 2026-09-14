import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tracking_mode.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../services/notification_service.dart';
import '../partner/partner_sharing_screen.dart';
import '../theme_studio_screen.dart';
import '../tutorial_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cycle = context.watch<CycleProvider>();
    final profile = cycle.profile;
    final user = auth.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (profile?.displayName ??
                              profile?.username ??
                              user?.displayName ??
                              '?')[0]
                          .toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    profile?.displayName ??
                        profile?.username ??
                        user?.displayName ??
                        'You',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Saved only on this device',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28),
            if (cycle.trackingMode != TrackingMode.pregnancy) ...[
              _section('Cycle settings'),
              _SettingsCard(
                children: [
                  _SliderRow(
                    label: 'Average cycle length',
                    value: profile?.averageCycleLength ??
                        AppConstants.defaultCycleLength,
                    min: AppConstants.minCycleLength,
                    max: AppConstants.maxCycleLength,
                    unit: 'days',
                    onChanged: (v) => _save(context, profile,
                        (p) => p.copyWith(averageCycleLength: v)),
                  ),
                  Divider(),
                  _SliderRow(
                    label: 'Average period length',
                    value: profile?.averagePeriodLength ??
                        AppConstants.defaultPeriodLength,
                    min: AppConstants.minPeriodLength,
                    max: AppConstants.maxPeriodLength,
                    unit: 'days',
                    onChanged: (v) => _save(context, profile,
                        (p) => p.copyWith(averagePeriodLength: v)),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
            _section('Preferences'),
            _SettingsCard(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Notifications'),
                  subtitle:
                      Text('Personalized reminders for your mode and cycle'),
                  value: profile?.notificationsEnabled ?? true,
                  activeColor: AppColors.primary,
                  onChanged: profile == null
                      ? null
                      : (v) async {
                          await _save(context, profile,
                              (p) => p.copyWith(notificationsEnabled: v));
                          if (v) {
                            await NotificationService.instance
                                .requestPermissions();
                          } else {
                            await NotificationService.instance.cancelAll();
                          }
                        },
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.schedule_rounded, color: AppColors.accent),
                  title: Text('Reminder time'),
                  subtitle: Text(
                    _formatTime(
                      profile?.reminderHour ?? 9,
                      profile?.reminderMinute ?? 0,
                    ),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: profile == null
                      ? null
                      : () => _pickReminderTime(context, profile),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.school_rounded, color: AppColors.accent),
                  title: Text('View tutorial'),
                  subtitle: Text(
                    'Replay the in-app guide',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TutorialScreen(replay: true),
                    ),
                  ),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_active_rounded,
                      color: AppColors.accent),
                  title: Text('Send test notification'),
                  subtitle: Text(
                    'Confirms permissions - arrives immediately',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await NotificationService.instance.requestPermissions();
                      await NotificationService.instance
                          .sendTestNotification(profile: profile);
                      messenger.showSnackBar(SnackBar(
                        content: Text('Test sent - check your status bar.'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 3),
                      ));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                        content: Text(
                          'Could not send the test. Allow notifications for Cyclus in phone settings, then try again.',
                        ),
                        backgroundColor: AppColors.error,
                        duration: Duration(seconds: 5),
                      ));
                    }
                  },
                ),
                if (profile != null) ...[
                  Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Period reminders'),
                    value: profile.notifyPeriod,
                    activeColor: AppColors.primary,
                    onChanged: (v) => _save(
                        context, profile, (p) => p.copyWith(notifyPeriod: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Fertile / peak-day reminders'),
                    value: profile.notifyFertile,
                    activeColor: AppColors.primary,
                    onChanged: (v) => _save(
                        context, profile, (p) => p.copyWith(notifyFertile: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Evening check-in'),
                    value: profile.notifyDailyLog,
                    activeColor: AppColors.primary,
                    onChanged: (v) => _save(
                        context, profile, (p) => p.copyWith(notifyDailyLog: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Vitamin reminder'),
                    value: profile.notifyVitamins,
                    activeColor: AppColors.primary,
                    onChanged: (v) => _save(
                        context, profile, (p) => p.copyWith(notifyVitamins: v)),
                  ),
                ],
              ],
            ),
            SizedBox(height: 24),
            _section('Look'),
            _SettingsCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.palette_rounded, color: AppColors.accent),
                  title: Text('App theme'),
                  subtitle: Text(
                    'Colors, photo, Chameleon Code',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: profile == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ThemeStudioScreen(profile: profile),
                            ),
                          ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _section('Mode'),
            _SettingsCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.swap_horiz_rounded, color: AppColors.accent),
                  title: Text('Change tracking mode'),
                  subtitle: Text(
                    cycle.trackingMode?.displayName ?? 'Not set',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => _showModeSwitcher(context, profile),
                ),
              ],
            ),
            SizedBox(height: 24),
            _section('Partner'),
            _SettingsCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.favorite_rounded, color: AppColors.primary),
                  title: Text('Partner sharing'),
                  subtitle: Text(
                    profile?.linkedPartnerUid == null
                        ? 'Same-phone PIN so a partner can follow your cycle'
                        : 'Connected on this device',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PartnerSharingScreen(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            _section('Account'),
            _SettingsCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout_rounded, color: AppColors.error),
                  title: Text('Lock this profile',
                      style: TextStyle(color: AppColors.error)),
                  onTap: () => _signOut(context),
                ),
                Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever_rounded,
                      color: AppColors.error),
                  title: Text('Delete this profile',
                      style: TextStyle(color: AppColors.error)),
                  subtitle: Text(
                    'Permanently erase data on this device',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                'Cyclus v1.0.0',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  Future<void> _save(BuildContext context, UserProfile? profile,
      UserProfile Function(UserProfile) update) async {
    if (profile == null) return;
    await context.read<CycleProvider>().updateProfile(update(profile));
  }

  /// Format hour+minute (24h) as "9:00 AM" / "8:30 PM" for display.
  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$h12:$mm $period';
  }

  Future<void> _pickReminderTime(
      BuildContext context, UserProfile profile) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: profile.reminderHour,
        minute: profile.reminderMinute,
      ),
      helpText: 'When should reminders arrive?',
    );
    if (picked == null || !context.mounted) return;
    await context.read<CycleProvider>().updateProfile(
          profile.copyWith(
            reminderHour: picked.hour,
            reminderMinute: picked.minute,
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Reminders will arrive at ${_formatTime(picked.hour, picked.minute)}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirm != true || !context.mounted) return;

    final cycle = context.read<CycleProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await cycle.wipeAccountData();
      final result = await auth.deleteLocalUser();
      if (result == DeleteAccountResult.failed) {
        messenger.showSnackBar(SnackBar(
          content: Text(auth.error ?? 'Could not delete account'),
          backgroundColor: AppColors.error,
        ));
        return;
      }
      if (!context.mounted) return;
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Delete failed: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Lock this profile?'),
        content: Text(
            'Your data stays on this phone. Unlock with your password anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.signOut();
  }

  Future<void> _showModeSwitcher(
      BuildContext context, UserProfile? profile) async {
    if (profile == null) return;
    final current = profile.trackingMode;

    final picked = await showModalBottomSheet<TrackingMode>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Change tracking mode',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Your cycle history stays - we\'ll just show the right view.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 20),
              for (final mode in TrackingMode.values) ...[
                _ModeRow(
                  mode: mode,
                  selected: mode == current,
                  onTap: () => Navigator.of(ctx).pop(mode),
                ),
                SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );

    if (picked == null || picked == current || !context.mounted) return;
    final cycle = context.read<CycleProvider>();
    await cycle.setTrackingMode(picked);

    // Pregnancy mode needs a due date - prompt if it's missing.
    if (picked == TrackingMode.pregnancy &&
        profile.dueDate == null &&
        context.mounted) {
      final dueDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 200)),
        firstDate: DateTime.now().subtract(const Duration(days: 280)),
        lastDate: DateTime.now().add(const Duration(days: 300)),
        helpText: 'When is your due date?',
      );
      if (dueDate != null && context.mounted) {
        final updated = (cycle.profile ?? profile).copyWith(dueDate: dueDate);
        await cycle.updateProfile(updated);
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${picked.displayName} mode'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _ModeRow extends StatelessWidget {
  final TrackingMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeRow({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (mode) {
      TrackingMode.period => (Icons.water_drop_rounded, AppColors.period),
      TrackingMode.conception => (Icons.spa_rounded, AppColors.fertile),
      TrackingMode.pregnancy => (
          Icons.child_friendly_rounded,
          AppColors.accent
        ),
    };

    return Material(
      color: selected ? color.withOpacity(0.10) : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      mode.tagline,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String unit;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                '$value $unit',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primaryLight.withOpacity(0.5),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal that requires the user to type DELETE before they can confirm.
/// Returns true if the user confirmed, false otherwise.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _ctrl = TextEditingController();
  bool get _canConfirm => _ctrl.text.trim().toUpperCase() == 'DELETE';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Icon(Icons.warning_amber_rounded, color: AppColors.error),
        SizedBox(width: 8),
        Text('Delete account?'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This permanently erases your cycles, daily logs, profile, partner links, and account. This cannot be undone.',
            style: TextStyle(height: 1.4),
          ),
          SizedBox(height: 16),
          Text(
            'Type DELETE to confirm:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: 'DELETE'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
