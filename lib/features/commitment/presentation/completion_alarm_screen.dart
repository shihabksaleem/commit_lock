import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../settings/presentation/settings_provider.dart';
import '../domain/session_model.dart';

class CompletionAlarmScreen extends ConsumerStatefulWidget {
  final SessionModel session;

  const CompletionAlarmScreen({super.key, required this.session});

  @override
  ConsumerState<CompletionAlarmScreen> createState() => _CompletionAlarmScreenState();
}

class _CompletionAlarmScreenState extends ConsumerState<CompletionAlarmScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically start the native alarm sound when this screen is launched
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    final settings = ref.read(settingsProvider);
    if (settings.soundEnabled) {
      FlutterRingtonePlayer().play(
        fromAsset: "assets/audio/alarm.mp3", // fallback
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    }
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  void _stopAlarm() {
    FlutterRingtonePlayer().stop();
    context.go('/result', extra: {'session': widget.session, 'fromHistory': false});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50), // Vibrant Success Green
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 120, color: Colors.white)
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(duration: 800.ms, curve: Curves.easeInOut)
                    .then()
                    .scale(duration: 800.ms, curve: Curves.easeInOut),
                const SizedBox(height: 32),
                const Text(
                  'COMMITMENT KEPT!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                const SizedBox(height: 12),
                Text(
                  widget.session.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 60),
                const Text(
                  'Well done! You stayed focused.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child:
                ElevatedButton(
                      onPressed: _stopAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 10,
                      ),
                      child: const Text('STOP ALARM', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
          ),
        ],
      ),
    );
  }
}
