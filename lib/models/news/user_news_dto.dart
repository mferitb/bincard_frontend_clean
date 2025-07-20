import 'news_priority.dart';
import 'news_type.dart';
import 'package:flutter/foundation.dart';

class UserNewsDTO {
  final int id;
  final String title;
  final String content;
  final String? image;
  final String? videoUrl;
  final String? thumbnailUrl; // Video için kapak fotoğrafı
  final bool likedByUser;
  final bool viewedByUser;
  final NewsPriority priority;
  final NewsType type;
  final DateTime? createdAt;
  final String? summary;
  final int viewCount;
  final int likeCount;

  UserNewsDTO({
    required this.id,
    required this.title,
    required this.content,
    this.image,
    this.videoUrl,
    this.thumbnailUrl,
    required this.likedByUser,
    required this.viewedByUser,
    required this.priority,
    required this.type,
    this.createdAt,
    this.summary,
    this.viewCount = 0,
    this.likeCount = 0,
  });

  factory UserNewsDTO.fromJson(Map<String, dynamic> json) {
    try {
      String? imageUrl;
      String? videoUrl;
      String? thumbnailUrl;
      int viewCount = 0;
      int likeCount = 0;
      
      // Debug logging
      debugPrint('🔍 Parsing news item:  [1m${json['id']} - ${json['title']}');
      
      // Image alanını kontrol et
      final imageField = json['image'];
      
      if (imageField != null && imageField is String && imageField.isNotEmpty) {
        // Eğer URL video formatında ise (.mp4, .mov, .avi, .webm vb.)
        if (_isVideoUrl(imageField)) {
          videoUrl = _optimizeVideoUrl(imageField);
          thumbnailUrl = _generateThumbnailUrl(imageField); // Video için thumbnail oluştur
          imageUrl = null; // Video ise image olarak gösterme
        } else {
          imageUrl = imageField;
          videoUrl = null;
        }
      }
      
      // Ayrıca ayrı videoUrl alanı varsa onu kullan
      if (json['videoUrl'] != null && json['videoUrl'].toString().isNotEmpty) {
        videoUrl = _optimizeVideoUrl(json['videoUrl']);
        if (thumbnailUrl == null) {
          thumbnailUrl = _generateThumbnailUrl(json['videoUrl']);
        }
      } else if (json['video_url'] != null && json['video_url'].toString().isNotEmpty) {
        videoUrl = _optimizeVideoUrl(json['video_url']);
        if (thumbnailUrl == null) {
          thumbnailUrl = _generateThumbnailUrl(json['video_url']);
        }
      } else if (json['video'] != null && json['video'].toString().isNotEmpty) {
        videoUrl = _optimizeVideoUrl(json['video']);
        if (thumbnailUrl == null) {
          thumbnailUrl = _generateThumbnailUrl(json['video']);
        }
      }
      
      // Açıkça tanımlanmış thumbnail alanı varsa onu kullan
      if (json['thumbnailUrl'] != null && json['thumbnailUrl'].toString().isNotEmpty) {
        thumbnailUrl = json['thumbnailUrl'];
      } else if (json['thumbnail_url'] != null && json['thumbnail_url'].toString().isNotEmpty) {
        thumbnailUrl = json['thumbnail_url'];
      } else if (json['thumbnail'] != null && json['thumbnail'].toString().isNotEmpty) {
        thumbnailUrl = json['thumbnail'];
      }
      
      // viewCount ve likeCount alanlarını kontrol et
      if (json['viewCount'] != null) {
        viewCount = json['viewCount'] is int ? json['viewCount'] : int.tryParse(json['viewCount'].toString()) ?? 0;
      } else if (json['view_count'] != null) {
        viewCount = json['view_count'] is int ? json['view_count'] : int.tryParse(json['view_count'].toString()) ?? 0;
      }
      
      if (json['likeCount'] != null) {
        likeCount = json['likeCount'] is int ? json['likeCount'] : int.tryParse(json['likeCount'].toString()) ?? 0;
      } else if (json['like_count'] != null) {
        likeCount = json['like_count'] is int ? json['like_count'] : int.tryParse(json['like_count'].toString()) ?? 0;
      }
      
      // Debug için view count ve like count bilgilerini yazdır
      debugPrint('📊 Haber ${json['id']} görüntülenme: $viewCount, beğeni: $likeCount');
      
      // datetime alanını kontrol et
      DateTime? createdAt;
      if (json['createdAt'] != null) {
        createdAt = DateTime.tryParse(json['createdAt']);
      } else if (json['date'] != null) {
        createdAt = DateTime.tryParse(json['date']);
      } else if (json['created_at'] != null) {
        createdAt = DateTime.tryParse(json['created_at']);
      } else {
        createdAt = DateTime.now(); // Varsayılan tarih
      }
      
      return UserNewsDTO(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        image: imageUrl,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        likedByUser: json['likedByUser'] ?? false,
        viewedByUser: json['viewedByUser'] ?? false,
        priority: NewsPriorityExtension.fromString(json['priority'] ?? 'NORMAL'),
        type: NewsTypeExtension.fromString(json['type'] ?? 'DUYURU'),
        createdAt: createdAt,
        summary: json['summary'],
        viewCount: viewCount,
        likeCount: likeCount,
      );
    } catch (e, stack) {
      debugPrint('❌ UserNewsDTO parse hatası: $e\n$stack');
      rethrow;
    }
  }
  
  // Video URL olup olmadığını kontrol eden yardımcı fonksiyon
  static bool _isVideoUrl(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.webm', '.mkv', '.flv', '.wmv', '.m4v'];
    final lowerUrl = url.toLowerCase();
    
    // Cloudinary video URL pattern kontrolü
    if (lowerUrl.contains('cloudinary.com') && lowerUrl.contains('/video/')) {
      return true;
    }
    
    // Dosya uzantısı kontrolü
    return videoExtensions.any((ext) => lowerUrl.contains(ext));
  }

  // Video URL'sini optimize eden fonksiyon
  static String _optimizeVideoUrl(String url) {
    if (url.contains('cloudinary.com') && url.contains('/video/upload/')) {
      // Cloudinary video URL'sini optimize et
      String optimizedUrl = url.replaceAll('/video/upload/', '/video/upload/f_mp4,q_auto/');
      
      // .mp4 uzantısı yoksa ekle
      if (!optimizedUrl.toLowerCase().endsWith('.mp4')) {
        optimizedUrl = '$optimizedUrl.mp4';
      }
      
      return optimizedUrl;
    }
    
    return url;
  }
  
  // Video URL'sinden thumbnail URL'si oluşturan fonksiyon
  static String? _generateThumbnailUrl(String videoUrl) {
    if (videoUrl.isEmpty) return null;
    
    // Cloudinary video URL'inden thumbnail oluştur
    if (videoUrl.contains('cloudinary.com') && videoUrl.contains('/video/')) {
      // Video URL'sini thumbnail URL'sine dönüştür
      String thumbnailUrl = videoUrl
          .replaceAll('/video/upload/', '/video/upload/f_jpg,w_640,h_360,c_fill,g_auto,q_auto,so_0/');
      
      // Uzantıyı değiştir
      thumbnailUrl = thumbnailUrl.replaceAll(RegExp(r'\.(mp4|mov|avi|webm|mkv|flv|wmv|m4v)$'), '.jpg');
      
      // Eğer dosya uzantısı yoksa .jpg ekle
      if (!thumbnailUrl.toLowerCase().endsWith('.jpg')) {
        thumbnailUrl = '$thumbnailUrl.jpg';
      }
      
      return thumbnailUrl;
    }
    
    // YouTube, Vimeo gibi diğer video servisleri için thumbnail mantığı eklenebilir
    
    return null;
  }

  // Tarih, özet gibi ek alanlar olmadığında ekran içinde kullanmak için
  DateTime get date => createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image': image,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'likedByUser': likedByUser,
      'viewedByUser': viewedByUser,
      'priority': priority.toString().split('.').last,
      'type': type.toString().split('.').last,
      'createdAt': createdAt?.toIso8601String(),
      'summary': summary,
      'viewCount': viewCount,
      'likeCount': likeCount,
    };
  }
}
