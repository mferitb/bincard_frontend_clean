import 'user_news_dto.dart';

class NewsPage {
  final List<UserNewsDTO> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool isFirst;
  final bool isLast;

  NewsPage({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.isFirst,
    required this.isLast,
  });

  factory NewsPage.fromJson(Map<String, dynamic> json) {
    final contentList = (json['content'] as List?)
        ?.map((item) => UserNewsDTO.fromJson(item))
        .toList() ?? [];

    return NewsPage(
      content: contentList,
      pageNumber: json['pageNumber'] ?? 0,
      pageSize: json['pageSize'] ?? 20,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      isFirst: json['first'] ?? true,
      isLast: json['last'] ?? true,
    );
  }

  // Empty page constructor for fallback cases
  factory NewsPage.empty() {
    return NewsPage(
      content: [],
      pageNumber: 0,
      pageSize: 20,
      totalElements: 0,
      totalPages: 0,
      isFirst: true,
      isLast: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.map((e) => e.toJson()).toList(),
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      'totalElements': totalElements,
      'totalPages': totalPages,
      'first': isFirst,
      'last': isLast,
    };
  }
}
