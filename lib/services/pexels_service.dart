import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/env.dart';
import '../models/photo.dart';

/// The only file that knows Pexels' HTTP + JSON details. Everything else just
/// receives `List<Photo>`.
class PexelsService {
  /// Without a timeout a dead connection can leave a spinner up for a very
  /// long time. After this the call throws and the UI shows its error state.
  static const Duration _timeout = Duration(seconds: 15);

  Future<List<Photo>> getCuratedPhotos({int page = 1}) {
    final uri = Uri.parse(PexelsApi.curatedEndpoint).replace(
      queryParameters: {
        'per_page': '${PexelsApi.defaultPerPage}',
        'page': '$page',
      },
    );
    return _fetchPhotos(uri);
  }

  Future<List<Photo>> searchPhotos(String query, {int page = 1}) {
    // Uri.replace(queryParameters:) URL-encodes the query for us, so
    // "mountain lake" or "café" are safe.
    final uri = Uri.parse(PexelsApi.searchEndpoint).replace(
      queryParameters: {
        'query': query,
        'per_page': '${PexelsApi.defaultPerPage}',
        'page': '$page',
      },
    );
    return _fetchPhotos(uri);
  }

  Future<List<Photo>> _fetchPhotos(Uri uri) async {
    final response = await http
        .get(uri, headers: {'Authorization': pexelsApiKey})
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Pexels request failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawPhotos = body['photos'] as List<dynamic>? ?? const [];

    return rawPhotos
        .map((json) => Photo.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}