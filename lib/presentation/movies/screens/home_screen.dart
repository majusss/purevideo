import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/services/watched_service.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/movies/bloc/movies_bloc.dart';
import 'package:purevideo/presentation/movies/bloc/movies_event.dart';
import 'package:purevideo/presentation/movies/bloc/movies_state.dart';
import 'package:purevideo/presentation/global/widgets/error_view.dart';
import 'package:purevideo/presentation/movies/widgets/movie_row.dart';
import 'package:purevideo/data/models/movie_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WatchedService _watchedService = getIt<WatchedService>();
  StreamSubscription? _watchedSubscription;

  @override
  void initState() {
    super.initState();
    context.read<MoviesBloc>().add(LoadMoviesRequested());
    _setupWatchedListener();
  }

  @override
  void dispose() {
    _watchedSubscription?.cancel();
    super.dispose();
  }

  void _setupWatchedListener() {
    _watchedSubscription = _watchedService.watchedStream.listen((watchedList) {
      debugPrint(
          'HomeScreen: Watched list updated: ${watchedList.length} items');

      if (mounted) {
        context.read<MoviesBloc>().add(LoadMoviesRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              final category = movie.category ?? 'INNE';
              moviesByCategory.putIfAbsent(category, () => []).add(movie);
            }

            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<MoviesBloc>().add(LoadMoviesRequested()),
              child: ListView(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                children: moviesByCategory.entries
                    .where((entry) => entry.value.isNotEmpty)
                    .map(
                      (entry) =>
                          MovieRow(title: entry.key, movies: entry.value),
                    )
                    .toList(),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
