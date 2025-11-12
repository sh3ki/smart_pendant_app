import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';

// Audio provider
final audioProvider = StateNotifierProvider<AudioNotifier, AudioState>((ref) {
  return AudioNotifier();
});

class AudioNotifier extends StateNotifier<AudioState> {
  Timer? _streamTimer;

  AudioNotifier() : super(AudioState());

  Future<void> startListening() async {
    state = AudioState(isBuffering: true);
    
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 1));
    
    state = AudioState(isListening: true, isBuffering: false);
    
    // Simulate periodic audio chunks (in real app, this would use just_audio)
    _streamTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      // In real implementation, this would receive and play audio chunks
      print('Playing audio chunk...');
    });
  }

  void stopListening() {
    _streamTimer?.cancel();
    state = AudioState(isListening: false, isBuffering: false);
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }
}
