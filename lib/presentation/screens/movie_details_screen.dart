import 'package:flutter/material.dart';
import 'package:purevideo/data/models/movie_model.dart';

class MovieDetailsScreen extends StatefulWidget {
  final MovieDetailsModel movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  int _selectedSeasonIndex = 0;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final seasons = movie.seasons ?? [];
    final currentSeason =
        seasons.isNotEmpty ? seasons[_selectedSeasonIndex] : null;
    final episodes = currentSeason?.episodes ?? [];
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 4,
                    right: 16,
                    bottom: 16,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (movie.genres.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children:
                              movie.genres
                                  .map(
                                    (genre) => Chip(
                                      label: Text(genre),
                                      backgroundColor:
                                          colorScheme.secondaryContainer,
                                      labelStyle: textTheme.bodyMedium
                                          ?.copyWith(
                                            color:
                                                colorScheme
                                                    .onSecondaryContainer,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: AspectRatio(
                              aspectRatio: 11 / 16,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  movie.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
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
                      FilledButton.icon(
                        onPressed: () {
                          // TODO: Odtwórz film
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          movie.isSeries
                              ? 'Oglądaj pierwszy odcinek'
                              : 'Oglądaj film',
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 0),
                          textStyle: textTheme.titleMedium,
                        ),
                      ),
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
                  movie.description.isEmpty ? 'Brak opisu.' : movie.description,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (movie.isSeries && seasons.isNotEmpty)
                  _buildSeriesSection(context, seasons, episodes),
              ]),
            ),
          ),
        ],
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

  Widget _buildSeriesSection(
    BuildContext context,
    List<SeasonModel> seasons,
    List<EpisodeModel> episodes,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Odcinki', style: textTheme.titleLarge),
            if (seasons.length > 1)
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
                    value: _selectedSeasonIndex,
                    isDense: true,
                    items:
                        seasons.asMap().entries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(entry.value.name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSeasonIndex = value;
                        });
                      }
                    },
                    style: textTheme.bodyLarge,
                    dropdownColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              )
            else if (seasons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Text(seasons.first.name, style: textTheme.titleMedium),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          separatorBuilder:
              (_, __) => Divider(
                height: 1,
                color: colorScheme.outlineVariant.withAlpha(128), // 0.5 opacity
              ),
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 0,
              ),
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Text(
                  '${index + 1}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              title: Text(episode.title, style: textTheme.bodyLarge),
              trailing: Icon(
                Icons.play_circle_outline,
                color: colorScheme.primary,
              ),
              onTap: () {
                // TODO: Implementacja odtwarzania odcinka
              },
            );
          },
        ),
      ],
    );
  }
}
