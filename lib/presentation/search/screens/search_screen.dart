import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/search/bloc/search_block.dart';
import 'package:purevideo/presentation/search/bloc/search_event.dart';
import 'package:purevideo/presentation/search/bloc/search_state.dart';
import 'package:purevideo/presentation/global/widgets/error_view.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Szukaj'), centerTitle: true),
        body: BlocProvider(
          create: (context) => SearchBloc(),
          child: const SearchScreenContent(),
        ));
  }
}

class MovieListItem extends StatelessWidget {
  final MovieModel movie;

  const MovieListItem({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed('movie_details', pathParameters: {
        'service': movie.service.name,
        'url': movie.url,
      }),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FastCachedImage(
          url: movie.imageUrl,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
            'Cookie':
                getIt<Map<SupportedService, AuthRepository>>()[movie.service]
                        ?.getAccount()
                        ?.cookies
                        .join('; ') ??
                    '',
          },
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

class SearchScreenContent extends StatefulWidget {
  const SearchScreenContent({super.key});

  @override
  State<SearchScreenContent> createState() => _SearchScreenContentState();
}

class _SearchScreenContentState extends State<SearchScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<SearchBloc>().add(const SearchCleared());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(32),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: (final query) =>
                context.read<SearchBloc>().add(SearchRequested(query)),
            decoration: InputDecoration(
              hintText: 'Wpisz tytuł filmu...',
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchInitial) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Zacznij wpisywać aby wyszukać filmy'),
                ),
              );
            } else if (state is SearchLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (state is SearchLoaded) {
              if (state.results.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Nie znaleziono żadnych filmów'),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.67,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: state.results.length,
                itemBuilder: (context, index) {
                  return MovieListItem(movie: state.results[index]);
                },
              );
            } else if (state is SearchError) {
              return ErrorView(
                  message: state.message,
                  onRetry: () {
                    _onSearchChanged(_searchController.text);
                  });
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
