// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_recording.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioRecordingAdapter extends TypeAdapter<AudioRecording> {
  @override
  final int typeId = 3;

  @override
  AudioRecording read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioRecording(
      id: fields[0] as String,
      filePath: fields[1] as String,
      createdAt: fields[2] as DateTime,
      durationMs: fields[3] as int,
      title: fields[4] as String?,
      isSent: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AudioRecording obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.durationMs)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.isSent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioRecordingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
