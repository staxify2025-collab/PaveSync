// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DistressRecordAdapter extends TypeAdapter<DistressRecord> {
  @override
  final int typeId = 8;

  @override
  DistressRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DistressRecord(
      id: fields[0] as String,
      category: fields[1] as DistressCategory,
      specificType: fields[2] as String,
      severity: fields[3] as SeverityLevel,
      quantity: fields[4] as double,
      unit: fields[5] as String,
      latitude: fields[6] as double,
      longitude: fields[7] as double,
      timestamp: fields[8] as DateTime,
      notes: fields[9] as String,
      photoPath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DistressRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.specificType)
      ..writeByte(3)
      ..write(obj.severity)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.unit)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.photoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistressRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SeverityLevelAdapter extends TypeAdapter<SeverityLevel> {
  @override
  final int typeId = 0;

  @override
  SeverityLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SeverityLevel.low;
      case 1:
        return SeverityLevel.medium;
      case 2:
        return SeverityLevel.high;
      default:
        return SeverityLevel.low;
    }
  }

  @override
  void write(BinaryWriter writer, SeverityLevel obj) {
    switch (obj) {
      case SeverityLevel.low:
        writer.writeByte(0);
        break;
      case SeverityLevel.medium:
        writer.writeByte(1);
        break;
      case SeverityLevel.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeverityLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DistressCategoryAdapter extends TypeAdapter<DistressCategory> {
  @override
  final int typeId = 1;

  @override
  DistressCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DistressCategory.pavement;
      case 1:
        return DistressCategory.shoulder;
      case 2:
        return DistressCategory.striping;
      default:
        return DistressCategory.pavement;
    }
  }

  @override
  void write(BinaryWriter writer, DistressCategory obj) {
    switch (obj) {
      case DistressCategory.pavement:
        writer.writeByte(0);
        break;
      case DistressCategory.shoulder:
        writer.writeByte(1);
        break;
      case DistressCategory.striping:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistressCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PavementDistressTypeAdapter extends TypeAdapter<PavementDistressType> {
  @override
  final int typeId = 2;

  @override
  PavementDistressType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PavementDistressType.alligatorCracking;
      case 1:
        return PavementDistressType.bleeding;
      case 2:
        return PavementDistressType.blockCracking;
      case 3:
        return PavementDistressType.corrugation;
      case 4:
        return PavementDistressType.depression;
      case 5:
        return PavementDistressType.edgeCracking;
      case 6:
        return PavementDistressType.longitudinalTransverseCracking;
      case 7:
        return PavementDistressType.patching;
      case 8:
        return PavementDistressType.polishedAggregate;
      case 9:
        return PavementDistressType.pothole;
      case 10:
        return PavementDistressType.rutting;
      case 11:
        return PavementDistressType.shoving;
      case 12:
        return PavementDistressType.slippageCracking;
      case 13:
        return PavementDistressType.swell;
      case 14:
        return PavementDistressType.weatheringRaveling;
      default:
        return PavementDistressType.alligatorCracking;
    }
  }

  @override
  void write(BinaryWriter writer, PavementDistressType obj) {
    switch (obj) {
      case PavementDistressType.alligatorCracking:
        writer.writeByte(0);
        break;
      case PavementDistressType.bleeding:
        writer.writeByte(1);
        break;
      case PavementDistressType.blockCracking:
        writer.writeByte(2);
        break;
      case PavementDistressType.corrugation:
        writer.writeByte(3);
        break;
      case PavementDistressType.depression:
        writer.writeByte(4);
        break;
      case PavementDistressType.edgeCracking:
        writer.writeByte(5);
        break;
      case PavementDistressType.longitudinalTransverseCracking:
        writer.writeByte(6);
        break;
      case PavementDistressType.patching:
        writer.writeByte(7);
        break;
      case PavementDistressType.polishedAggregate:
        writer.writeByte(8);
        break;
      case PavementDistressType.pothole:
        writer.writeByte(9);
        break;
      case PavementDistressType.rutting:
        writer.writeByte(10);
        break;
      case PavementDistressType.shoving:
        writer.writeByte(11);
        break;
      case PavementDistressType.slippageCracking:
        writer.writeByte(12);
        break;
      case PavementDistressType.swell:
        writer.writeByte(13);
        break;
      case PavementDistressType.weatheringRaveling:
        writer.writeByte(14);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PavementDistressTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShoulderDistressTypeAdapter extends TypeAdapter<ShoulderDistressType> {
  @override
  final int typeId = 3;

  @override
  ShoulderDistressType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ShoulderDistressType.shoulderDropoff;
      case 1:
        return ShoulderDistressType.shoulderErosion;
      case 2:
        return ShoulderDistressType.shoulderCracking;
      case 3:
        return ShoulderDistressType.vegetationEncroachment;
      default:
        return ShoulderDistressType.shoulderDropoff;
    }
  }

  @override
  void write(BinaryWriter writer, ShoulderDistressType obj) {
    switch (obj) {
      case ShoulderDistressType.shoulderDropoff:
        writer.writeByte(0);
        break;
      case ShoulderDistressType.shoulderErosion:
        writer.writeByte(1);
        break;
      case ShoulderDistressType.shoulderCracking:
        writer.writeByte(2);
        break;
      case ShoulderDistressType.vegetationEncroachment:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoulderDistressTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StripingDistressTypeAdapter extends TypeAdapter<StripingDistressType> {
  @override
  final int typeId = 4;

  @override
  StripingDistressType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StripingDistressType.paintWear;
      case 1:
        return StripingDistressType.legendWear;
      case 2:
        return StripingDistressType.retroreflectivityLoss;
      case 3:
        return StripingDistressType.missingRPMs;
      default:
        return StripingDistressType.paintWear;
    }
  }

  @override
  void write(BinaryWriter writer, StripingDistressType obj) {
    switch (obj) {
      case StripingDistressType.paintWear:
        writer.writeByte(0);
        break;
      case StripingDistressType.legendWear:
        writer.writeByte(1);
        break;
      case StripingDistressType.retroreflectivityLoss:
        writer.writeByte(2);
        break;
      case StripingDistressType.missingRPMs:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StripingDistressTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PavementMaterialAdapter extends TypeAdapter<PavementMaterial> {
  @override
  final int typeId = 5;

  @override
  PavementMaterial read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PavementMaterial.asphalt;
      case 1:
        return PavementMaterial.concrete;
      case 2:
        return PavementMaterial.composite;
      default:
        return PavementMaterial.asphalt;
    }
  }

  @override
  void write(BinaryWriter writer, PavementMaterial obj) {
    switch (obj) {
      case PavementMaterial.asphalt:
        writer.writeByte(0);
        break;
      case PavementMaterial.concrete:
        writer.writeByte(1);
        break;
      case PavementMaterial.composite:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PavementMaterialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShoulderMaterialAdapter extends TypeAdapter<ShoulderMaterial> {
  @override
  final int typeId = 6;

  @override
  ShoulderMaterial read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ShoulderMaterial.asphalt;
      case 1:
        return ShoulderMaterial.concrete;
      case 2:
        return ShoulderMaterial.gravel;
      case 3:
        return ShoulderMaterial.turf;
      case 4:
        return ShoulderMaterial.soil;
      default:
        return ShoulderMaterial.asphalt;
    }
  }

  @override
  void write(BinaryWriter writer, ShoulderMaterial obj) {
    switch (obj) {
      case ShoulderMaterial.asphalt:
        writer.writeByte(0);
        break;
      case ShoulderMaterial.concrete:
        writer.writeByte(1);
        break;
      case ShoulderMaterial.gravel:
        writer.writeByte(2);
        break;
      case ShoulderMaterial.turf:
        writer.writeByte(3);
        break;
      case ShoulderMaterial.soil:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoulderMaterialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StripingMaterialAdapter extends TypeAdapter<StripingMaterial> {
  @override
  final int typeId = 7;

  @override
  StripingMaterial read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StripingMaterial.paint;
      case 1:
        return StripingMaterial.thermoplastic;
      case 2:
        return StripingMaterial.preformedTape;
      case 3:
        return StripingMaterial.epoxy;
      case 4:
        return StripingMaterial.rpm;
      default:
        return StripingMaterial.paint;
    }
  }

  @override
  void write(BinaryWriter writer, StripingMaterial obj) {
    switch (obj) {
      case StripingMaterial.paint:
        writer.writeByte(0);
        break;
      case StripingMaterial.thermoplastic:
        writer.writeByte(1);
        break;
      case StripingMaterial.preformedTape:
        writer.writeByte(2);
        break;
      case StripingMaterial.epoxy:
        writer.writeByte(3);
        break;
      case StripingMaterial.rpm:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StripingMaterialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
