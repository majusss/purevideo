import 'package:purevideo/core/utils/supported_enum.dart';

class MovieModel {
  final SupportedService service;
  final String title;
  final String imageUrl;
  final String url;

  MovieModel({
    required this.service,
    required this.title,
    required this.imageUrl,
    required this.url,
  });
}
