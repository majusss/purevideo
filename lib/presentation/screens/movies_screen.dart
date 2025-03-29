import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/blocs/movies/movies_bloc.dart';
import 'package:purevideo/presentation/blocs/movies/movies_event.dart';
import 'package:purevideo/presentation/blocs/movies/movies_state.dart';

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MoviesBloc>()..add(LoadMoviesRequested()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Filmy')),
        body: BlocBuilder<MoviesBloc, MoviesState>(
          builder: (context, state) {
            if (state is MoviesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MoviesError) {
              return Center(child: Text(state.message));
            }
            if (state is MoviesLoaded) {
              return _buildMoviesList(context, state);
            }
            return const Center(child: Text('Brak filmów'));
          },
        ),
      ),
    );
  }

  Widget _buildMoviesList(BuildContext context, MoviesLoaded state) {
    if (state.movies.isEmpty) {
      return const Center(child: Text('Brak filmów'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: state.movies.length,
      itemBuilder: (context, index) {
        final movie = state.movies[index];
        return _buildMovieCard(context, movie);
      },
    );
  }

  Widget _buildMovieCard(BuildContext context, MovieModel movie) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Tutaj dodaj nawigację do szczegółów filmu
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child:
                  movie.imageUrl.isNotEmpty
                      ? Image.network(
                        movie.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                      : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.movie,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.service.displayName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
