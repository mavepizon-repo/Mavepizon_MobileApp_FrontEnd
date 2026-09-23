import 'dart:math' as math;

/// Lightweight parser for Spring Data `Page` JSON payloads:
/// `{ content, totalPages, totalElements, number, size, ... }`.
///
/// It also gracefully handles plain `List` payloads so unpaginated
/// endpoints keep working after the backend switched to pages.
class PaginationData {
  final List<dynamic> content;
  final int page;
  final int totalPages;
  final int totalElements;
  final int size;

  const PaginationData({
    this.content = const [],
    this.page = 0,
    this.totalPages = 1,
    this.totalElements = 0,
    this.size = 20,
  });

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;

  /// 1-based index of the first item shown on the current page.
  int get firstItem => totalElements == 0 ? 0 : page * size + 1;

  /// 1-based index of the last item shown on the current page.
  int get lastItem =>
      totalElements == 0 ? 0 : math.min(totalElements, page * size + size);

  /// Maps the raw page content to a typed list.
  List<T> map<T>(T Function(dynamic raw) mapper) => content.map(mapper).toList();

  /// Parses either a Spring `Page` map or a plain list.
  static PaginationData parse(dynamic raw) {
    if (raw is Map) {
      final content = raw['content'];
      return PaginationData(
        content: content is List ? content : const [],
        page: _toInt(raw['number']) ?? 0,
        totalPages: _toInt(raw['totalPages']) ?? 1,
        totalElements: _toInt(raw['totalElements']) ?? 0,
        size: _toInt(raw['size']) ?? _toInt(raw['pageSize']) ?? 20,
      );
    }
    if (raw is List) {
      return PaginationData(
        content: raw,
        page: 0,
        totalPages: 1,
        totalElements: raw.length,
        size: raw.length == 0 ? 20 : raw.length,
      );
    }
    return const PaginationData();
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}