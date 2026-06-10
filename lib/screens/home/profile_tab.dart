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
import '../tutorial_screen.dart';
import '../welcome_screen.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
                      (profile?.displayName ?? user?.email ?? '?')[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile?.displayName ?? user?.displayName ?? 'You',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style:
                        const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
                  onChanged: (v) => _save(context,
                      profile, (p) => p.copyWith(averageCycleLength: v)),
                ),
                const Divider(),
                _SliderRow(
                  label: 'Average period length',
                  value: profile?.averagePeriodLength ??
                      AppConstants.defaultPeriodLength,
                  min: AppConstants.minPeriodLength,
                  max: AppConstants.maxPeriodLength,
                  unit: 'days',
                  onChanged: (v) => _save(context,
                      profile, (p) => p.copyWith(averagePeriodLength: v)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section('Preferences'),
            _SettingsCard(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications'),
                  subtitle: const Text(
                      'Reminders 3, 2 & 1 day before each phase'),
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
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_rounded,
                      color: AppColors.accent),
                  title: const Text('Reminder time'),
                  subtitle: Text(
                    _formatTime(
                      profile?.reminderHour ?? 9,
                      profile?.reminderMinute ?? 0,
                    ),
                    style:
                        const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: profile == null
                      ? null
                      : () => _pickReminderTime(context, profile),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.school_rounded,
                      color: AppColors.accent),
                  title: const Text('View tutorial'),
                  subtitle: const Text(
                    'Replay the in-app guide',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TutorialScreen(replay: true),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.accent),
                  title: const Text('Send test notification'),
                  subtitle: const Text(
                    'Arrives in 5 seconds — confirms permissions',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await NotificationService.instance.requestPermissions();
                      await NotificationService.instance.sendTestNotification();
                      messenger.showSnackBar(const SnackBar(
                        content: Text('Test sent — check your status bar.'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 3),
                      ));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                        content: Text('Notification failed: $e'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 8),
                      ));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section('Mode'),
            _SettingsCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.accent),
                  title: const Text('Change tracking mode'),
                  subtitle: Text(
                    cycle.trackingMode?.displayName ?? 'Not set',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showModeSwitcher(context, profile),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section('Partner'),
            _SettingsCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.favorite_rounded,
                      color: AppColors.primary),
                  title: const Text('Partner sharing'),
                  subtitle: Text(
                    profile?.linkedPartnerUid == null
                        ? 'Invite or connect with a partner'
                        : 'Connected',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PartnerSharingScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section('Account'),
            _SettingsCard(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout_rounded,
                      color: AppColors.error),
                  title: const Text('Sign out',
                      style: TextStyle(color: AppColors.error)),
                  onTap: () => _signOut(context),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.error),
                  title: const Text('Delete account',
                      style: TextStyle(color: AppColors.error)),
                  subtitle: const Text(
                    'Permanently erase your data and account',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Cyclus v1.0.0',
                style:
                    TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          label,
          style: const TextStyle(
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
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      await cycle.wipeAccountData();
      final result = await auth.deleteFirebaseUser();
      if (result == DeleteAccountResult.requiresReauth) {
        messenger.showSnackBar(const SnackBar(
          content: Text(
              'Please sign in again, then delete the account.'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 5),
        ));
        await auth.signOut();
      } else if (result == DeleteAccountResult.failed) {
        messenger.showSnackBar(SnackBar(
          content: Text(auth.error ?? 'Could not delete account'),
          backgroundColor: AppColors.error,
        ));
        return;
      }
      if (!context.mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
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
        title: const Text('Sign out?'),
        content: const Text('Your data stays safe in your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);
    await auth.signOut();
    if (!context.mounted) return;
    // Route to Welcome (not SignIn) so the user can pick "Sign in" or
    // "Sign in as partner" on their next entry.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _showModeSwitcher(
      BuildContext context, UserProfile? profile) async {
    if (profile == null) return;
    final current = profile.trackingMode;

    final picked = await showModalBottomSheet<TrackingMode>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const SizedBox(height: 18),
              const Text(
                'Change tracking mode',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your cycle history stays — we\'ll just show the right view.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              for (final mode in TrackingMode.values) ...[
                _ModeRow(
                  mode: mode,
                  selected: mode == current,
                  onTap: () => Navigator.of(ctx).pop(mode),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );

    if (picked == null || picked == current || !context.mounted) return;
    final cycle = context.read<CycleProvider>();
    await cycle.setTrackingMode(picked);

    // Pregnancy mode needs a due date — prompt if it's missing.
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
      TrackingMode.pregnancy =>
        (Icons.child_friendly_rounded, AppColors.accent),
    };

    return Material(
      color: selected ? color.withOpacity(0.10) : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.tagline,
                      style: const TextStyle(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                '$value $unit',
                style: const TextStyle(
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
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded, color: AppColors.error),
        SizedBox(width: 8),
        Text('Delete account?'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This permanently erases your cycles, daily logs, profile, partner links, and account. This cannot be undone.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Type DELETE to confirm:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'DELETE'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canConfirm
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Delete',
              style: TextStyle(color: AppColors.error)),
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
