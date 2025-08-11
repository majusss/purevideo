import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/di/injection_container.dart';

class MovieRow extends StatelessWidget {
  final String title;
  final List<MovieModel> movies;

  const MovieRow({super.key, required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final movie = movies[index];
              return AspectRatio(
                aspectRatio: 11 / 16,
                child: GestureDetector(
                  onTap: () => context.pushNamed(
                    'movie_details',
                    pathParameters: {
                      'service': movie.service.name,
                      'url': movie.url,
                    },
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FastCachedImage(
                      url: movie.imageUrl,
                      headers: {
                        'User-Agent':
                            'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
                        'Cookie':
                            getIt<Map<SupportedService, AuthRepository>>()[
                                        movie.service]
                                    ?.getAccount()
                                    ?.cookies
                                    .join('; ') ??
                                '',
                      },
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
