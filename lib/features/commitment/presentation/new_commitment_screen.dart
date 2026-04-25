import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/ui_utils.dart';
import 'session_provider.dart';
import 'habit_provider.dart';

class NewCommitmentScreen extends ConsumerStatefulWidget {
  const NewCommitmentScreen({super.key});

  @override
  ConsumerState<NewCommitmentScreen> createState() => _NewCommitmentScreenState();
}

class _NewCommitmentScreenState extends ConsumerState<NewCommitmentScreen> {
  String? _selectedCategory;
  int _selectedDuration = 25;
  double _selectedPenalty = 5.0;
  String _selectedRestriction = 'Normal';

  bool _isCustomDuration = false;
  String _durationUnit = 'Minutes';
  final _customHabitController = TextEditingController();
  final _customDurationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habits = ref.read(habitProvider);
      if (habits.isNotEmpty && _selectedCategory == null) {
        setState(() {
          _selectedCategory = habits.first;
        });
      }
    });
  }

  @override
  void dispose() {
    _customHabitController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitProvider);
    final activeSession = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Commitment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (activeSession != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A session is already running. You must finish or break it before starting a new one.',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            _buildSection('Habit Category', _buildCategoryDropdown(habits)),
            if (_selectedCategory == 'Custom') ...[const SizedBox(height: 16), _buildCustomHabitField()],
            const SizedBox(height: 32),
            _buildSection('Duration', _buildDurationChips()),
            if (_isCustomDuration) ...[const SizedBox(height: 16), _buildCustomDurationField()],
            const SizedBox(height: 32),
            _buildSection('Penalty Amount (\$)', _buildPenaltyChips()),
            const SizedBox(height: 32),
            _buildSection('Restriction Level', _buildRestrictionList()),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: activeSession != null ? null : () => _startCommitment(),
              style: activeSession != null ? ElevatedButton.styleFrom(backgroundColor: Colors.grey) : null,
              child: const Text('Start Commitment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _startCommitment() async {
    String finalHabit = _selectedCategory ?? '';
    if (_selectedCategory == 'Custom') {
      if (_customHabitController.text.isEmpty) {
        UIUtils.showSnackBar(context, 'Please enter a habit name', isError: true);
        return;
      }
      finalHabit = _customHabitController.text;
    } else if (finalHabit.isEmpty) {
      UIUtils.showSnackBar(context, 'Please select a habit', isError: true);
      return;
    }

    int finalDuration = _selectedDuration;
    if (_isCustomDuration) {
      if (_customDurationController.text.isEmpty) {
        UIUtils.showSnackBar(context, 'Please enter duration', isError: true);
        return;
      }
      final durationVal = int.tryParse(_customDurationController.text);
      if (durationVal == null || durationVal <= 0) {
        UIUtils.showSnackBar(context, 'Enter a valid duration', isError: true);
        return;
      }
      finalDuration = _durationUnit == 'Hours' ? durationVal * 60 : durationVal;
    }

    await ref
        .read(sessionProvider.notifier)
        .startSession(
          category: finalHabit,
          durationMinutes: finalDuration,
          penaltyAmount: _selectedPenalty,
          restrictionLevel: _selectedRestriction,
        );

    if (mounted) {
      context.pushReplacement('/active-session');
    }
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildCategoryDropdown(List<String> habits) {
    final items = habits.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList();
    items.add(const DropdownMenuItem(value: 'Custom', child: Text('Custom Habit +')));

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items,
      onChanged: (val) => setState(() => _selectedCategory = val),
      hint: const Text('Select Habit'),
    );
  }

  Widget _buildCustomHabitField() {
    return TextField(
      controller: _customHabitController,
      decoration: InputDecoration(
        hintText: 'Enter habit name...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDurationChips() {
    final durations = [15, 25, 45, 60, 90];
    return Wrap(
      spacing: 12,
      children: [
        ...durations.map((d) {
          final isSelected = _selectedDuration == d && !_isCustomDuration;
          return ChoiceChip(
            label: Text('${d}m'),
            selected: isSelected,
            onSelected: (val) {
              if (val)
                setState(() {
                  _selectedDuration = d;
                  _isCustomDuration = false;
                });
            },
          );
        }),
        ChoiceChip(
          label: const Text('Custom'),
          selected: _isCustomDuration,
          onSelected: (val) {
            if (val) setState(() => _isCustomDuration = true);
          },
        ),
      ],
    );
  }

  Widget _buildCustomDurationField() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _customDurationController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter amount',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _durationUnit,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            items: ['Minutes', 'Hours'].map((unit) {
              return DropdownMenuItem(value: unit, child: Text(unit));
            }).toList(),
            onChanged: (val) => setState(() => _durationUnit = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildPenaltyChips() {
    final penalties = [5.0, 10.0, 25.0, 50.0];
    return Wrap(
      spacing: 12,
      children: penalties.map((p) {
        return ChoiceChip(
          label: Text('\$${p.toInt()}'),
          selected: _selectedPenalty == p,
          onSelected: (val) {
            if (val) setState(() => _selectedPenalty = p);
          },
        );
      }).toList(),
    );
  }

  Widget _buildRestrictionList() {
    final levels = ['Normal', 'Strict', 'Extreme'];
    return Column(
      children: levels.map((l) {
        final isSelected = _selectedRestriction == l;
        return RadioListTile<String>(
          title: Text(l),
          subtitle: Text(_getRestrictionDesc(l)),
          value: l,
          groupValue: _selectedRestriction,
          onChanged: (val) => setState(() => _selectedRestriction = val!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          selected: isSelected,
          tileColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : null,
        );
      }).toList(),
    );
  }

  String _getRestrictionDesc(String level) {
    switch (level) {
      case 'Normal':
        return 'Single confirmation to exit.';
      case 'Strict':
        return '2-step confirmation with 5s delay.';
      case 'Extreme':
        return 'Type a specific phrase to exit.';
      default:
        return '';
    }
  }
}
