import 'dart:async';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/services/watched_service.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/movies/bloc/movies_bloc.dart';
import 'package:purevideo/presentation/movies/bloc/movies_event.dart';
import 'package:purevideo/presentation/movies/bloc/movies_state.dart';
import 'package:purevideo/presentation/global/widgets/error_view.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class MovieListItem extends StatelessWidget {
  final MovieModel movie;

  const MovieListItem({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed('movie_details',
          pathParameters: {
            'title': movie.title,
          },
          extra: movie),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FastCachedImage(
          url: movie.imageUrl,
          headers: movie.imageHeaders,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.movie,
              color: Theme.of(context).colorScheme.primary,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final WatchedService _watchedService = getIt<WatchedService>();
  StreamSubscription? _watchedSubscription;
  late MoviesBloc _moviesBloc;

  @override
  void initState() {
    super.initState();
    _moviesBloc = MoviesBloc();
    _setupWatchedListener();
  }

  @override
  void dispose() {
    _watchedSubscription?.cancel();
    super.dispose();
  }

  void _setupWatchedListener() {
    _watchedSubscription = _watchedService.watchedStream.listen((watchedList) {
      if (mounted) {
        _moviesBloc.add(LoadMoviesRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _moviesBloc..add(LoadMoviesRequested()),
      child: Scaffold(
        body: BlocBuilder<MoviesBloc, MoviesState>(
          builder: (context, state) {
            if (state is MoviesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MoviesError) {
              return ErrorView(
                message: state.message,
                onRetry: () {
                  context.read<MoviesBloc>().add(LoadMoviesRequested());
                },
              );
            }
            if (state is MoviesLoaded) {
              if (state.movies.isEmpty) {
                return const Center(child: Text('Brak dostępnych filmów'));
              }

              final moviesByCategory = <String, List<MovieModel>>{};
              for (final movie in state.movies) {
                const category = /*movie.category ??*/ 'INNE';
                moviesByCategory.putIfAbsent(category, () => []).add(movie);
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<MoviesBloc>().add(LoadMoviesRequested()),
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.67,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: state.movies.length,
                    itemBuilder: (context, index) {
                      return MovieListItem(movie: state.movies[index]);
                    },
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
