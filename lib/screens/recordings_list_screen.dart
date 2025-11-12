import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_recording.dart';
import '../providers/audio_recording_provider.dart';

class RecordingsListScreen extends ConsumerWidget {
  const RecordingsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioRecordingProvider);
    final recordings = audioState.savedRecordings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Recordings'),
        actions: [
          if (recordings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Recording Info'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total recordings: ${recordings.length}'),
                        const SizedBox(height: 8),
                        Text(
                          'Sent: ${recordings.where((r) => r.isSent).length}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        Text(
                          'Pending: ${recordings.where((r) => !r.isSent).length}',
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: recordings.isEmpty
          ? _EmptyState()
          : ListView.builder(
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                return _RecordingListTile(recording: recording);
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No recordings yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go back and record your first audio',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingListTile extends ConsumerStatefulWidget {
  final AudioRecording recording;

  const _RecordingListTile({required this.recording});

  @override
  ConsumerState<_RecordingListTile> createState() => _RecordingListTileState();
}

class _RecordingListTileState extends ConsumerState<_RecordingListTile> {
  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController(
      text: widget.recording.title ?? 'Recording ${widget.recording.formattedDate}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Recording'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Recording Name',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref
                    .read(audioRecordingProvider.notifier)
                    .renameRecording(widget.recording.id, newTitle);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recording renamed!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('RENAME'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text(
          'Are you sure you want to delete this recording? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(audioRecordingProvider.notifier)
                  .deleteRecording(widget.recording.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recording deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioRecordingProvider);
    final isCurrentlyPlaying = audioState.isPlaying &&
        audioState.currentRecording?.id == widget.recording.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: widget.recording.isSent
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          child: Icon(
            isCurrentlyPlaying ? Icons.volume_up : Icons.mic,
            color: widget.recording.isSent ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          widget.recording.title ?? 'Recording ${widget.recording.formattedDate}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.recording.formattedDuration,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.recording.formattedDate,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (widget.recording.isSent)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Sent to Arduino',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. PLAY button (always visible)
            IconButton(
              icon: Icon(
                isCurrentlyPlaying ? Icons.stop : Icons.play_arrow,
                color: Colors.blue,
              ),
              onPressed: () {
                ref
                    .read(audioRecordingProvider.notifier)
                    .playSavedRecording(widget.recording);
              },
              tooltip: isCurrentlyPlaying ? 'Stop' : 'Play on Phone',
            ),
            
            // 2. SEND button (always visible)
            IconButton(
              icon: audioState.isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.orange),
              onPressed: audioState.isSending
                  ? null
                  : () async {
                      await ref
                          .read(audioRecordingProvider.notifier)
                          .sendRecording(recording: widget.recording);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recording sent to Arduino!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              tooltip: 'Send to Arduino',
            ),
            
            // 3. OPTIONS button (always visible - vertical 3 dots)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              tooltip: 'Options',
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(context, ref);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, ref);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
