import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../providers/saved_provider.dart';
import '../../widgets/photo_tile.dart';
import '../../widgets/state_views.dart';

/// Saved tab: the signed-in user's saved photos.
///
/// Watches [SavedProvider], so a photo saved or removed on any other screen
/// appears / disappears here immediately.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedProvider>();
    final count = saved.count;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: 'Saved',
            subtitle:
            count == 0 ? null : '$count ${count == 1 ? 'photo' : 'photos'}',
          ),
          Expanded(child: _buildBody(saved)),
        ],
      ),
    );
  }

  Widget _buildBody(SavedProvider saved) {
    if (saved.photos.isEmpty) {
      if (saved.isLoading) return const LoadingView();
      if (saved.error != null) {
        return ErrorView(message: saved.error!, onRetry: saved.retry);
      }
      return const EmptyView(
        icon: Icons.bookmark_border,
        title: 'Nothing saved yet',
        message: 'Tap the bookmark on any photo to keep it here.',
      );
    }

    return MasonryGridView.count(
      // Several tabs are alive at once, so this must not grab the route's
      // primary scroll controller.
      primary: false,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: saved.photos.length,
      itemBuilder: (context, index) {
        final photo = saved.photos[index];
        return PhotoTile(
          key: ValueKey(photo.id),
          photo: photo,
          heroTag: 'saved-${photo.id}',
        );
      },
    );
  }
}