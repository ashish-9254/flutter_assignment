import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/photo.dart';
import '../../widgets/save_button.dart';

/// Full-size photo, photographer, Save and Share.
///
/// [heroTag] matches the tag on the tile that was tapped, which is what makes
/// the image fly from the grid into this screen.
class PhotoDetailScreen extends StatelessWidget {
  final Photo photo;
  final String heroTag;

  const PhotoDetailScreen({
    super.key,
    required this.photo,
    required this.heroTag,
  });

  Future<void> _share(BuildContext context) async {
    final link = photo.pageUrl.isNotEmpty ? photo.pageUrl : photo.fullUrl;
    try {
      await SharePlus.instance.share(
        ShareParams(text: 'Photo by ${photo.photographer} on Pexels\n$link'),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the share sheet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;

    // Photo height follows the photo's own shape, kept between a sensible
    // minimum and 68% of the screen so very tall photos don't push the
    // actions off screen.
    final imageHeight = math.min(
      math.max(size.width / photo.aspectRatio, 240.0),
      size.height * 0.68,
    );

    final initial = photo.photographer.isNotEmpty
        ? photo.photographer[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: heroTag,
                  child: SizedBox(
                    width: double.infinity,
                    height: imageHeight,
                    child: CachedNetworkImage(
                      imageUrl: photo.fullUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 250),
                      // The small version is already cached from the grid, so
                      // the screen never opens on a blank rectangle.
                      placeholder: (context, url) => CachedNetworkImage(
                        imageUrl: photo.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => ColoredBox(
                          color: colorFromHex(photo.averageColor),
                        ),
                      ),
                      errorWidget: (context, url, error) => ColoredBox(
                        color: colorFromHex(photo.averageColor),
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: p.primary,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: p.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photo.photographer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: p.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Photographer on Pexels',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          SaveButton(photo: photo, compact: false),
                          const SizedBox(width: 12),
                          _ShareButton(onTap: () => _share(context)),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Photo details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        photo.alt,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: p.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: '${photo.width} × ${photo.height}'),

                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 12,
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: p.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.ios_share, size: 20, color: p.textPrimary),
                const SizedBox(width: 8),
                Text(
                  'Share',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color? dot;

  const _InfoChip({required this.label, this.dot});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(fontSize: 13, color: p.textSecondary)),
        ],
      ),
    );
  }
}