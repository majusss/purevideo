enum SupportedService { filman, obejrzyjto }

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
