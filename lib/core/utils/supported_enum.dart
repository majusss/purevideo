enum SupportedService { filman, obejrzyjto }

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
}
