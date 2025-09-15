import 'package:dio/dio.dart';
import 'package:purevideo/data/models/filmweb_model.dart';
import 'package:purevideo/data/repositories/filmweb/filmweb_dio_factory.dart';

class FilmwebInfoRepository {
  final Dio _dio = FilmwebDioFactory.getDio();

  FilmwebInfoRepository();

  Future<List<FilmwebSearchResultModel>> searchMovie(
      String query, bool isSeries) async {
    final response = await _dio.get('api/v1/search', queryParameters: {
      'query': query.toLowerCase(),
      'pageSize': 25,
      'groupType': 'web'
    });
    if (response.statusCode == 200) {
      final List<dynamic> results = response.data['searchHits'];
      return results
          .where((r) =>
              r['id'] != null && r['type'] == (isSeries ? 'serial' : 'film'))
          .map((item) => FilmwebSearchResultModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }

  Future<FilmwebPreviewModel> getPreview(int filmwebId) async {
    final response = await _dio.get('api/v1/film/$filmwebId/preview');
    if (response.statusCode == 200) {
      final preview = FilmwebPreviewModel.fromJson(response.data);
      return preview;
    } else {
      throw Exception('Failed to load preview');
    }
  }

  Future<FilmwebRatingModel> getRating(int filmwebId) async {
    final response = await _dio.get('api/v1/film/$filmwebId/ratings');
    if (response.statusCode == 200) {
      final rating = FilmwebRatingModel.fromJson(response.data);
      return rating;
    } else {
      throw Exception('Failed to load rating');
    }
  }
}
