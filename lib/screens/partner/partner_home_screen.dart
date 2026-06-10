import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cycle.dart';
import '../../models/cycle_prediction.dart';
import '../../models/pregnancy_status.dart';
import '../../models/tracking_mode.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../services/partner_service.dart';
import '../../services/prediction_engine.dart';
import '../../widgets/cycle_ring.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/stat_card.dart';
import '../welcome_screen.dart';

/// Standalone home for users who signed in as a partner.
/// Shows a read-only summary of the *linked partner's* cycle data.
/// Supports multiple linked partners with a chip selector at the top.
///
/// If no partner is linked yet, prompts to enter the partner's invite code.
class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  String? _selectedUid;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CycleProvider>().profile;
    final linkedUids = profile?.linkedPartnerUids ?? const <String>[];

    // Keep selection in sync with the list.
    if (linkedUids.isEmpty) {
      _selectedUid = null;
    } else if (_selectedUid == null || !linkedUids.contains(_selectedUid)) {
      _selectedUid = linkedUids.last;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner view'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              if (v == 'signout') _signOut(context);
              if (v == 'delete') _deleteAccount(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'signout',
                child: Row(children: [
                  Icon(Icons.logout_rounded,
                      color: AppColors.textSecondary, size: 18),
                  SizedBox(width: 10),
                  Text('Sign out'),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_forever_rounded,
                      color: AppColors.error, size: 18),
                  SizedBox(width: 10),
                  Text('Delete account',
                      style: TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: linkedUids.isEmpty
            ? const _PartnerNotLinkedView()
            : Column(
                children: [
                  if (linkedUids.length > 1)
                    _PartnerSwitcher(
                      uids: linkedUids,
                      selectedUid: _selectedUid!,
                      onSelect: (u) => setState(() => _selectedUid = u),
                    ),
                  Expanded(
                    child: _PartnerLinkedView(partnerUid: _selectedUid!),
                  ),
                  _AddAnotherPartnerBar(),
                ],
              ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final typed = await showDialog<String>(
      context: context,
      builder: (_) => const _ConfirmDeleteDialog(),
    );
    if (typed != 'DELETE' || !context.mounted) return;
    final cycle = context.read<CycleProvider>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      await cycle.wipeAccountData();
      final result = await auth.deleteFirebaseUser();
      if (result == DeleteAccountResult.requiresReauth) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Please sign in again, then delete the account.'),
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
    final navigator = Navigator.of(context, rootNavigator: true);
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }
}

// ===================== Not linked yet =====================
class _PartnerNotLinkedView extends StatefulWidget {
  const _PartnerNotLinkedView();
  @override
  State<_PartnerNotLinkedView> createState() => _PartnerNotLinkedViewState();
}

class _PartnerNotLinkedViewState extends State<_PartnerNotLinkedView> {
  final _ctrl = TextEditingController();
  final _partnerSvc = PartnerService();
  bool _connecting = false;

  Future<void> _connect() async {
    final code = _ctrl.text.trim();
    if (code.length != 6) {
      _err('Enter the 6-digit code your partner shared.');
      return;
    }
    setState(() => _connecting = true);
    try {
      final invite = await _partnerSvc.lookupCode(code);
      final profile = context.read<CycleProvider>().profile;
      if (profile == null) return;
      if (invite.partnerUid == profile.uid) {
        _err('That\'s your own code.');
        return;
      }
      await context.read<CycleProvider>().updateProfile(
            profile.copyWith(addLinkedPartnerUid: invite.partnerUid),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Connected to ${invite.partnerDisplayName ?? "your partner"} 💕'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      _err(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 48),
          )
              .animate(),
          const SizedBox(height: 24),
          const Text(
            'Connect to your partner',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask your partner to share their 6-digit invite code with you. Find it in their app under Profile → Partner sharing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _ctrl,
            autofocus: false,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
              color: AppColors.primary,
            ),
            decoration: const InputDecoration(
              hintText: '000000',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Connect',
            loading: _connecting,
            icon: Icons.link_rounded,
            onPressed: _connecting ? null : _connect,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// Small no-op extension so the animate() call above doesn't need a package.
extension on Widget {
  Widget animate() => this;
}

// ===================== Linked: show partner's status =====================
class _PartnerLinkedView extends StatelessWidget {
  final String partnerUid;
  const _PartnerLinkedView({required this.partnerUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUid)
          .snapshots(),
      builder: (ctx, profileSnap) {
        if (profileSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (profileSnap.hasError ||
            !profileSnap.hasData ||
            !profileSnap.data!.exists) {
          return _PartnerUnreachable(
            partnerUid: partnerUid,
            hasError: profileSnap.hasError,
            error: profileSnap.error?.toString(),
          );
        }
        final partner = UserProfile.fromMap(profileSnap.data!.data()!);
        final mode = partner.trackingMode ?? TrackingMode.period;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(partnerUid)
              .collection('cycles')
              .orderBy('startDate', descending: true)
              .limit(10)
              .snapshots(),
          builder: (ctx, cyclesSnap) {
            final cycles = (cyclesSnap.data?.docs ?? [])
                .map((d) => Cycle.fromMap(d.data()))
                .toList();
            return _PartnerStatusBody(
              partner: partner,
              cycles: cycles,
              mode: mode,
            );
          },
        );
      },
    );
  }
}

class _PartnerStatusBody extends StatelessWidget {
  final UserProfile partner;
  final List<Cycle> cycles;
  final TrackingMode mode;

  const _PartnerStatusBody({
    required this.partner,
    required this.cycles,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final partnerName = partner.displayName ??
        partner.username ??
        partner.email.split('@').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PartnerHeader(name: partnerName, mode: mode),
          const SizedBox(height: 24),
          if (mode == TrackingMode.pregnancy)
            _PregnancyBody(partner: partner)
          else
            _CycleBody(partner: partner, cycles: cycles, mode: mode),
        ],
      ),
    );
  }
}

class _PartnerHeader extends StatelessWidget {
  final String name;
  final TrackingMode mode;
  const _PartnerHeader({required this.name, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Following $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mode.displayName} • Updated live',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _CycleBody extends StatelessWidget {
  final UserProfile partner;
  final List<Cycle> cycles;
  final TrackingMode mode;
  const _CycleBody({
    required this.partner,
    required this.cycles,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final p = PredictionEngine.predict(
      cyclesNewestFirst: cycles,
      fallbackCycleLength: partner.averageCycleLength,
      fallbackPeriodLength: partner.averagePeriodLength,
    );
    final current = cycles.isNotEmpty ? cycles.first : null;
    final phase = p == null
        ? CyclePhase.unknown
        : PredictionEngine.phaseFor(
            day: DateTime.now(),
            cyclesNewestFirst: cycles,
            prediction: p,
          );

    if (p == null) {
      return _emptyCard(
          'Your partner hasn\'t logged any cycle data yet. The home screen will fill in as soon as they do.');
    }

    final fertileLabel = mode == TrackingMode.conception
        ? 'High-chance days'
        : 'Fertile window';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: CycleRing(currentCycle: current, prediction: p)),
        const SizedBox(height: 28),
        _phaseTip(phase, mode),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: StatCard(
              icon: Icons.water_drop_rounded,
              label: 'Next period',
              value: DateFormat('MMM d').format(p.nextPeriodStart),
              subtitle: '${p.daysUntilNextPeriod(DateTime.now())} days',
              color: AppColors.period,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.eco_rounded,
              label: fertileLabel,
              value:
                  '${DateFormat('MMM d').format(p.fertileWindowStart)} – ${DateFormat('MMM d').format(p.fertileWindowEnd)}',
              color: AppColors.fertile,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: StatCard(
              icon: Icons.repeat_rounded,
              label: 'Cycle length',
              value: '${p.averageCycleLength} days',
              subtitle: p.isIrregular ? 'Irregular' : 'Regular',
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.verified_rounded,
              label: 'Confidence',
              value: '${p.confidence}%',
              color: AppColors.ovulation,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _SupportTipCard(phase: phase, mode: mode),
      ],
    );
  }

  Widget _phaseTip(CyclePhase phase, TrackingMode mode) {
    final (label, color) = switch (phase) {
      CyclePhase.period =>
        ('She\'s on her period right now', AppColors.period),
      CyclePhase.fertile => mode == TrackingMode.conception
          ? ('High chance to conceive', AppColors.fertile)
          : ('In fertile window', AppColors.fertile),
      CyclePhase.ovulation => ('Ovulation day', AppColors.ovulation),
      CyclePhase.predicted => ('Period expected soon', AppColors.predicted),
      CyclePhase.follicular => ('Energy ramping up', AppColors.accent),
      CyclePhase.luteal => ('Pre-period luteal phase', AppColors.accentDark),
      CyclePhase.unknown => ('Cycle phase unknown', AppColors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _emptyCard(String body) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty_rounded,
                color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(body,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}

class _PregnancyBody extends StatelessWidget {
  final UserProfile partner;
  const _PregnancyBody({required this.partner});

  @override
  Widget build(BuildContext context) {
    PregnancyStatus? status;
    if (partner.dueDate != null) {
      status = PregnancyStatus.fromDueDate(partner.dueDate!);
    } else if (partner.lastMenstrualPeriod != null) {
      status = PregnancyStatus.fromLmp(partner.lastMenstrualPeriod!);
    }
    if (status == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Your partner hasn\'t set a due date yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: status.progress,
                  strokeWidth: 18,
                  backgroundColor: AppColors.accentLight.withOpacity(0.35),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Week ${status.weeksAlong}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      )),
                  Text('${status.daysIntoWeek} days',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: StatCard(
              icon: Icons.event_available_rounded,
              label: 'Due date',
              value: DateFormat('MMM d').format(status.dueDate),
              subtitle: '${status.daysUntilDue} days to go',
              color: AppColors.period,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.eco_rounded,
              label: 'Trimester',
              value: status.trimesterLabel,
              color: AppColors.fertile,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(children: [
            Icon(Icons.tips_and_updates_rounded, color: AppColors.accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Check in often, offer extra rest, and celebrate every milestone together.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _SupportTipCard extends StatelessWidget {
  final CyclePhase phase;
  final TrackingMode mode;
  const _SupportTipCard({required this.phase, required this.mode});

  @override
  Widget build(BuildContext context) {
    final tip = _tipFor(phase, mode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.tips_and_updates_rounded, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ]),
    );
  }

  String _tipFor(CyclePhase phase, TrackingMode mode) {
    if (mode == TrackingMode.conception &&
        (phase == CyclePhase.fertile || phase == CyclePhase.ovulation)) {
      return 'These are your highest-chance days. Be present, gentle, and intentional together.';
    }
    return switch (phase) {
      CyclePhase.period =>
        'She may feel low-energy. Offer warmth, comfort food, and patience.',
      CyclePhase.fertile =>
        'Energy and mood usually peak right now — a great time for shared plans.',
      CyclePhase.ovulation =>
        'Peak fertility today. Make her feel cherished.',
      CyclePhase.predicted => 'Pre-period soon — be extra understanding.',
      CyclePhase.follicular =>
        'Mood often lifts after a period. A good time for activity.',
      CyclePhase.luteal =>
        'PMS can show up. Lead with empathy and small kindnesses.',
      CyclePhase.unknown => 'Stay tuned — predictions will sharpen with more data.',
    };
  }
}

class _PartnerUnreachable extends StatefulWidget {
  final String partnerUid;
  final bool hasError;
  final String? error;
  const _PartnerUnreachable({
    required this.partnerUid,
    required this.hasError,
    this.error,
  });

  @override
  State<_PartnerUnreachable> createState() => _PartnerUnreachableState();
}

class _PartnerUnreachableState extends State<_PartnerUnreachable> {
  bool _repairing = false;
  bool _autoRepairTried = false;
  String? _repairError;

  @override
  void initState() {
    super.initState();
    // Self-heal once on first appearance: maybe this is an old partner link
    // missing its partnerships doc. If the write succeeds the read stream
    // will rebuild and we'll move past this screen automatically.
    WidgetsBinding.instance.addPostFrameCallback((_) => _repair(silent: true));
  }

  Future<void> _repair({bool silent = false}) async {
    if (_repairing || _autoRepairTried && silent) return;
    if (silent) _autoRepairTried = true;
    setState(() {
      _repairing = true;
      _repairError = null;
    });
    final profile = context.read<CycleProvider>().profile;
    try {
      if (profile == null) throw Exception('No profile loaded yet.');
      await PartnerService().ensurePartnership(
        viewerUid: profile.uid,
        ownerUid: widget.partnerUid,
      );
    } catch (e) {
      _repairError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _repairing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'Can\'t reach your partner\'s data',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.hasError
                  ? 'We just tried to repair the connection. If this keeps showing, your partner needs to publish the updated Firestore rules.'
                  : 'Their account isn\'t available right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 12),
              Text(widget.error!,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11)),
            ],
            if (_repairError != null) ...[
              const SizedBox(height: 8),
              Text('Repair failed: $_repairError',
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 11)),
            ],
            const SizedBox(height: 24),
            // "Try to repair" — re-creates the partnerships doc. Fixes old
            // links made before linkPartner() existed.
            ElevatedButton.icon(
              icon: _repairing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.healing_rounded),
              label: Text(_repairing ? 'Repairing…' : 'Try to repair'),
              onPressed: _repairing ? null : () => _repair(),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Disconnect this partner'),
              onPressed: () async {
                final cycle = context.read<CycleProvider>();
                final p = cycle.profile;
                if (p == null) return;
                // Tear down the partnerships doc and remove just this partner
                // from the linked list — keep the user's other partners intact.
                await PartnerService().unlinkPartner(
                  viewerUid: p.uid,
                  ownerUid: widget.partnerUid,
                );
                await cycle.updateProfile(
                  p.copyWith(removeLinkedPartnerUid: widget.partnerUid),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Silence unused-import warnings — AppConstants is used by other partner code paths.
// ignore: unused_element
typedef _Unused = AppConstants;

/// Horizontal chip selector shown when there are 2+ linked partners.
class _PartnerSwitcher extends StatelessWidget {
  final List<String> uids;
  final String selectedUid;
  final ValueChanged<String> onSelect;
  const _PartnerSwitcher({
    required this.uids,
    required this.selectedUid,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: uids.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final uid = uids[i];
          final selected = uid == selectedUid;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (ctx, snap) {
              String label = 'Partner';
              if (snap.hasData && (snap.data?.exists ?? false)) {
                final p = UserProfile.fromMap(snap.data!.data()!);
                label = (p.displayName ??
                        p.username ??
                        p.email.split('@').first)
                    .split(' ')
                    .first;
              }
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelect(uid),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite_rounded,
                          size: 14,
                          color: selected
                              ? Colors.white
                              : AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// CTA pinned at the bottom that opens the code-entry dialog to add another
/// partner without leaving the partner home.
class _AddAnotherPartnerBar extends StatefulWidget {
  @override
  State<_AddAnotherPartnerBar> createState() => _AddAnotherPartnerBarState();
}

class _AddAnotherPartnerBarState extends State<_AddAnotherPartnerBar> {
  final _partnerSvc = PartnerService();
  bool _busy = false;

  Future<void> _addCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _AddCodeDialog(),
    );
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final profile = context.read<CycleProvider>().profile;
      if (profile == null) return;
      final invite = await _partnerSvc.linkPartner(
        code: code,
        viewerUid: profile.uid,
        viewerDisplayName: profile.displayName ?? profile.username,
      );
      await context.read<CycleProvider>().updateProfile(
            profile.copyWith(addLinkedPartnerUid: invite.partnerUid),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Now also following ${invite.partnerDisplayName ?? "your partner"}'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _addCode,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded),
          label: const Text('Add another partner'),
        ),
      ),
    );
  }
}

class _AddCodeDialog extends StatefulWidget {
  const _AddCodeDialog();
  @override
  State<_AddCodeDialog> createState() => _AddCodeDialogState();
}

class _AddCodeDialogState extends State<_AddCodeDialog> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add partner\'s code'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 6,
        ),
        decoration: const InputDecoration(
          hintText: '000000',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: const Text('Connect'),
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

/// Type-to-confirm "delete account" dialog. Returns the typed text on confirm.
class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog();
  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
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
            'This permanently erases your partner links, profile, and account. This cannot be undone.',
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canConfirm
              ? () => Navigator.of(context).pop(_ctrl.text.trim().toUpperCase())
              : null,
          child:
              const Text('Delete', style: TextStyle(color: AppColors.error)),
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
