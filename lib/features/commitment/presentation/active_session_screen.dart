import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/session_model.dart';
import '../../../core/utils/ui_utils.dart';
import 'session_provider.dart';

class ActiveSessionScreen extends ConsumerStatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen> {
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    // Update UI every second
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _handleExit(SessionModel session) async {
    final level = session.restrictionLevel;

    if (level == 'Normal') {
      final confirm = await _showConfirmDialog('Exit Session?', 'Are you sure you want to break your commitment?');
      if (confirm) _breakSession(session);
    } else if (level == 'Strict') {
      final confirm1 = await _showConfirmDialog(
        'First Confirmation',
        'Are you really sure? This will break your streak.',
      );
      if (confirm1) {
        bool canConfirm = false;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              Timer(const Duration(seconds: 5), () => setState(() => canConfirm = true));
              return AlertDialog(
                title: const Text('Strict Confirmation'),
                content: const Text('Please wait 5 seconds before final confirmation...'),
                actions: [
                  TextButton(
                    onPressed: canConfirm ? () => Navigator.pop(context, true) : null,
                    child: Text(canConfirm ? 'YES, BREAK IT' : 'WAIT...'),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                ],
              );
            },
          ),
        ).then((val) {
          if (val == true && mounted) _breakSession(session);
        });
      }
    } else if (level == 'Extreme') {
      final controller = TextEditingController();
      const phrase = 'I am breaking my commitment';
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('EXTREME EXIT'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('To exit, you must type the following exactly:'),
              const SizedBox(height: 8),
              const Text(
                '"$phrase"',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (controller.text == phrase) {
                  Navigator.pop(context, true);
                } else {
                  UIUtils.showSnackBar(context, 'Incorrect phrase!', isError: true);
                }
              },
              child: const Text('CONFIRM BREAK', style: TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ],
        ),
      ).then((val) {
        if (val == true && mounted) _breakSession(session);
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('YES')),
            ],
          ),
        ) ??
        false;
  }

  void _breakSession(SessionModel session) {
    ref.read(sessionProvider.notifier).breakSession(session);
    context.go('/result', extra: {'session': session, 'fromHistory': false});
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final endTime = session.startTime.add(Duration(minutes: session.plannedDurationMinutes));
    final remaining = endTime.difference(now);
    final totalSeconds = session.plannedDurationMinutes * 60;
    final progress = (1 - (remaining.inSeconds / totalSeconds)).clamp(0.0, 1.0);

    final textColor = isDark ? Colors.white : AppTheme.primaryColor;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          session.category,
          style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge('${session.restrictionLevel} Mode', colorScheme),
                const SizedBox(width: 8),
                _buildBadge('\$${session.penaltyAmount.toInt()} Penalty', colorScheme, isAlert: true),
              ],
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(isDark ? colorScheme.tertiary : colorScheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(remaining),
                      style: TextStyle(color: textColor, fontSize: 64, fontWeight: FontWeight.bold),
                    ),
                    Text('REMAINING', style: TextStyle(color: subTextColor, letterSpacing: 2)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '"The only bad workout is the one that didn\'t happen."',
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor, fontStyle: FontStyle.italic, fontSize: 16),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TextButton(
                onPressed: () => _handleExit(session),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Break Commitment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, ColorScheme colorScheme, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isAlert ? Colors.redAccent.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAlert ? Colors.redAccent.withOpacity(0.3) : colorScheme.primary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isAlert ? Colors.redAccent : colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
