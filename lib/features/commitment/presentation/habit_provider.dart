import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

final habitProvider = StateNotifierProvider<HabitNotifier, List<String>>((ref) {
  return HabitNotifier();
});

class HabitNotifier extends StateNotifier<List<String>> {
  HabitNotifier() : super([]) {
    _loadHabits();
  }

  late Box<String> _habitsBox;

  void _loadHabits() {
    _habitsBox = Hive.box<String>(AppConstants.habitsBox);
    final storedHabits = _habitsBox.values.toList();
    
    if (storedHabits.isEmpty) {
      // Seed with default categories excluding 'Custom'
      final defaults = AppConstants.categories.where((c) => c != 'Custom').toList();
      for (var habit in defaults) {
        _habitsBox.add(habit);
      }
      state = [...defaults, 'Custom'];
    } else {
      state = [...storedHabits, 'Custom'];
    }
  }

  Future<void> addHabit(String habit) async {
    if (!state.contains(habit)) {
      await _habitsBox.add(habit);
      // Keep 'Custom' at the end
      final current = [...state];
      current.remove('Custom');
      current.add(habit);
      current.add('Custom');
      state = current;
    }
  }
}
