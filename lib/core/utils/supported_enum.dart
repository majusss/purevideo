import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/core/services/captcha_service.dart';

enum SupportedService { filman, obejrzyjto, ekino }

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
        SupportedService.ekino => 'Ekino-tv.pl',
      };

  String get image => switch (this) {
        SupportedService.filman =>
          'https://filman.cc/public/dist/images/logo.png',
        SupportedService.obejrzyjto =>
          'https://obejrzyj.to/storage/branding_media/ead386d3-fca5-4082-8754-2a0992ae8c22.png',
        SupportedService.ekino => 'https://ekino-tv.pl/views/img/logo.png'
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
        SupportedService.ekino => [
            {'login': InputType.text},
            {'password': InputType.password},
          ],
      };

  bool get canBeAnonymous => switch (this) {
        SupportedService.filman => false,
        SupportedService.obejrzyjto => true,
        SupportedService.ekino => true,
      };

  String get baseUrl => switch (this) {
        SupportedService.filman => 'https://filman.cc',
        SupportedService.obejrzyjto => 'https://obejrzyj.to',
        SupportedService.ekino => 'https://ekino-tv.pl',
      };

  CaptchaConfig get loginCaptchaConfig => switch (this) {
        SupportedService.filman => CaptchaConfig(
            service: CaptchaServiceProvider.recaptcha,
            siteKey: '6LcQs24iAAAAALFibpEQwpQZiyhOCn-zdc-eFout',
            isInvisible: false,
          ),
        SupportedService.obejrzyjto => CaptchaConfig(
            service: CaptchaServiceProvider.recaptcha,
            siteKey: '',
            isInvisible: false,
          ),
        SupportedService.ekino => CaptchaConfig(
            service: CaptchaServiceProvider.recaptcha,
            siteKey: '6Lfk0J0aAAAAACxgxuV0XOQsGUq3w-CX3TZUULuC',
            isInvisible: true,
          ),
      };
}
