/// A single photo from Pexels, trimmed to the fields this app uses.
///
/// Every screen, provider and widget talks in terms of this class. Raw JSON
/// only exists inside [Photo.fromJson] (API responses) and
/// [Photo.fromSavedMap] (Firestore documents).
class Photo {
  final int id;
  final int width;
  final int height;
  final String photographer;
  final String photographerUrl;

  /// The photo's page on pexels.com (used when sharing).
  final String pageUrl;
  final String averageColor;
  final String alt;

  /// Small image for grids.
  final String thumbnailUrl;

  /// Large image for the detail screen.
  final String fullUrl;

  const Photo({
    required this.id,
    required this.width,
    required this.height,
    required this.photographer,
    required this.photographerUrl,
    required this.pageUrl,
    required this.averageColor,
    required this.alt,
    required this.thumbnailUrl,
    required this.fullUrl,
  });

  /// width / height. The masonry grid uses this so every tile keeps the
  /// shape of its photo.
  double get aspectRatio {
    if (width <= 0 || height <= 0) return 1;
    return width / height;
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    final src =
        (json['src'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final photographer = (json['photographer'] as String?) ?? 'Unknown';
    final alt = ((json['alt'] as String?) ?? '').trim();

    return Photo(
      id: (json['id'] as num).toInt(),
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      photographer: photographer,
      photographerUrl: (json['photographer_url'] as String?) ?? '',
      pageUrl: (json['url'] as String?) ?? '',
      averageColor: (json['avg_color'] as String?) ?? '#CCCCCC',
      alt: alt.isNotEmpty ? alt : 'Photo by $photographer',
      thumbnailUrl:
      (src['medium'] as String?) ?? (src['large'] as String?) ?? '',
      fullUrl: (src['large2x'] as String?) ??
          (src['large'] as String?) ??
          (src['original'] as String?) ??
          '',
    );
  }

  /// Rebuilds a photo from a Firestore "saved" document.
  factory Photo.fromSavedMap(Map<String, dynamic> map) {
    return Photo(
      id: (map['id'] as num).toInt(),
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      photographer: (map['photographer'] as String?) ?? 'Unknown',
      photographerUrl: (map['photographerUrl'] as String?) ?? '',
      pageUrl: (map['pageUrl'] as String?) ?? '',
      averageColor: (map['averageColor'] as String?) ?? '#CCCCCC',
      alt: (map['alt'] as String?) ?? '',
      thumbnailUrl: (map['thumbnailUrl'] as String?) ?? '',
      fullUrl: (map['fullUrl'] as String?) ?? '',
    );
  }

  /// What we store in Firestore. We keep the display data (not just the id)
  /// so the Saved screen renders without calling Pexels again.
  Map<String, dynamic> toSavedMap() {
    return {
      'id': id,
      'width': width,
      'height': height,
      'photographer': photographer,
      'photographerUrl': photographerUrl,
      'pageUrl': pageUrl,
      'averageColor': averageColor,
      'alt': alt,
      'thumbnailUrl': thumbnailUrl,
      'fullUrl': fullUrl,
    };
  }

  @override
  bool operator ==(Object other) => other is Photo && other.id == id;

  @override
  int get hashCode => id.hashCode;
}