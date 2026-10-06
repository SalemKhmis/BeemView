/// Generic paginated response wrapper.
///
/// The projects endpoint returns:
/// ```json
/// {"total": 1, "count": 1, "limit": 10, "offset": 0, "data": [...]}
/// ```
/// An empty result may instead be:
/// ```json
/// {"result": [], "count": 0}
/// ```
/// This class handles both envelopes transparently.
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int count;
  final int limit;
  final int offset;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.count,
    required this.limit,
    required this.offset,
  });

  /// Whether there are more items available beyond the current page.
  bool get hasMore => offset + count < total;

  /// The offset to use for loading the next page.
  int get nextOffset => offset + limit;

  /// Parses a paginated response from JSON.
  ///
  /// [fromJson] converts each item in the data array to type [T].
  /// Handles both `data` and `result` response envelopes.
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    // Handle both "data" and "result" envelopes
    final List<dynamic> rawItems =
        (json['data'] as List<dynamic>?) ??
        (json['result'] as List<dynamic>?) ??
        [];

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();

    final count = json['count'] as int? ?? items.length;
    final total = json['total'] as int? ?? count;
    final limit = json['limit'] as int? ?? items.length;
    final offset = json['offset'] as int? ?? 0;

    return PaginatedResponse(
      items: items,
      total: total,
      count: count,
      limit: limit,
      offset: offset,
    );
  }
}
