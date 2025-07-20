import 'news_priority.dart';
import 'news_type.dart';
import 'package:intl/intl.dart';

class NewsHistoryDTO {
  final int newsId;
  final String title;
  final String? image;
  final String viewedAt;  // LocalDateTime in backend, we'll handle as String in Dart
  final NewsType type;
  final NewsPriority priority;

  NewsHistoryDTO({
    required this.newsId,
    required this.title,
    this.image,
    required this.viewedAt,
    required this.type,
    required this.priority,
  });

  factory NewsHistoryDTO.fromJson(Map<String, dynamic> json) {
    return NewsHistoryDTO(
      newsId: json['newsId'],
      title: json['title'],
      image: json['image'],
      viewedAt: json['viewedAt'],
      type: NewsTypeExtension.fromString(json['type'] ?? 'DUYURU'),
      priority: NewsPriorityExtension.fromString(json['priority'] ?? 'NORMAL'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newsId': newsId,
      'title': title,
      'image': image,
      'viewedAt': viewedAt,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
    };
  }
  
  // Format the viewedAt date to a user-friendly string
  String get formattedDate {
    try {
      // Parse the ISO 8601 date string
      DateTime dateTime = DateTime.parse(viewedAt);
      
      // Format the date based on the locale
      final formatter = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR');
      return formatter.format(dateTime);
    } catch (e) {
      // Return the original string if there's a parsing error
      return viewedAt;
    }
  }
}
