import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/movie_details/bloc/movie_details_bloc.dart';
import 'package:purevideo/presentation/movie_details/bloc/movie_details_event.dart';
import 'package:purevideo/presentation/movie_details/bloc/movie_details_state.dart';
import 'package:purevideo/presentation/global/widgets/error_view.dart';
import 'package:purevideo/core/services/settings_service.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';

class MovieDetailsScreen extends StatelessWidget {
  final SupportedService service;
  final String url;

  const MovieDetailsScreen({
    super.key,
    required this.service,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MovieDetailsBloc>()
        ..add(
          LoadMovieDetails(service: service, url: url),
        ),
      child: const MovieDetailsView(),
    );
  }
}

class MovieDetailsView extends StatelessWidget {
  const MovieDetailsView({super.key});

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
              label: const Text("Anuluj"),
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
              service: service['service'],
              url: service['url'],
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
                      if (movie.genres.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: movie.genres
                              .map(
                                (genre) => Chip(
                                  label: Text(genre),
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  labelStyle: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 16),
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
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.calendar_month_outlined,
                            movie.year,
                            context,
                          ),
                          const SizedBox(width: 12),
                          if (movie.countries.isNotEmpty)
                            _buildInfoChip(
                              Icons.public_outlined,
                              movie.countries.join(', '),
                              context,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPlayButton(context, state),
                      if (!state.isSeries &&
                          getIt<SettingsService>().isDebugVisible)
                        _buildMovieDebugPanel(context, state),
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
        if (movie.isSeries) {
          context.pushNamed(
            'player',
            extra: movie,
            queryParameters: {
              'season': state.selectedSeasonIndex.toString(),
              'episode': "0",
            },
          );
        } else {
          context.pushNamed(
            'player',
            extra: movie,
          );
        }
      },
      icon: const Icon(Icons.play_arrow),
      label: Text(
          "Oglądaj ${movie.isSeries ? 'sezon ${state.selectedSeasonIndex + 1}' : ''}"),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 0),
        textStyle: textTheme.titleMedium,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Chip(
      avatar: Icon(
        icon,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text(text),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

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
        if (getIt<SettingsService>().isDebugVisible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Debug - Status odcinków:",
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_filled,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        "Wczytane",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.hourglass_top,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        "Wczytywanie",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.play_circle_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "Niewczytane",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                      height: 16,
                      color: colorScheme.outline..withValues(alpha: 0.5)),
                  Text(
                    "Statystyki:",
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    "Całkowita liczba odcinków: ${state.episodes.length}",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    "Odcinki wczytane: ${state.episodes.where((e) => e.directUrls != null && e.directUrls!.isNotEmpty).length}",
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "Odcinki z URLami wideo: ${state.episodes.length}",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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
                  '${index + 1}',
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

  Widget _buildMovieDebugPanel(BuildContext context, MovieDetailsState state) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final movie = state.movie!;
    final hasDirectUrls =
        movie.directUrls != null && movie.directUrls!.isNotEmpty;
    final bloc = context.read<MovieDetailsBloc>();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Debug - Status filmu:",
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  hasDirectUrls
                      ? Icons.play_circle_filled
                      : Icons.play_circle_outline,
                  size: 16,
                  color: hasDirectUrls ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  hasDirectUrls ? "Źródła wczytane" : "Brak źródeł",
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Divider(
                height: 16, color: colorScheme.outline.withValues(alpha: 0.5)),
            Text(
              "Statystyki:",
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              "Host URLs: ${movie.videoUrls?.length ?? 0}",
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              "Direct URLs: ${movie.directUrls?.length ?? 0}",
              style: textTheme.bodySmall?.copyWith(
                color: hasDirectUrls ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Debug filmu"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Tytuł: ${movie.title}"),
                          Text("URL: ${movie.url}"),
                          const Divider(),
                          Text(
                            "Host URLs: ${movie.videoUrls?.length ?? 0}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...(movie.videoUrls ?? [])
                              .map((link) => Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                        "${link.url} (${link.lang}, ${link.quality})"),
                                  ))
                              .toList(),
                          const Divider(),
                          Text(
                            "Direct URLs: ${movie.directUrls?.length ?? 0}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...(movie.directUrls ?? [])
                              .map((src) => Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                        "${src.url} (${src.lang}, ${src.quality})"),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Zamknij"),
                      ),
                      TextButton(
                        onPressed: () {
                          bloc.add(ScrapeVideoUrls(
                            movie: movie,
                            service: movie.service,
                          ));
                          Navigator.of(context).pop();
                        },
                        child: const Text("Scrapuj ponownie"),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text("Szczegóły debugowania"),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
