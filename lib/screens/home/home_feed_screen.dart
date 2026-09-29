import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/theme.dart';
import '../../models/photo.dart';
import '../../services/pexels_service.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/photo_tile.dart';
import '../../widgets/state_views.dart';

/// Home tab: curated Pexels photos in a masonry grid with infinite scroll,
/// pull-to-refresh, and loading / empty / error states.
class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final _service = PexelsService();
  final _scrollController = ScrollController();

  /// Ids of tiles that have already played their entrance animation, so a
  /// tile that scrolls away and back doesn't animate again.
  final Set<int> _animatedIds = <int>{};

  List<Photo> _photos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  /// Bumped on every full (re)load. A "load more" that started before a
  /// refresh checks this and throws its result away instead of appending
  /// stale pages to the fresh list.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final photos = await _service.getCuratedPhotos(page: 1);
      if (!mounted) return;
      setState(() {
        _generation++;
        _photos = photos;
        _page = 1;
        _hasMore = photos.isNotEmpty;
        _isLoading = false;
        _isLoadingMore = false;
        _loadMoreFailed = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (isRefresh && _photos.isNotEmpty) {
        // Keep what's on screen; just tell the user the refresh failed.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh. Check your connection.')),
        );
      } else {
        setState(() {
          _error = 'Could not load photos.\nCheck your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final nearBottom = position.pixels >= position.maxScrollExtent - 600;
    if (nearBottom &&
        _hasMore &&
        !_isLoading &&
        !_isLoadingMore &&
        !_loadMoreFailed) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    final generation = _generation;

    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    try {
      final more = await _service.getCuratedPhotos(page: _page + 1);
      if (!mounted || generation != _generation) return;

      final existing = _photos.map((p) => p.id).toSet();
      final fresh = more.where((p) => !existing.contains(p.id)).toList();

      setState(() {
        _photos = [..._photos, ...fresh];
        _page += 1;
        _hasMore = more.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      // Keep the photos already shown; offer a small retry instead.
      setState(() {
        _isLoadingMore = false;
        _loadMoreFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'XYZ', serif: true),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final p = AppPalette.of(context);

    if (_isLoading) return const LoadingView();

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () => _loadInitial());
    }

    if (_photos.isEmpty) {
      return EmptyView(
        icon: Icons.photo_library_outlined,
        title: 'No photos right now',
        message: 'There is nothing to show yet.',
        actionLabel: 'Refresh',
        onAction: () => _loadInitial(),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _loadInitial(isRefresh: true),
          color: p.primary,
          backgroundColor: p.card,
          child: MasonryGridView.count(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              // add() returns true only the first time an id is seen.
              final firstTime = _animatedIds.add(photo.id);
              return FadeSlideIn(
                key: ValueKey(photo.id),
                animate: firstTime,
                delay: Duration(milliseconds: (index % 6) * 50),
                child: PhotoTile(photo: photo, heroTag: 'home-${photo.id}'),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_buildFooter(p)],
          ),
        ),
      ],
    );
  }

  /// Floats over the bottom of the grid, so showing / hiding it never shifts
  /// the layout.
  Widget _buildFooter(AppPalette p) {
    if (_isLoadingMore) {
      return Material(
        elevation: 2,
        color: p.card,
        shape: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (_loadMoreFailed) {
      return ElevatedButton.icon(
        onPressed: _loadMore,
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text("Couldn't load more. Retry"),
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          shape: const StadiumBorder(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}