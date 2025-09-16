// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ga.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameAttributesAdapter extends TypeAdapter<GameAttributes> {
  @override
  final int typeId = 1;

  @override
  GameAttributes read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameAttributes(
      gameId: fields[0] as String,
      imgUrl: fields[2] as String?,
      type: fields[1] as GameType,
      url: fields[4] as String,
      conceptId: fields[5] as String?,
      addon: fields[6] as bool?,
      releaseDate: fields[7] as String?,
    )..discountedValue = fields[3] as int?;
  }

  @override
  void write(BinaryWriter writer, GameAttributes obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.gameId)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.imgUrl)
      ..writeByte(3)
      ..write(obj.discountedValue)
      ..writeByte(4)
      ..write(obj.url)
      ..writeByte(5)
      ..write(obj.conceptId)
      ..writeByte(6)
      ..write(obj.addon)
      ..writeByte(7)
      ..write(obj.releaseDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameAttributesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GameTypeAdapter extends TypeAdapter<GameType> {
  @override
  final int typeId = 11;

  @override
  GameType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GameType.PRODUCT;
      case 1:
        return GameType.CONCEPT;
      case 2:
        return GameType.ADD_ON;
      case 3:
        return GameType.CONCEPT_PRE_ORDER;
      default:
        return GameType.PRODUCT;
    }
  }

  @override
  void write(BinaryWriter writer, GameType obj) {
    switch (obj) {
      case GameType.PRODUCT:
        writer.writeByte(0);
        break;
      case GameType.CONCEPT:
        writer.writeByte(1);
        break;
      case GameType.ADD_ON:
        writer.writeByte(2);
        break;
      case GameType.CONCEPT_PRE_ORDER:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
