import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/audio_recording.dart';
import '../services/audio_recording_service.dart';
import '../services/api_client.dart';

// Service provider
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  return AudioRecordingService();
});

// State class
class AudioRecordingState {
  final bool isRecording;
  final bool isPlaying;
  final bool isSending;
  final AudioRecording? currentRecording;
  final List<AudioRecording> savedRecordings;
  final Duration recordingDuration;
  final Duration playbackPosition;
  final String? error;
  final bool hasPermission;

  const AudioRecordingState({
    this.isRecording = false,
    this.isPlaying = false,
    this.isSending = false,
    this.currentRecording,
    this.savedRecordings = const [],
    this.recordingDuration = Duration.zero,
    this.playbackPosition = Duration.zero,
    this.error,
    this.hasPermission = false,
  });

  AudioRecordingState copyWith({
    bool? isRecording,
    bool? isPlaying,
    bool? isSending,
    AudioRecording? currentRecording,
    bool clearCurrentRecording = false, // Flag to explicitly clear currentRecording
    List<AudioRecording>? savedRecordings,
    Duration? recordingDuration,
    Duration? playbackPosition,
    String? error,
    bool clearError = false, // Flag to explicitly clear error
    bool? hasPermission,
  }) {
    return AudioRecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPlaying: isPlaying ?? this.isPlaying,
      isSending: isSending ?? this.isSending,
      currentRecording: clearCurrentRecording ? null : (currentRecording ?? this.currentRecording),
      savedRecordings: savedRecordings ?? this.savedRecordings,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      playbackPosition: playbackPosition ?? this.playbackPosition,
      error: clearError ? null : error,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

// Notifier
class AudioRecordingNotifier extends StateNotifier<AudioRecordingState> {
  final AudioRecordingService _service;
  final ApiClient _apiClient;
  Timer? _durationTimer;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  AudioRecordingNotifier(this._service, this._apiClient) : super(const AudioRecordingState()) {
    _init();
  }

  Future<void> _init() async {
    // Initialize service (cache Hive box reference)
    await _service.initialize();
    
    final hasPermission = await _service.hasPermission();
    state = state.copyWith(hasPermission: hasPermission);
    await loadSavedRecordings();
    
    // Listen to playback position
    _positionSubscription = _service.positionStream.listen((position) {
      state = state.copyWith(playbackPosition: position);
    });

    // Listen to player state
    _playerStateSubscription = _service.playerStateStream.listen((playerState) {
      if (playerState == PlayerState.completed || playerState == PlayerState.stopped) {
        state = state.copyWith(isPlaying: false, playbackPosition: Duration.zero);
      }
    });
  }

  // Start recording
  Future<void> startRecording() async {
    try {
      state = state.copyWith(error: null);
      
      if (!state.hasPermission) {
        state = state.copyWith(error: 'Microphone permission required');
        return;
      }

      final success = await _service.startRecording();
      if (success) {
        state = state.copyWith(
          isRecording: true,
          clearCurrentRecording: true, // Use flag to explicitly set to null
          recordingDuration: Duration.zero,
        );
        
        // Start duration timer with 5-second auto-stop
        _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          final duration = _service.getRecordingDuration();
          if (duration != null) {
            state = state.copyWith(recordingDuration: duration);
            
            // Auto-stop at 5 seconds
            if (duration.inSeconds >= 5) {
              stopRecording();
            }
          }
        });
      } else {
        state = state.copyWith(error: 'Failed to start recording');
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Stop recording
  Future<void> stopRecording() async {
    try {
      _durationTimer?.cancel();
      final recording = await _service.stopRecording();
      
      if (recording != null) {
        state = state.copyWith(
          isRecording: false,
          currentRecording: recording,
          recordingDuration: Duration.zero,
        );
      } else {
        state = state.copyWith(
          isRecording: false,
          error: 'Failed to save recording',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: 'Error: $e',
      );
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      _durationTimer?.cancel();
      await _service.cancelRecording();
      state = state.copyWith(
        isRecording: false,
        clearCurrentRecording: true, // Use flag to explicitly set to null
        recordingDuration: Duration.zero,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Play current recording
  Future<void> playCurrentRecording() async {
    if (state.currentRecording == null) return;
    
    try {
      if (state.isPlaying) {
        await _service.stopPlayback();
        state = state.copyWith(isPlaying: false, playbackPosition: Duration.zero);
      } else {
        await _service.playRecording(state.currentRecording!.filePath);
        state = state.copyWith(isPlaying: true);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Play saved recording
  Future<void> playSavedRecording(AudioRecording recording) async {
    try {
      if (state.isPlaying) {
        await _service.stopPlayback();
        state = state.copyWith(isPlaying: false, playbackPosition: Duration.zero);
      } else {
        await _service.playRecording(recording.filePath);
        state = state.copyWith(isPlaying: true, currentRecording: recording);
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    try {
      await _service.stopPlayback();
      state = state.copyWith(isPlaying: false, playbackPosition: Duration.zero);
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Save recording
  Future<void> saveRecording() async {
    if (state.currentRecording == null) return;
    
    try {
      await _service.saveRecording(state.currentRecording!);
      await loadSavedRecordings();
      state = state.copyWith(clearCurrentRecording: true); // Use flag to explicitly set to null
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Send recording to server/Arduino
  Future<void> sendRecording({AudioRecording? recording}) async {
    final recordingToSend = recording ?? state.currentRecording;
    if (recordingToSend == null) return;

    try {
      state = state.copyWith(isSending: true, error: null);

      // Get recording as base64 WITH AMPLIFICATION (3x gain to boost audio without distortion)
      final base64Audio = await _service.getAmplifiedRecordingAsBase64(
        recordingToSend.filePath,
        gain: 3.0, // 3x amplification - balanced between volume and clarity
      );
      if (base64Audio == null) {
        state = state.copyWith(
          isSending: false,
          error: 'Failed to encode audio',
        );
        return;
      }

      // Send to server
      await _apiClient.sendAudio(base64Audio);
      
      // Mark as sent
      await _service.markAsSent(recordingToSend.id);
      await loadSavedRecordings();

      state = state.copyWith(
        isSending: false,
        clearCurrentRecording: true, // Use flag to explicitly set to null
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: 'Failed to send: $e',
      );
    }
  }

  // Load saved recordings
  Future<void> loadSavedRecordings() async {
    try {
      final recordings = _service.getSavedRecordings();
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
      state = state.copyWith(savedRecordings: recordings);
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Delete recording
  Future<void> deleteRecording(String id) async {
    try {
      await _service.deleteRecording(id);
      await loadSavedRecordings();
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Rename recording
  Future<void> renameRecording(String id, String newTitle) async {
    try {
      await _service.renameRecording(id, newTitle);
      await loadSavedRecordings();
    } catch (e) {
      state = state.copyWith(error: 'Error: $e');
    }
  }

  // Clear current recording (for cancel button)
  Future<void> clearCurrentRecording() async {
    if (state.currentRecording != null) {
      // Delete the file associated with current recording
      try {
        final file = File(state.currentRecording!.filePath);
        if (await file.exists()) {
          await file.delete();
          print('✅ Current recording file deleted: ${state.currentRecording!.filePath}');
        }
      } catch (e) {
        print('❌ Failed to delete current recording file: $e');
      }
    }
    state = state.copyWith(clearCurrentRecording: true); // Use flag to explicitly set to null
    print('✅ Current recording cleared from state');
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true); // Use flag to explicitly clear error
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}

// Provider
final audioRecordingProvider = StateNotifierProvider<AudioRecordingNotifier, AudioRecordingState>((ref) {
  final service = ref.watch(audioRecordingServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AudioRecordingNotifier(service, apiClient);
});
