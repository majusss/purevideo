import 'dart:convert';

final RegExp _bootstrapDataRegex = RegExp(
  r'window\.bootstrapData\s*=\s*(\{.*?\});',
  dotAll: true,
);

Map<String, dynamic>? extractBootstrapData(String responseData) {
  final match = _bootstrapDataRegex.firstMatch(responseData);
  final jsonString = match?.group(1);

  if (jsonString == null) return null;

  final data = jsonDecode(jsonString);
  return data is Map<String, dynamic> ? data : null;
}

String generateSlug(String title) {
  const Map<String, String> polishChars = {
    'ą': 'a',
    'Ą': 'a',
    'ć': 'c',
    'Ć': 'c',
    'ę': 'e',
    'Ę': 'e',
    'ł': 'l',
    'Ł': 'l',
    'ń': 'n',
    'Ń': 'n',
    'ó': 'o',
    'Ó': 'o',
    'ś': 's',
    'Ś': 's',
    'ź': 'z',
    'Ź': 'z',
    'ż': 'z',
    'Ż': 'z',
  };

  String slug = title;

  polishChars.forEach((polish, replacement) {
    slug = slug.replaceAll(polish, replacement);
  });
  slug = slug.toLowerCase();
  slug = slug.replaceAll(RegExp(r'[:\.\*\(\)\[\]{}]'), ' ');
  slug = slug.replaceAll(RegExp(r'[^\w\s-]'), ' ');
  slug = slug.replaceAll(RegExp(r'\s+'), ' ');
  slug = slug.trim();
  slug = slug.replaceAll(' ', '-');
  slug = slug.replaceAll(RegExp(r'-+'), '-');
  slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');

  return slug;
}
