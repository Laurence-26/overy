import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cycle_prediction.dart';
import '../../models/tracking_mode.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../services/cycle_service.dart';
import '../../services/partner_service.dart';
import '../../services/partner_share_io.dart';
import '../../widgets/gradient_button.dart';

/// Hub screen for partner sharing. Shows your invite code + a place to enter
/// a partner's code, plus a "Partner status" entry once a link is active.
class PartnerSharingScreen extends StatefulWidget {
  const PartnerSharingScreen({super.key});

  @override
  State<PartnerSharingScreen> createState() => _PartnerSharingScreenState();
}

class _PartnerSharingScreenState extends State<PartnerSharingScreen> {
  final _partnerSvc = PartnerService();
  String? _myCode;
  bool _loadingCode = false;
  bool _connecting = false;
  bool _exporting = false;

  Future<void> _generateOrRefresh() async {
    final user = context.read<AuthProvider>().user;
    final profile = context.read<CycleProvider>().profile;
    if (user == null) return;
    setState(() => _loadingCode = true);
    try {
      final code = await _partnerSvc.generateInviteCode(
        uid: user.uid,
        displayName: profile?.displayName ?? profile?.username ?? user.email,
      );
      if (mounted) setState(() => _myCode = code);
    } catch (e) {
      if (mounted) _showError('Couldn\'t generate code: $e');
    } finally {
      if (mounted) setState(() => _loadingCode = false);
    }
  }

  Future<void> _enterCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _EnterCodeDialog(),
    );
    if (code == null || code.isEmpty || !mounted) return;

    setState(() => _connecting = true);
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
              'Connected to ${invite.partnerDisplayName ?? "your partner"}'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception:', ''));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _exportFile() async {
    setState(() => _exporting = true);
    try {
      final snapshot =
          await context.read<CycleProvider>().exportPartnerSnapshot();
      await PartnerShareIo.shareSnapshot(snapshot);
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception:', ''));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _importFile() async {
    setState(() => _connecting = true);
    try {
      final data = await PartnerShareIo.pickSnapshot();
      if (data == null) return;
      await context.read<CycleProvider>().importPartnerSnapshot(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imported her cycle on this phone'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception:', ''));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect(String partnerUid) async {
    final profile = context.read<CycleProvider>().profile;
    if (profile == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Disconnect partner?'),
        content: Text(
            'You\'ll stop seeing their cycle updates. You can reconnect anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Disconnect', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _partnerSvc.unlinkPartner(
      viewerUid: profile.uid,
      ownerUid: partnerUid,
    );
    await context.read<CycleProvider>().updateProfile(
          profile.copyWith(removeLinkedPartnerUid: partnerUid),
        );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CycleProvider>().profile;
    final linkedUids = profile?.linkedPartnerUids ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: Text('Partner sharing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              SizedBox(height: 24),

              _SectionCard(
                title: 'Share a file (any phone)',
                subtitle:
                    'Send her cycle as a JSON file with Bluetooth, Nearby Share, WhatsApp, USB, or Files - no internet required. Your partner imports it in Partner view.',
                child: Column(
                  children: [
                    GradientButton(
                      label: 'Share my cycle file',
                      icon: Icons.ios_share_rounded,
                      loading: _exporting,
                      onPressed: _exporting ? null : _exportFile,
                    ),
                    SizedBox(height: 10),
                    GradientButton(
                      label: 'Import her cycle file',
                      gradient: AppColors.accentGradient,
                      icon: Icons.file_open_rounded,
                      loading: _connecting,
                      onPressed: _connecting ? null : _importFile,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // ----- INVITE -----
              _SectionCard(
                title: 'Same-phone PIN',
                subtitle:
                    'Only if you both use this device. A 6-digit PIN lets a partner profile here open your live cycle.',
                child: _myCode == null
                    ? Column(
                        children: [
                          SizedBox(height: 8),
                          GradientButton(
                            label: 'Generate code',
                            icon: Icons.key_rounded,
                            loading: _loadingCode,
                            onPressed: _loadingCode ? null : _generateOrRefresh,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _CodeDisplay(code: _myCode!),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _myCode!));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text('Code copied'),
                                      duration: Duration(seconds: 1),
                                    ));
                                  },
                                  icon: Icon(Icons.copy_rounded),
                                  label: Text('Copy'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _loadingCode ? null : _generateOrRefresh,
                                  icon: Icon(Icons.refresh_rounded),
                                  label: Text('Refresh'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Code expires after 24 hours',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
              SizedBox(height: 16),

              // ----- ACCEPT / CONNECTED PARTNERS -----
              _SectionCard(
                title: linkedUids.isEmpty
                    ? 'Have a partner\'s code?'
                    : 'Connected partners (${linkedUids.length})',
                subtitle: linkedUids.isEmpty
                    ? 'Enter their 6-digit code to follow their cycle.'
                    : 'Tap any partner to view their cycle.',
                child: Column(
                  children: [
                    for (final uid in linkedUids) ...[
                      _PartnerRow(
                        partnerUid: uid,
                        onDisconnect: () => _disconnect(uid),
                      ),
                      SizedBox(height: 8),
                    ],
                    SizedBox(height: 4),
                    GradientButton(
                      label: linkedUids.isEmpty
                          ? 'Enter code'
                          : 'Add another partner',
                      gradient: AppColors.accentGradient,
                      icon: Icons.input_rounded,
                      loading: _connecting,
                      onPressed: _connecting ? null : _enterCode,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              const _PrivacyNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded, color: Colors.white, size: 30),
          ),
          SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In this together',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Send a file to a partner\'s phone - Bluetooth, Nearby Share, or a cable. Nothing goes online.',
                  style:
                      TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CodeDisplay extends StatelessWidget {
  final String code;
  const _CodeDisplay({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          code.split('').join(''),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

class _EnterCodeDialog extends StatefulWidget {
  const _EnterCodeDialog();

  @override
  State<_EnterCodeDialog> createState() => _EnterCodeDialogState();
}

class _EnterCodeDialogState extends State<_EnterCodeDialog> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter partner\'s code'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 6,
        ),
        decoration: InputDecoration(
          hintText: '000000',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
          child: Text('Connect'),
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

/// Compact row for one connected partner: avatar + name + mode + disconnect.
class _PartnerRow extends StatelessWidget {
  final String partnerUid;
  final VoidCallback onDisconnect;
  const _PartnerRow({required this.partnerUid, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: CycleService(partnerUid).watchProfile(),
      builder: (ctx, snap) {
        String name = 'Partner';
        String subtitle = 'Loading...';
        IconData modeIcon = Icons.hourglass_empty_rounded;
        Color color = AppColors.textTertiary;
        bool unreachable = false;

        if (snap.connectionState != ConnectionState.waiting) {
          if (snap.hasError || snap.data == null) {
            unreachable = true;
            name = 'Partner unavailable';
            subtitle = 'No profile found on this device';
            modeIcon = Icons.error_outline_rounded;
            color = AppColors.error;
          } else {
            final profile = snap.data!;
            final mode = profile.trackingMode ?? TrackingMode.period;
            name = profile.displayName ??
                profile.username ??
                profile.email.split('@').first;
            subtitle = '${mode.displayName} mode';
            (modeIcon, color) = switch (mode) {
              TrackingMode.period => (
                  Icons.water_drop_rounded,
                  AppColors.period
                ),
              TrackingMode.conception => (Icons.spa_rounded, AppColors.fertile),
              TrackingMode.pregnancy => (
                  Icons.child_friendly_rounded,
                  AppColors.accent
                ),
            };
          }
        }

        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.18),
                child: Icon(modeIcon, color: color, size: 18),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      unreachable
                          ? 'Ask her to generate a PIN on this phone'
                          : subtitle,
                      style: TextStyle(
                        color: unreachable
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.link_off_rounded,
                    color: AppColors.error, size: 20),
                tooltip: 'Disconnect',
                onPressed: onDisconnect,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _StatusTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _StatusTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded,
            size: 16, color: AppColors.textTertiary),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'A cycle file can be resent anytime to refresh their view. Same-phone PINs last 24 hours.',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// Silence unused import warnings - these models are referenced via type only.
// ignore: unused_element
typedef _Unused = CyclePhase;
