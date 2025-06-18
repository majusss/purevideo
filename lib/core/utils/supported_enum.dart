import 'package:hive_flutter/adapters.dart';

enum SupportedService { filman, obejrzyjto }

class SupportedServiceAdapter extends TypeAdapter<SupportedService> {
  @override
  final int typeId = 8;

  @override
  SupportedService read(BinaryReader reader) {
    return SupportedService.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, SupportedService obj) {
    writer.writeInt(obj.index);
  }
}

enum InputType { text, password, recaptcha }

extension SupportedServiceExtension on SupportedService {
  String get displayName => switch (this) {
        SupportedService.filman => 'Filman.cc',
        SupportedService.obejrzyjto => 'Obejrzyj.to',
      };

  String get image => switch (this) {
        SupportedService.filman =>
          'https://filman.cc/public/dist/images/favicon.png',
        SupportedService.obejrzyjto =>
          'https://obejrzyj.to/favicon/icon-144x144.png',
      };

  List<Map<String, InputType>> get loginRequiredFields => switch (this) {
        SupportedService.filman => [
            {'login': InputType.text},
            {'password': InputType.password},
            {'g-recaptcha-response': InputType.recaptcha},
          ],
        SupportedService.obejrzyjto => [
            {'email': InputType.text},
            {'password': InputType.password},
          ],
      };

  bool get canBeAnonymous => switch (this) {
        SupportedService.filman => false,
        SupportedService.obejrzyjto => true,
      };
}
