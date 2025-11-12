import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_recording_provider.dart';
import 'recordings_list_screen.dart';

class AudioScreen extends ConsumerWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioRecordingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recording'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${audioState.savedRecordings.length}'),
              isLabelVisible: audioState.savedRecordings.isNotEmpty,
              child: const Icon(Icons.list),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecordingsListScreen(),
                ),
              );
            },
            tooltip: 'View Recordings',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Recording visualizer
              Expanded(
                child: Center(
                  child: _RecordingVisualizer(
                    isRecording: audioState.isRecording,
                    isPlaying: audioState.isPlaying,
                    duration: audioState.isRecording
                        ? audioState.recordingDuration
                        : (audioState.currentRecording?.duration ?? Duration.zero),
                    position: audioState.playbackPosition,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Recording controls
              if (!audioState.hasPermission)
                _PermissionWarning()
              else if (audioState.currentRecording == null)
                _RecordButton(isRecording: audioState.isRecording)
              else
                _RecordingControls(),
              
              const SizedBox(height: 16),
              
              // Error display
              if (audioState.error != null)
                _ErrorDisplay(error: audioState.error!),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingVisualizer extends StatelessWidget {
  final bool isRecording;
  final bool isPlaying;
  final Duration duration;
  final Duration position;

  const _RecordingVisualizer({
    required this.isRecording,
    required this.isPlaying,
    required this.duration,
    required this.position,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated circle
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording
                ? Colors.red.withOpacity(0.1)
                : isPlaying
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            border: Border.all(
              color: isRecording
                  ? Colors.red
                  : isPlaying
                      ? Colors.blue
                      : Colors.grey,
              width: 3,
            ),
          ),
          child: Center(
            child: Icon(
              isRecording
                  ? Icons.mic
                  : isPlaying
                      ? Icons.play_arrow
                      : Icons.mic_none,
              size: 80,
              color: isRecording
                  ? Colors.red
                  : isPlaying
                      ? Colors.blue
                      : Colors.grey,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Duration display
        Text(
          _formatDuration(isPlaying ? position : duration),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Status text
        Text(
          isRecording
              ? 'Recording...'
              : isPlaying
                  ? 'Playing...'
                  : duration > Duration.zero
                      ? 'Ready to replay'
                      : 'Tap RECORD to start',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _PermissionWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 48),
          const SizedBox(height: 8),
          const Text(
            'Microphone Permission Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please grant microphone permission to record audio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _RecordButton extends ConsumerWidget {
  final bool isRecording;

  const _RecordButton({required this.isRecording});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 64,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isRecording ? Colors.red : Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record, size: 28),
        label: Text(
          isRecording ? 'STOP' : 'RECORD',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        onPressed: () {
          if (isRecording) {
            ref.read(audioRecordingProvider.notifier).stopRecording();
          } else {
            ref.read(audioRecordingProvider.notifier).startRecording();
          }
        },
      ),
    );
  }
}

class _RecordingControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioRecordingProvider);
    final isSending = audioState.isSending;

    return Column(
      children: [
        // Replay button
        SizedBox(
          height: 64,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: audioState.isPlaying ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            icon: Icon(
              audioState.isPlaying ? Icons.stop : Icons.play_arrow,
              size: 28,
            ),
            label: Text(
              audioState.isPlaying ? 'STOP PLAYBACK' : 'REPLAY',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            onPressed: () {
              ref.read(audioRecordingProvider.notifier).playCurrentRecording();
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Action buttons row
        Row(
          children: [
            // Cancel button - Reset to default RECORD screen
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.close),
                label: const Text('CANCEL'),
                onPressed: isSending
                    ? null
                    : () async {
                        // Stop playback if playing
                        await ref.read(audioRecordingProvider.notifier).stopPlayback();
                        
                        // Clear current recording (deletes file and resets state)
                        await ref.read(audioRecordingProvider.notifier).clearCurrentRecording();
                      },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Save button - Save to list and reset to RECORD screen (DON'T send to Arduino)
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.save),
                label: const Text('SAVE'),
                onPressed: isSending
                    ? null
                    : () async {
                        // Stop any playback first
                        await ref.read(audioRecordingProvider.notifier).stopPlayback();
                        // Save the recording (adds to saved recordings list)
                        await ref.read(audioRecordingProvider.notifier).saveRecording();
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Recording saved!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 1),
                            ),
                          );
                          
                          // Navigate to recordings list screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecordingsListScreen(),
                            ),
                          );
                        }
                        // Screen automatically resets to RECORD button (saveRecording sets currentRecording to null)
                      },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Send button - Save to list, send to Arduino, navigate to recordings screen, reset audio screen
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(isSending ? 'SENDING...' : 'SEND'),
                onPressed: isSending
                    ? null
                    : () async {
                        // Stop any playback first
                        await ref.read(audioRecordingProvider.notifier).stopPlayback();
                        
                        // Save the recording first (so it appears in the list)
                        await ref.read(audioRecordingProvider.notifier).saveRecording();
                        
                        // Get the saved recording from the list (it's the newest one)
                        final savedRecordings = ref.read(audioRecordingProvider).savedRecordings;
                        if (savedRecordings.isNotEmpty) {
                          final recordingToSend = savedRecordings.first; // Newest recording
                          
                          // Send the saved recording to Arduino
                          await ref.read(audioRecordingProvider.notifier).sendRecording(recording: recordingToSend);
                        }
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Recording sent to Arduino!'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          
                          // Navigate to recordings list screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecordingsListScreen(),
                            ),
                          );
                        }
                        // Audio screen will reset to RECORD button when we come back (currentRecording is null)
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorDisplay extends ConsumerWidget {
  final String error;

  const _ErrorDisplay({required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              ref.read(audioRecordingProvider.notifier).clearError();
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

