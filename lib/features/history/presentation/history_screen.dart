import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../commitment/domain/session_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = 'All';
  String _sort = 'Newest';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<SessionModel>(AppConstants.sessionsBox).listenable(),
        builder: (context, Box<SessionModel> box, _) {
          var sessions = box.values.toList();

          // Filter
          if (_filter == 'Completed') {
            sessions = sessions.where((s) => s.status == SessionStatus.completed).toList();
          } else if (_filter == 'Broken') {
            sessions = sessions.where((s) => s.status == SessionStatus.broken).toList();
          }

          // Sort
          if (_sort == 'Newest') {
            sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
          } else {
            sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
          }

          return Column(
            children: [
              _buildFilters(),
              _buildSummary(context, sessions),
              Expanded(
                child: sessions.isEmpty
                    ? const Center(child: Text('No sessions yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return _buildSessionItem(context, session);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _filterChip('All'),
          _filterChip('Completed'),
          _filterChip('Broken'),
          const SizedBox(width: 8),
          const VerticalDivider(),
          const SizedBox(width: 8),
          _sortChip('Newest'),
          _sortChip('Oldest'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == label,
        onSelected: (val) => setState(() => _filter = label),
      ),
    );
  }

  Widget _sortChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _sort == label,
        onSelected: (val) => setState(() => _sort = label),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, List<SessionModel> sessions) {
    final completed = sessions.where((s) => s.status == SessionStatus.completed).length;
    final total = sessions.length;
    final rate = total == 0 ? 0 : (completed / total * 100).toInt();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total', '$total'),
          _summaryItem('Success', '$rate%'),
          _summaryItem('Completed', '$completed'),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildSessionItem(BuildContext context, SessionModel session) {
    final isCompleted = session.status == SessionStatus.completed;
    final colorScheme = Theme.of(context).colorScheme;

    // Format actual duration
    final actualSecondsTotal = session.actualDurationSeconds ?? 0;
    final actualMinutes = actualSecondsTotal ~/ 60;
    final actualSeconds = actualSecondsTotal % 60;
    final actualStr = "${actualMinutes}:${actualSeconds.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => context.push('/result', extra: {'session': session, 'fromHistory': true}),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (isCompleted ? colorScheme.tertiary : Colors.redAccent).withOpacity(0.2),
          child: Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCompleted ? colorScheme.tertiary : Colors.redAccent,
          ),
        ),
        title: Row(
          children: [
            Text(session.category, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${session.plannedDurationMinutes}m Goal', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Time spent: $actualStr', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMM dd, hh:mm a').format(session.startTime),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isCompleted ? 'Completed' : 'Broken',
              style: TextStyle(
                color: isCompleted ? colorScheme.tertiary : Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '\$${session.penaltyAmount.toInt()}',
              style: TextStyle(
                color: isCompleted ? Colors.grey : Colors.redAccent,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
