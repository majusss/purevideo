import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/presentation/blocs/movies/movies_bloc.dart';
import 'package:purevideo/presentation/blocs/movies/movies_event.dart';
import 'package:purevideo/presentation/blocs/movies/movies_state.dart';
import 'package:purevideo/presentation/widgets/error_view.dart';
import 'package:purevideo/presentation/widgets/movie_row.dart';
import 'package:purevideo/data/models/movie_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MoviesBloc>().add(LoadMoviesRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PureVideo'), scrolledUnderElevation: 0),
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

            return ListView(
              padding: EdgeInsets.only(
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              children:
                  moviesByCategory.entries
                      .where((entry) => entry.value.isNotEmpty)
                      .map(
                        (entry) =>
                            MovieRow(title: entry.key, movies: entry.value),
                      )
                      .toList(),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
