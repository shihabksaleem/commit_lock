import 'dart:async';

import 'package:commit_lock/core/utils/streak_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../commitment/domain/session_model.dart';
import '../domain/user_stats_model.dart';
import '../../commitment/presentation/session_provider.dart';
import '../../../core/utils/ui_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(sessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.history_outlined), onPressed: () => context.push('/history')),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<UserStatsModel>(AppConstants.userStatsBox).listenable(),
        builder: (context, Box<UserStatsModel> box, _) {
          final stats = box.get('current_stats') ?? UserStatsModel();
          final sessions = Hive.box<SessionModel>(AppConstants.sessionsBox).values.toList();
          final totalPenalty = sessions
              .where((s) => s.status == SessionStatus.broken)
              .fold(0.0, (sum, s) => sum + s.penaltyAmount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String?>(
                  future: SharedPreferences.getInstance().then((p) => p.getString(AppConstants.userNameKey)),
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? 'Achiever';
                    return Text('Hello, $name! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
                  },
                ),
                const SizedBox(height: 24),
                _buildStreakCard(context, stats),
                const SizedBox(height: 12),
                _buildPenaltyInfo(context, totalPenalty),
                if (activeSession != null) ...[
                  const SizedBox(height: 24),
                  _buildActiveSessionCard(context, activeSession),
                ],
                const SizedBox(height: 20),
                _buildTodayStats(context, stats),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (activeSession != null) {
            UIUtils.showSnackBar(context, 'A session is already running! Finish or break it first.');
          } else {
            context.push('/new-commitment');
          }
        },
        label: const Text('New Commitment'),
        icon: const Icon(Icons.add),
        backgroundColor: activeSession != null ? Colors.grey : colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, UserStatsModel stats) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showStreakBreakdown(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Streak', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text(
                    '${stats.currentStreak} Days',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Best', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  '${stats.longestStreak}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.info_outline, color: Colors.white70, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakBreakdown(BuildContext context) {
    final sessionsBox = Hive.box<SessionModel>(AppConstants.sessionsBox);
    final sessions = sessionsBox.values.toList();
    final dailyStats = StreakCalculator.getDailyStats(sessions);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Streak Strategy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Text('Consecutive days with 80% or higher success rate.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dailyStats.length > 7 ? 7 : dailyStats.length,
                itemBuilder: (context, index) {
                  final day = dailyStats[index];
                  final isSuccessful = day.successRate >= 0.8;
                  final dateLabel = DateFormat('EEEE, MMM d').format(day.date);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSuccessful ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSuccessful ? Icons.check : Icons.close,
                            color: isSuccessful ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${day.completed}/${day.total} sessions completed',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(day.successRate * 100).toInt()}%',
                          style: TextStyle(
                            color: isSuccessful ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (dailyStats.isEmpty)
              const Center(
                child: Padding(padding: EdgeInsets.all(32.0), child: Text('No session data yet')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats(BuildContext context, UserStatsModel stats) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<SessionModel>(AppConstants.sessionsBox).listenable(),
      builder: (context, Box<SessionModel> box, _) {
        final now = DateTime.now();
        final todaySessions = box.values.where((s) {
          return s.startTime.year == now.year && s.startTime.month == now.month && s.startTime.day == now.day;
        }).toList();

        final completedMinutes = todaySessions
            .where((s) => s.status == SessionStatus.completed)
            .fold(0, (sum, s) => sum + s.plannedDurationMinutes);

        final totalPlannedMinutes = todaySessions.fold(0, (sum, s) => sum + s.plannedDurationMinutes);

        final completedCount = todaySessions.where((s) => s.status == SessionStatus.completed).length;
        final totalCount = todaySessions.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Today\'s Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Row(
              children: [
                Expanded(
                  child: _statItem(
                    context,
                    'Total Time',
                    '${completedMinutes}m / ${totalPlannedMinutes}m',
                    Icons.timer_outlined,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _statItem(
                    context,
                    'Completed',
                    '$completedCount / $totalCount',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
              ],
            ),
            if (todaySessions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Today\'s Commitments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todaySessions.length,
                itemBuilder: (context, index) {
                  final session = todaySessions[todaySessions.length - 1 - index];
                  return _buildTodaySessionItem(context, session);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTodaySessionItem(BuildContext context, SessionModel session) {
    final isCompleted = session.status == SessionStatus.completed;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => context.push('/result', extra: {'session': session, 'fromHistory': true}),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isCompleted ? Colors.green : Colors.red).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.close,
                color: isCompleted ? Colors.green : Colors.red,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${session.plannedDurationMinutes}m • ${isCompleted ? "Completed" : "Broken"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('hh:mm a').format(session.startTime),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenaltyInfo(BuildContext context, double totalPenalty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          const Text(
            'Total Penalty:',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${totalPenalty.toInt()}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.red, size: 20),
            onPressed: () => _showPenaltyGuidance(context),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _showPenaltyGuidance(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Penalty Guidance'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your broken commitments have consequences. Here is how to handle your penalty funds:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('• You must invest the penalty amount for today\'s broken commitments into a long-term asset.'),
            SizedBox(height: 8),
            Text('• You should not touch or spend this amount for the remainder of this month.'),
            SizedBox(height: 8),
            Text('• Use this as a lesson to stay committed tomorrow!'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('I UNDERSTAND'))],
      ),
    );
  }

  Widget _buildActiveSessionCard(BuildContext context, SessionModel session) {
    return _ActiveSessionTimerCard(session: session);
  }
}

class _ActiveSessionTimerCard extends StatefulWidget {
  final SessionModel session;
  const _ActiveSessionTimerCard({required this.session});

  @override
  State<_ActiveSessionTimerCard> createState() => _ActiveSessionTimerCardState();
}

class _ActiveSessionTimerCardState extends State<_ActiveSessionTimerCard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final endTime = widget.session.startTime.add(Duration(minutes: widget.session.plannedDurationMinutes));
    final remaining = endTime.difference(now);

    return InkWell(
      onTap: () => context.push('/active-session'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Highlight with a subtle gradient or primary tint
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A3A32), const Color(0xFF0D1F1D)]
                : [colorScheme.primary.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary, width: 2),
          boxShadow: [
            BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: (1 - (remaining.inSeconds / (widget.session.plannedDurationMinutes * 60))).clamp(0.0, 1.0),
                    strokeWidth: 3,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
                Icon(Icons.timer_outlined, color: colorScheme.primary, size: 24),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Session',
                    style: TextStyle(
                      color: isDark ? colorScheme.tertiary : colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    widget.session.category,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(remaining),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Text('remaining', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: colorScheme.primary.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }
}

Widget _statItem(BuildContext context, String label, String value, IconData icon, Color color) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    ),
  );
}
