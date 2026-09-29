import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/utils.dart';
import '../models/photo.dart';
import '../screens/detail/photo_detail_screen.dart';
import 'save_button.dart';

/// One photo in a grid: keeps the photo's own aspect ratio, opens the detail
/// screen on tap (with a Hero transition) and has a save button overlay.
///
/// [heroTag] must be unique per screen ("home-123", "search-123", ...).
/// All tabs stay alive at once, so the same photo can be on screen in two
/// tabs and two Heroes with the same tag would clash.
class PhotoTile extends StatelessWidget {
  final Photo photo;
  final String heroTag;

  const PhotoTile({super.key, required this.photo, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          fadeRoute(PhotoDetailScreen(photo: photo, heroTag: heroTag)),
        );
      },
      child: AspectRatio(
        aspectRatio: photo.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: heroTag,
                child: CachedNetworkImage(
                  imageUrl: photo.thumbnailUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) =>
                      ColoredBox(color: colorFromHex(photo.averageColor)),
                  errorWidget: (context, url, error) => ColoredBox(
                    color: Colors.grey.shade400,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: SaveButton(photo: photo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}