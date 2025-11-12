import 'dart:io';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/audio_recording.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Uuid _uuid = const Uuid();
  
  Box<AudioRecording>? _recordingsBox;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  // Get Hive box for recordings (already opened in main.dart)
  Box<AudioRecording> get _box {
    if (_recordingsBox == null || !_recordingsBox!.isOpen) {
      _recordingsBox = Hive.box<AudioRecording>('audio_recordings');
    }
    return _recordingsBox!;
  }

  // Initialize is no longer needed, but kept for compatibility
  Future<void> initialize() async {
    // Box is already opened in main.dart
    _recordingsBox = Hive.box<AudioRecording>('audio_recordings');
  }

  // Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      if (!await hasPermission()) {
        print('❌ Microphone permission not granted');
        return false;
      }

      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      _currentRecordingPath = '${recordingsDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      _recordingStartTime = DateTime.now();

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav, // WAV for Arduino compatibility (raw PCM)
          bitRate: 128000, // Increased from 32k for better quality
          sampleRate: 8000, // 8kHz for Arduino compatibility
          numChannels: 1, // Mono
          autoGain: true, // Enable automatic gain control
          echoCancel: false, // Disable to preserve audio loudness
          noiseSuppress: false, // Disable to preserve audio loudness
        ),
        path: _currentRecordingPath!,
      );

      print('✅ Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('❌ Failed to start recording: $e');
      return false;
    }
  }

  // Stop recording and return the recording details
  Future<AudioRecording?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null || _recordingStartTime == null) {
        print('❌ No recording path returned');
        return null;
      }

      final duration = DateTime.now().difference(_recordingStartTime!);
      final recording = AudioRecording(
        id: _uuid.v4(),
        filePath: path,
        createdAt: _recordingStartTime!,
        durationMs: duration.inMilliseconds,
      );

      print('✅ Recording stopped: ${recording.formattedDuration}');
      _currentRecordingPath = null;
      _recordingStartTime = null;
      
      return recording;
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      return null;
    }
  }

  // Cancel recording (delete file without saving)
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          print('✅ Recording cancelled and deleted');
        }
      }
      _currentRecordingPath = null;
      _recordingStartTime = null;
    } catch (e) {
      print('❌ Failed to cancel recording: $e');
    }
  }

  // Play recording
  Future<void> playRecording(String filePath) async {
    try {
      await _player.play(DeviceFileSource(filePath));
      print('✅ Playing: $filePath');
    } catch (e) {
      print('❌ Failed to play recording: $e');
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
      print('✅ Playback stopped');
    } catch (e) {
      print('❌ Failed to stop playback: $e');
    }
  }

  // Get playback duration stream
  Stream<Duration> get positionStream => _player.onPositionChanged;

  // Get playback state stream
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;

  // Save recording to Hive
  Future<void> saveRecording(AudioRecording recording) async {
    try {
      await _box.put(recording.id, recording);
      print('✅ Recording saved: ${recording.id}');
    } catch (e) {
      print('❌ Failed to save recording: $e');
    }
  }

  // Get all saved recordings
  List<AudioRecording> getSavedRecordings() {
    return _box.values.toList().cast<AudioRecording>();
  }

  // Delete recording
  Future<void> deleteRecording(String id) async {
    try {
      final recording = _box.get(id);
      if (recording != null) {
        // Delete file
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        // Delete from Hive
        await _box.delete(id);
        print('✅ Recording deleted: $id');
      }
    } catch (e) {
      print('❌ Failed to delete recording: $e');
    }
  }

  // Rename recording
  Future<void> renameRecording(String id, String newTitle) async {
    try {
      final recording = _box.get(id);
      if (recording != null) {
        // Create updated recording with new title
        final updatedRecording = AudioRecording(
          id: recording.id,
          filePath: recording.filePath,
          durationMs: recording.durationMs,
          createdAt: recording.createdAt,
          title: newTitle,
          isSent: recording.isSent,
        );
        // Save updated recording
        await _box.put(id, updatedRecording);
        print('✅ Recording renamed: $id -> $newTitle');
      }
    } catch (e) {
      print('❌ Failed to rename recording: $e');
    }
  }

  // Amplify audio by modifying the WAV file samples
  Future<String?> getAmplifiedRecordingAsBase64(String filePath, {double gain = 8.0}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      final bytes = await file.readAsBytes();
      
      // WAV files have 44-byte header, then PCM data
      if (bytes.length < 44) {
        print('⚠️ File too small to be valid WAV');
        return base64Encode(bytes);
      }
      
      // Copy the bytes to modify them
      final amplifiedBytes = List<int>.from(bytes);
      
      // Process 16-bit PCM samples (skip 44-byte header)
      for (int i = 44; i < bytes.length - 1; i += 2) {
        // Read 16-bit signed sample (little-endian)
        int sample = bytes[i] | (bytes[i + 1] << 8);
        // Convert to signed 16-bit
        if (sample > 32767) sample -= 65536;
        
        // Amplify the sample
        int amplified = (sample * gain).round();
        
        // Clip to prevent distortion
        if (amplified > 32767) amplified = 32767;
        if (amplified < -32768) amplified = -32768;
        
        // Convert back to unsigned for storage
        if (amplified < 0) amplified += 65536;
        
        // Write back (little-endian)
        amplifiedBytes[i] = amplified & 0xFF;
        amplifiedBytes[i + 1] = (amplified >> 8) & 0xFF;
      }
      
      print('✅ Audio amplified with gain: ${gain}x');
      return base64Encode(amplifiedBytes);
    } catch (e) {
      print('❌ Failed to amplify audio: $e');
      return null;
    }
  }

  // Get recording file as base64 (for sending to server)
  Future<String?> getRecordingAsBase64(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
      return null;
    } catch (e) {
      print('❌ Failed to encode recording: $e');
      return null;
    }
  }

  // Mark recording as sent
  Future<void> markAsSent(String id) async {
    try {
      final recording = _box.get(id);
      if (recording != null) {
        await _box.put(id, recording.copyWith(isSent: true));
        print('✅ Recording marked as sent: $id');
      }
    } catch (e) {
      print('❌ Failed to mark as sent: $e');
    }
  }

  // Get recording duration in real-time while recording
  Duration? getRecordingDuration() {
    if (_recordingStartTime != null) {
      return DateTime.now().difference(_recordingStartTime!);
    }
    return null;
  }

  // Check if currently recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // Dispose resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
