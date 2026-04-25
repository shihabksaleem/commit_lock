import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/session_model.dart';

class ResultScreen extends StatelessWidget {
  final SessionModel session;
  final bool fromHistory;

  const ResultScreen({super.key, required this.session, this.fromHistory = false});

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.status == SessionStatus.completed;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 80,
                color: isCompleted ? colorScheme.tertiary : Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                isCompleted ? 'Commitment Kept!' : 'Commitment Broken',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isCompleted
                    ? 'Great job staying focused on your ${session.category} habit!'
                    : 'You broke your focus on ${session.category}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildInfoCard(context),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to Dashboard'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _infoRow('Category', session.category),
            const Divider(),
            _infoRow('Planned', '${session.plannedDurationMinutes}m'),
            const Divider(),
            _infoRow('Actual', '${(session.actualDurationSeconds ?? 0) ~/ 60}m'),
            const Divider(),
            _infoRow('Penalty', '\$${session.penaltyAmount.toInt()}'),
            const Divider(),
            _infoRow('Level', session.restrictionLevel),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
