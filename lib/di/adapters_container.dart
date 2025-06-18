import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/link_model.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/watched_model.dart';

void setupHiveAdapters() {
  Hive.registerAdapter(SupportedServiceAdapter());
  Hive.registerAdapter(MovieModelAdapter());
  Hive.registerAdapter(MovieDetailsModelAdapter());
  Hive.registerAdapter(VideoSourceAdapter());
  Hive.registerAdapter(SeasonModelAdapter());
  Hive.registerAdapter(EpisodeModelAdapter());
  Hive.registerAdapter(HostLinkAdapter());
  Hive.registerAdapter(WatchedEpisodeModelAdapter());
  Hive.registerAdapter(WatchedMovieModelAdapter());
}
