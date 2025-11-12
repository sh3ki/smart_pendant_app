// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoredTelemetryAdapter extends TypeAdapter<StoredTelemetry> {
  @override
  final int typeId = 0;

  @override
  StoredTelemetry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredTelemetry(
      deviceId: fields[0] as String,
      timestamp: fields[1] as String,
      lat: fields[2] as double,
      lon: fields[3] as double,
      accuracyMeters: fields[4] as double,
      speed: fields[5] as double,
      alt: fields[6] as double?,
      batteryPercent: fields[7] as int,
      signalDbm: fields[8] as int?,
      motionState: fields[9] as String,
      firmwareVersion: fields[10] as String?,
      accelX: fields[11] as double,
      accelY: fields[12] as double,
      accelZ: fields[13] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StoredTelemetry obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.lat)
      ..writeByte(3)
      ..write(obj.lon)
      ..writeByte(4)
      ..write(obj.accuracyMeters)
      ..writeByte(5)
      ..write(obj.speed)
      ..writeByte(6)
      ..write(obj.alt)
      ..writeByte(7)
      ..write(obj.batteryPercent)
      ..writeByte(8)
      ..write(obj.signalDbm)
      ..writeByte(9)
      ..write(obj.motionState)
      ..writeByte(10)
      ..write(obj.firmwareVersion)
      ..writeByte(11)
      ..write(obj.accelX)
      ..writeByte(12)
      ..write(obj.accelY)
      ..writeByte(13)
      ..write(obj.accelZ);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredTelemetryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoredPanicAlertAdapter extends TypeAdapter<StoredPanicAlert> {
  @override
  final int typeId = 1;

  @override
  StoredPanicAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredPanicAlert(
      id: fields[0] as String,
      deviceId: fields[1] as String,
      timestamp: fields[2] as String,
      lat: fields[3] as double,
      lon: fields[4] as double,
      handled: fields[5] as bool,
      handledAt: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StoredPanicAlert obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deviceId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.lon)
      ..writeByte(5)
      ..write(obj.handled)
      ..writeByte(6)
      ..write(obj.handledAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredPanicAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StoredActivityRecordAdapter extends TypeAdapter<StoredActivityRecord> {
  @override
  final int typeId = 2;

  @override
  StoredActivityRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredActivityRecord(
      id: fields[0] as String,
      timestamp: fields[1] as String,
      activityType: fields[2] as String,
      speed: fields[3] as double,
      steps: fields[4] as int,
      calories: fields[5] as int,
      accelX: fields[6] as double,
      accelY: fields[7] as double,
      accelZ: fields[8] as double,
    );
  }

  @override
  void write(BinaryWriter writer, StoredActivityRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.activityType)
      ..writeByte(3)
      ..write(obj.speed)
      ..writeByte(4)
      ..write(obj.steps)
      ..writeByte(5)
      ..write(obj.calories)
      ..writeByte(6)
      ..write(obj.accelX)
      ..writeByte(7)
      ..write(obj.accelY)
      ..writeByte(8)
      ..write(obj.accelZ);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredActivityRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
