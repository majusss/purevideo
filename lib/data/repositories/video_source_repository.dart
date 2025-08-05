import 'dart:io';

import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:purevideo/core/video_hosts/video_host_registry.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:dio/dio.dart';

class VideoSourceRepository {
  final VideoHostRegistry _hostRegistry = getIt<VideoHostRegistry>();

  Future<MovieDetailsModel> scrapeVideoUrls(MovieDetailsModel movie) async {
    if (movie.videoUrls == null) return movie;

    final videoSources = <VideoSource>[];

    for (final hostLink in movie.videoUrls!) {
      final scraper = _hostRegistry.getScraperForUrl(hostLink.url);

      if (scraper == null) continue;

      final videoSource = await scraper.getVideoSource(
          hostLink.url, hostLink.lang, hostLink.quality);

      if (videoSource == null) continue;

      final Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      final ioc = HttpClient();
      ioc.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => ioc,
      );

      try {
        final response = await dio.head(videoSource.url,
            options: Options(
                headers: videoSource.headers, validateStatus: (_) => true));

        if (response.statusCode != 200) continue;
      } catch (e) {
        debugPrint('Error checking video source URL: $e');
        continue;
      }

      videoSources.add(videoSource);
    }

    return movie.copyWith(directUrls: videoSources);
  }
}
