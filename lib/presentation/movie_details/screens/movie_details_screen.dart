import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purevideo/core/services/watched_service.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/movie_details/bloc/movie_details_bloc.dart';
import 'package:purevideo/presentation/movie_details/bloc/movie_details_event.dart';
import 'package:purevideo/presentation/movie_details/bloc/movie_details_state.dart';
import 'package:purevideo/presentation/global/widgets/error_view.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';

class MovieDetailsScreen extends StatelessWidget {
  final MovieModel movie;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieDetailsBloc()
        ..add(
          LoadMovieDetails(movie: movie),
        ),
      child: const MovieDetailsView(),
    );
  }
}

class MovieDetailsView extends StatefulWidget {
  const MovieDetailsView({super.key});

  @override
  State<MovieDetailsView> createState() => _MovieDetailsViewState();
}

class _MovieDetailsViewState extends State<MovieDetailsView> {
  final WatchedService _watchedService = getIt<WatchedService>();
  StreamSubscription? _watchedSubscription;

  @override
  void initState() {
    super.initState();
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
        final bloc = context.read<MovieDetailsBloc>();
        if (bloc.state.movie != null) {
          final watched = _watchedService.getByMovie(bloc.state.movie!);
          bloc.add(UpdateWatchedStatus(watched: watched));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
      builder: (context, state) {
        if (state.movie != null) {
          return _buildMovieDetails(context, state);
        } else if (state.errorMessage != null) {
          return _buildErrorView(
              context, state.errorMessage ?? 'Nieznany błąd');
        } else {
          return _buildLoadingView(context);
        }
      },
    );
  }

  Widget _buildLoadingView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anuluj'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String errorMessage) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ErrorView(
        message: 'Wystąpił błąd: $errorMessage',
        onRetry: () {
          final bloc = context.read<MovieDetailsBloc>();
          final service = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          if (service != null &&
              service['service'] != null &&
              service['url'] != null) {
            bloc.add(LoadMovieDetails(
              movie: service['movie'] as MovieModel,
            ));
          }
        },
      ),
    );
  }

  Widget _buildMovieDetails(BuildContext context, MovieDetailsState state) {
    final movie = state.movie!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // if (movie.genres.isNotEmpty)
                      //   Wrap(
                      //     spacing: 8.0,
                      //     children: movie.genres
                      //         .map(
                      //           (genre) => Chip(
                      //             label: Text(genre),
                      //             backgroundColor:
                      //                 colorScheme.secondaryContainer,
                      //             labelStyle: textTheme.bodyMedium?.copyWith(
                      //               color: colorScheme.onSecondaryContainer,
                      //             ),
                      //             padding: const EdgeInsets.symmetric(
                      //               horizontal: 8,
                      //             ),
                      //             visualDensity: VisualDensity.compact,
                      //           ),
                      //         )
                      //         .toList(),
                      //   ),
                      // const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            child: AspectRatio(
                              aspectRatio: 11 / 16,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: FastCachedImage(
                                  url: movie.imageUrl,
                                  headers: movie.imageHeaders,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              movie.title,
                              style: textTheme.headlineSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row(
                      //   children: [
                      //     _buildInfoChip(
                      //       Icons.calendar_month_outlined,
                      //       movie.year,
                      //       context,
                      //     ),
                      //     const SizedBox(width: 12),
                      //     if (movie.countries.isNotEmpty)
                      //       _buildInfoChip(
                      //         Icons.public_outlined,
                      //         movie.countries.join(', '),
                      //         context,
                      //       ),
                      //   ],
                      // ),
                      // const SizedBox(height: 16),
                      _buildPlayButton(context, state),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Opis', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  movie.description,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (state.isSeries && state.seasons.isNotEmpty)
                  _buildSeriesSection(context, state),
                for (final service in movie.services) ...[
                  Text(
                      'Serwis: ${service.service.displayName} - ${service.title.toLowerCase().trim().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim()} - ${service.url}',
                      style: textTheme.titleSmall),
                  const SizedBox(height: 6),
                  for (final link in service.videoUrls ?? [])
                    Text(
                      link.url,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  const Divider()
                ],
                Text('Directs', style: textTheme.titleSmall),
                const SizedBox(height: 6),
                for (final VideoSource link in movie.directUrls ?? []) ...[
                  Text(
                    '${link.host}: ${link.url}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                ]
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(BuildContext context, MovieDetailsState state) {
    final textTheme = Theme.of(context).textTheme;
    final movie = state.movie!;

    return FilledButton.icon(
      onPressed: () {
        if (!state.isLoaded) {
          return;
        }
        if (movie.isSeries) {
          context.pushNamed(
            'player',
            extra: movie,
            queryParameters: {
              'season': state.selectedSeasonIndex.toString(),
              'episode': ((state.watched?.lastWatchedEpisode?.watchedEpisode
                              .episode.number ??
                          1) -
                      1)
                  .toString(),
            },
          );
        } else {
          context.pushNamed(
            'player',
            extra: movie,
          );
        }
      },
      icon: state.isLoaded
          ? const Icon(Icons.play_arrow)
          : const Icon(Icons.refresh),
      label: state.isLoaded
          ? Text(watchedText(state))
          : const Text('Wczytywanie...'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 0),
        textStyle: textTheme.titleMedium,
      ),
    );
  }

  String watchedText(MovieDetailsState state) {
    if (state.watched != null) {
      if (state.movie!.isSeries) {
        return 'Kontynuuj odcinek ${state.watched!.lastWatchedEpisode?.watchedEpisode.episode.number}';
      } else {
        return 'Kontynuuj';
      }
    } else {
      if (state.movie!.isSeries) {
        return 'Oglądaj sezon ${state.selectedSeasonIndex + 1}';
      } else {
        return 'Oglądaj';
      }
    }
  }

  // Widget _buildInfoChip(IconData icon, String text, BuildContext context) {
  //   if (text.isEmpty) return const SizedBox.shrink();
  //   return Chip(
  //     avatar: Icon(
  //       icon,
  //       size: 16,
  //       color: Theme.of(context).colorScheme.onSurfaceVariant,
  //     ),
  //     label: Text(text),
  //     visualDensity: VisualDensity.compact,
  //     padding: const EdgeInsets.symmetric(horizontal: 8),
  //     backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
  //   );
  // }

  Widget _buildSeriesSection(BuildContext context, MovieDetailsState state) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bloc = context.read<MovieDetailsBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Odcinki', style: textTheme.titleLarge),
            if (state.seasons.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: state.selectedSeasonIndex,
                    isDense: true,
                    items: state.seasons.asMap().entries.map((entry) {
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(entry.value.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        bloc.add(SelectSeason(seasonIndex: value));
                      }
                    },
                    style: textTheme.bodyLarge,
                    dropdownColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              )
            else if (state.seasons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Text(state.seasons.first.name,
                    style: textTheme.titleMedium),
              ),
          ],
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.episodes.length,
          padding: const EdgeInsets.only(top: 8),
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: colorScheme.outlineVariant.withAlpha(128),
          ),
          itemBuilder: (context, index) {
            final episode = state.episodes[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 0,
              ),
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Text(
                  episode.number.toString(),
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSecondaryContainer),
                ),
              ),
              title: Text(
                episode.title,
                style: textTheme.bodyLarge,
              ),
              onTap: () {
                context.pushNamed(
                  'player',
                  extra: state.movie!,
                  queryParameters: {
                    'season': state.selectedSeasonIndex.toString(),
                    'episode': index.toString(),
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
