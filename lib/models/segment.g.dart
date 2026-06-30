// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoadSegmentAdapter extends TypeAdapter<RoadSegment> {
  @override
  final int typeId = 9;

  @override
  RoadSegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoadSegment(
      id: fields[0] as String,
      roadName: fields[1] as String,
      startMilepost: fields[2] as double,
      endMilepost: fields[3] as double,
      lengthInMiles: fields[4] as double,
      state: fields[5] as String,
      pavementMaterial: fields[6] as PavementMaterial,
      shoulderMaterial: fields[7] as ShoulderMaterial,
      stripingMaterial: fields[8] as StripingMaterial,
      paserScore: fields[9] as int?,
      calculatedPci: fields[10] as double?,
      fdotCrackRating: fields[11] as double?,
      fdotRideRating: fields[12] as double?,
      fdotRutRating: fields[13] as double?,
      distresses: (fields[14] as List).cast<DistressRecord>(),
      isSynced: fields[15] as bool,
      timestamp: fields[16] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RoadSegment obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.roadName)
      ..writeByte(2)
      ..write(obj.startMilepost)
      ..writeByte(3)
      ..write(obj.endMilepost)
      ..writeByte(4)
      ..write(obj.lengthInMiles)
      ..writeByte(5)
      ..write(obj.state)
      ..writeByte(6)
      ..write(obj.pavementMaterial)
      ..writeByte(7)
      ..write(obj.shoulderMaterial)
      ..writeByte(8)
      ..write(obj.stripingMaterial)
      ..writeByte(9)
      ..write(obj.paserScore)
      ..writeByte(10)
      ..write(obj.calculatedPci)
      ..writeByte(11)
      ..write(obj.fdotCrackRating)
      ..writeByte(12)
      ..write(obj.fdotRideRating)
      ..writeByte(13)
      ..write(obj.fdotRutRating)
      ..writeByte(14)
      ..write(obj.distresses)
      ..writeByte(15)
      ..write(obj.isSynced)
      ..writeByte(16)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoadSegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
