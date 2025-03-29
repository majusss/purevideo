import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_dio_factory.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:html/parser.dart' as html;
import 'package:purevideo/di/injection_container.dart';

class FilmanMovieRepository implements MovieRepository {
  final AuthRepository _authRepository =
      getIt<Map<SupportedService, AuthRepository>>()[SupportedService.filman]!;

  @override
  Future<List<MovieModel>> getMovies() async {
    final account = _authRepository.getAccountForService(
      SupportedService.filman,
    );
    final dio = FilmanDioFactory.getDio(account);
    final response = await dio.get('/');
    final document = html.parse(response.data);

    final movies = <MovieModel>[];

    for (final list in document.querySelectorAll("div[id=item-list]")) {
      for (final item in list.children) {
        final poster = item.querySelector(".poster");
        final title =
            poster
                ?.querySelector("a")
                ?.attributes["title"]
                ?.trim()
                .split("/")
                .first
                .trim() ??
            "Brak danych";
        final imageUrl =
            poster?.querySelector("img")?.attributes["src"] ??
            "https://placehold.co/250x370/png?font=roboto&text=?";
        final link =
            poster?.querySelector("a")?.attributes["href"] ?? "Brak danych";
        // final category =
        //     list.parent?.querySelector("h3")?.text.trim() ?? "INNE";

        final movie = MovieModel(
          service: SupportedService.filman,
          title: title,
          imageUrl: imageUrl,
          url: link,
        );

        movies.add(movie);
      }
    }

    return movies;
  }
}
