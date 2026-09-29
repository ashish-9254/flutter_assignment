/// Pexels API configuration that isn't secret — safe to commit to git.
/// The actual API key lives in env.dart, which is gitignored.
class PexelsApi {
  // Every Pexels endpoint starts with this base.
  static const String baseUrl = 'https://api.pexels.com/v1';

  // "Curated" is Pexels' term for their hand-picked, general-purpose
  // photo feed — this is what populates the Home Feed screen.
  static const String curatedEndpoint = '$baseUrl/curated';

  // Appending a query string (?query=mountains) to this is how search works.
  static const String searchEndpoint = '$baseUrl/search';

  // How many photos to request per API call. Pexels paginates results,
  // so this also controls how many photos load each time the user
  // scrolls near the bottom of the feed.
  static const int defaultPerPage = 20;
}