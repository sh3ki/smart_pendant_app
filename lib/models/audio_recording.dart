import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'audio_recording.g.dart';

@HiveType(typeId: 3)
class AudioRecording extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String filePath;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final int durationMs;

  @HiveField(4)
  final String? title;

  @HiveField(5)
  final bool isSent;

  const AudioRecording({
    required this.id,
    required this.filePath,
    required this.createdAt,
    required this.durationMs,
    this.title,
    this.isSent = false,
  });

  String get formattedDuration {
    final seconds = durationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Duration get duration => Duration(milliseconds: durationMs);

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  AudioRecording copyWith({
    String? id,
    String? filePath,
    DateTime? createdAt,
    int? durationMs,
    String? title,
    bool? isSent,
  }) {
    return AudioRecording(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
      title: title ?? this.title,
      isSent: isSent ?? this.isSent,
    );
  }

  @override
  List<Object?> get props => [id, filePath, createdAt, durationMs, title, isSent];
}
