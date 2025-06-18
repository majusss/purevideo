import 'package:hive_flutter/adapters.dart';

part 'link_model.g.dart';

@HiveType(typeId: 2)
class HostLink {
  @HiveField(0)
  final String lang;

  @HiveField(1)
  final String quality;

  @HiveField(2)
  final String url;

  const HostLink(
      {required this.lang, required this.quality, required this.url});
}
