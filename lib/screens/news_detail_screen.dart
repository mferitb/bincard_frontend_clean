import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/news/user_news_dto.dart';
import '../models/news/news_type.dart';
import '../models/news/news_priority.dart';
import '../services/news_service.dart';
import '../widgets/video_player_widget.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../constants/api_constants.dart';

class NewsDetailScreen extends StatefulWidget {
  final UserNewsDTO news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _isLiked = false;
  bool _showFullVideo = false;
  bool _isLiking = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.news.likedByUser ?? false;
    _likeCount = widget.news.likeCount;
    
    // Yerel görüntülenme sayısını artır (UI için)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        final newsService = NewsService();
        final updatedNews = newsService.incrementLocalViewCount(widget.news);
        // This is a bit of a hack since widget.news is final
        // In a real app, you'd use state management (Provider, Bloc, etc.)
        (widget.news as dynamic).viewCount = updatedNews.viewCount;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('tr_TR', null);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white), // Geri dönüş butonunu beyaz yap
        title: const Text(
          'Haber Detayı', 
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          )
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video oynatma alanı
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildVideoSection(),
            ),
            
            // Etiketler ve beğen/paylaş butonları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sol tarafta kategori etiketleri
                  Expanded(
                    child: _buildCategoryTags(),
                  ),
                  
                  // Sağ tarafta görüntülenme, beğeni ve paylaş butonları
                  Row(
                    children: [
                      // Görüntülenme sayısı
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${widget.news.viewCount}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      
                      // Beğeni sayısı
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$_likeCount",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      
                      // Beğen butonu
                      _isLiking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            onPressed: _handleLikeButton,
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_outline,
                              color: _isLiked ? Colors.red : Colors.grey,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                      const SizedBox(width: 12),
                      
                      // Paylaş butonu
                      IconButton(
                        onPressed: () => _shareNews(widget.news),
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.grey,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tarih
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Text(
                _formatDate(widget.news.createdAt ?? DateTime.now()),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Başlık ve içerik
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Text(
                    widget.news.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202020),
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Özet kaldırıldı
                  
                  // Ana içerik
                  Text(
                    widget.news.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimaryColor,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    final bool hasVideo = widget.news.videoUrl != null && widget.news.videoUrl!.isNotEmpty;
    final bool hasImage = widget.news.image != null && widget.news.image!.isNotEmpty;
    final bool hasThumbnail = widget.news.thumbnailUrl != null && widget.news.thumbnailUrl!.isNotEmpty;
    
    // Sadece video/resim alanı, hiçbir ek öğe içermiyor
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildMediaContent(hasVideo, hasImage, hasThumbnail),
      ),
    );
  }

  Widget _buildMediaContent(bool hasVideo, bool hasImage, bool hasThumbnail) {
    // Medya içeriği yoksa boş container döndür
    if (!hasVideo && !hasImage && !hasThumbnail) {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            _getCategoryIcon(widget.news.type),
            size: 48,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    // Video gösterilecekse
    if (_showFullVideo && hasVideo) {
      return VideoPlayerWidget(
        videoUrl: widget.news.videoUrl!,
        autoPlay: true,
        looping: false,
        showControls: true,
        fitToScreen: true,
        showCloseButton: true,
        showFullscreenButton: true,
        onClosePressed: () => setState(() {
          _showFullVideo = false;
        }),
        onFullscreenPressed: () => _showVideoFullscreen(),
      );
    }
    
    // Video var ama oynatılmıyorsa thumbnail göster
    if (hasVideo && hasThumbnail) {
      return GestureDetector(
        onTap: () => setState(() {
          _showFullVideo = true;
        }),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Thumbnail
            SizedBox(
              width: double.infinity,
              height: 220,
              child: Image.network(
                widget.news.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            
            // Video oynat butonu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
      );
    }
    
    // Sadece resim varsa
    if (hasImage) {
      return SizedBox(
        width: double.infinity,
        height: 220,
        child: Image.network(
          widget.news.image!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              ),
            );
          },
        ),
      );
    }
    
    // Video var ama thumbnail yoksa
    if (hasVideo) {
      return SizedBox(
        width: double.infinity,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: Colors.grey[200],
              width: double.infinity,
              height: 220,
            ),
            GestureDetector(
              onTap: () => setState(() {
                _showFullVideo = true;
              }),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildCategoryTags() {
    final bool isImportant = widget.news.priority == NewsPriority.YUKSEK || 
                          widget.news.priority == NewsPriority.COK_YUKSEK ||
                          widget.news.priority == NewsPriority.KRITIK;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Kategori etiketi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor(widget.news.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _getCategoryName(widget.news.type),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getCategoryColor(widget.news.type),
            ),
          ),
        ),
        
        // Önemli etiketi
        if (isImportant)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 12,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Önemli',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'tr_TR');
    return formatter.format(date);
  }

  IconData _getCategoryIcon(NewsType type) {
    switch (type) {
      case NewsType.DUYURU:
        return Icons.campaign;
      case NewsType.KAMPANYA:
        return Icons.engineering;
      case NewsType.BAKIM:
        return Icons.trending_up;
      case NewsType.BILGILENDIRME:
        return Icons.devices;
      case NewsType.GUNCELLEME:
        return Icons.support_agent;
      default:
        return Icons.article;
    }
  }

  Color _getCategoryColor(NewsType type) {
    switch (type) {
      case NewsType.DUYURU:
        return AppTheme.primaryColor;
      case NewsType.KAMPANYA:
        return AppTheme.infoColor;
      case NewsType.BAKIM:
        return AppTheme.successColor;
      case NewsType.BILGILENDIRME:
        return AppTheme.accentColor;
      case NewsType.GUNCELLEME:
        return Colors.purple;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  String _getCategoryName(NewsType type) {
    return type.name;
  }

  void _shareNews(UserNewsDTO news) {
    const int maxContentLength = 250;
    
    final String truncatedContent = news.content.length > maxContentLength 
      ? '${news.content.substring(0, maxContentLength)}...' 
      : news.content;
    
    String shareContent = """
📰 ${news.title}

$truncatedContent
""";

    final String appDeepLink = "bincard://news-detail?id=${news.id}";
    shareContent += "\n\n📱 Haberin tamamını görmek için tıklayın: $appDeepLink";

    final String webUrl = "${ApiConstants.newsWebBaseUrl}/news/${news.id}";
    shareContent += "\n🌐 Web: $webUrl";

    shareContent += "\n\n📊 Şehir Kartım uygulamasından paylaşıldı";

    Share.share(
      shareContent,
      subject: news.title,
    );
  }

  // Videoyu tam ekran gösterme fonksiyonu
  void _showVideoFullscreen() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: 16/9, // Video için standart aspect ratio
            child: VideoPlayerWidget(
              videoUrl: widget.news.videoUrl!,
              autoPlay: true,
              looping: false,
              showControls: true,
              fitToScreen: true,
              showCloseButton: true,
              onClosePressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLikeButton() async {
    setState(() => _isLiking = true);
    final newsService = NewsService();
    bool success;
    if (_isLiked) {
      success = await newsService.unlikeNews(widget.news.id);
    } else {
      success = await newsService.likeNews(widget.news.id);
    }
    setState(() {
      if (success) {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiked ? 'Haber beğenildi' : 'Beğeni kaldırıldı'),
            backgroundColor: _isLiked ? Colors.red : Colors.grey,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _isLiking = false;
    });
  }
}
