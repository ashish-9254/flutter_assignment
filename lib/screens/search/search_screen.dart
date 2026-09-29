import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/photo.dart';
import '../../services/pexels_service.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/photo_tile.dart';
import '../../widgets/state_views.dart';

/// Search tab. The query is sent only after the user stops typing for
/// [_debounceDuration].
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const List<String> _suggestions = [
    'Nature',
    'Architecture',
    'Travel',
    'Food',
    'Animals',
    'Ocean',
  ];

  final _service = PexelsService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<int> _animatedIds = <int>{};

  Timer? _debounce;

  /// Every search gets a new id. When a response arrives we only use it if
  /// its id is still the latest. Otherwise a slow response for "cat" could
  /// overwrite the results for "cats" that the user typed afterwards.
  int _requestId = 0;

  String _query = '';
  List<Photo> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  bool _hasMore = false;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // refreshes the clear (x) button
    _debounce?.cancel();

    final query = value.trim();
    if (query.isEmpty) {
      _reset();
      return;
    }
    if (query == _query && _error == null) return;

    _debounce = Timer(_debounceDuration, () => _search(query));
  }

  void _onSubmitted(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isNotEmpty) _search(query);
  }

  void _clear() {
    _debounce?.cancel();
    _textController.clear();
    _reset();
  }

  void _useSuggestion(String suggestion) {
    _debounce?.cancel();
    _textController.text = suggestion;
    _textController.selection =
        TextSelection.collapsed(offset: suggestion.length);
    FocusManager.instance.primaryFocus?.unfocus();
    _search(suggestion);
  }

  void _reset() {
    _requestId++;
    setState(() {
      _query = '';
      _results = [];
      _isLoading = false;
      _isLoadingMore = false;
      _loadMoreFailed = false;
      _hasMore = false;
      _error = null;
    });
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;

    setState(() {
      _query = query;
      _results = [];
      _page = 1;
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreFailed = false;
      _hasMore = false;
      _error = null;
    });

    try {
      final results = await _service.searchPhotos(query, page: 1);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _hasMore = results.length >= PexelsApi.defaultPerPage;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = 'Could not load results.\nCheck your connection and try again.';
        _isLoading = false;
      });
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
    final id = _requestId;

    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    try {
      final more = await _service.searchPhotos(_query, page: _page + 1);
      if (!mounted || id != _requestId) return;

      final existing = _results.map((p) => p.id).toSet();
      final fresh = more.where((p) => !existing.contains(p.id)).toList();

      setState(() {
        _results = [..._results, ...fresh];
        _page += 1;
        _hasMore = more.length >= PexelsApi.defaultPerPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _isLoadingMore = false;
        _loadMoreFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeader(title: 'Search'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _textController,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: p.primary,
              style: TextStyle(color: p.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search photos',
                hintStyle: TextStyle(color: p.textSecondary),
                filled: true,
                fillColor: p.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: Icon(Icons.search, color: p.textSecondary),
                suffixIcon: _textController.text.isEmpty
                    ? null
                    : IconButton(
                  icon: Icon(Icons.close, color: p.textSecondary),
                  onPressed: _clear,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: p.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: p.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: p.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(p)),
        ],
      ),
    );
  }

  Widget _buildBody(AppPalette p) {
    if (_query.isEmpty) return _buildIdle(p);
    if (_isLoading) return const LoadingView();
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () => _search(_query));
    }
    if (_results.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        title: 'No results',
        message: 'Nothing found for "$_query". Try a different word.',
      );
    }

    return Stack(
      children: [
        MasonryGridView.count(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final photo = _results[index];
            final firstTime = _animatedIds.add(photo.id);
            return FadeSlideIn(
              key: ValueKey(photo.id),
              animate: firstTime,
              delay: Duration(milliseconds: (index % 6) * 50),
              child: PhotoTile(photo: photo, heroTag: 'search-${photo.id}'),
            );
          },
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

  /// Shown before anything has been searched.
  Widget _buildIdle(AppPalette p) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try searching for',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s),
                  onPressed: () => _useSuggestion(s),
                  backgroundColor: p.card,
                  side: BorderSide(color: p.border),
                  labelStyle: TextStyle(color: p.textPrimary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}