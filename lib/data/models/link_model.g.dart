// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HostLinkAdapter extends TypeAdapter<HostLink> {
  @override
  final int typeId = 2;

  @override
  HostLink read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HostLink(
      lang: fields[0] as String,
      quality: fields[1] as String,
      url: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HostLink obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.lang)
      ..writeByte(1)
      ..write(obj.quality)
      ..writeByte(2)
      ..write(obj.url);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostLinkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
