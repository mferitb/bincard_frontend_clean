import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/news/user_news_dto.dart';
import '../models/news/news_type.dart';
import '../models/news/news_priority.dart';
import '../models/news/platform_type.dart';
import '../services/news_service.dart';
import '../services/api_service.dart';
import '../widgets/video_player_widget.dart';
import 'news_detail_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math';
import 'news_detail_from_id_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/api_constants.dart';

// Video oynatma durumunu takip eden sınıf
class VideoPlayState {
  final String newsId;  // Hangi habere ait
  bool isPlaying;      // Video oynatılıyor mu?

  VideoPlayState({required this.newsId, this.isPlaying = false});
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<UserNewsDTO> _allNews = [];
  
  // Video oynatma durumunu takip etmek için map
  Map<int, VideoPlayState> _videoPlayStates = {};
  
  // Video oynatma durumunu değiştiren fonksiyon
  void _toggleVideoPlay(UserNewsDTO news) {
    // Video URL'sinin geçerli olup olmadığını kontrol et
    if (news.videoUrl == null || news.videoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu haber için video bulunamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      if (_videoPlayStates.containsKey(news.id)) {
        // Mevcut durumu tersine çevir
        _videoPlayStates[news.id]!.isPlaying = !_videoPlayStates[news.id]!.isPlaying;
      } else {
        // Yeni oynatma durumu oluştur
        _videoPlayStates[news.id] = VideoPlayState(newsId: news.id.toString(), isPlaying: true);
      }
    });
    
    // Video oynatma durumu loglanıyor
    if (_videoPlayStates[news.id]!.isPlaying) {
      print('📹 Video oynatma başlatıldı: ${news.title}');
    } else {
      print('📹 Video oynatma durduruldu: ${news.title}');
    }
  }
  
  // Video oynatma durumunu kontrol eden getter
  bool isVideoPlaying(int newsId) {
    return _videoPlayStates.containsKey(newsId) && _videoPlayStates[newsId]!.isPlaying;
  }
  
  // Video oynatma durumunu sıfırlayan fonksiyon
  void _resetVideoPlayState(int newsId) {
    setState(() {
      _videoPlayStates.remove(newsId);
    });
  }
  
  // Haberi paylaşma fonksiyonu
  void _shareNews(UserNewsDTO news) {
    // Paylaşım içeriğini hazırla
    String shareContent = """
${news.title}

${news.content}
""";

    // Uygulama deep link URL'i oluştur
    final String appDeepLink = "bincard://news-detail?id=${news.id}";
    
    // Deep link bilgisini ekle
    shareContent += "\n\nHaberi uygulamada görüntülemek için tıklayın: $appDeepLink";
    
    // Alternatif olarak web sayfası linki
    final String webUrl = "${ApiConstants.newsWebBaseUrl}/news/${news.id}";
    shareContent += "\nveya web sitesinde görüntüleyin: $webUrl";
    
    // Uygulama bilgisi ekle
    shareContent += "\n\nBincard uygulamasından paylaşıldı.";
    
    // Paylaşım seçeneklerini göster
    Share.share(
      shareContent,
      subject: news.title,
    ).then((result) {
      print('📤 Haber paylaşıldı: ${news.title}');
    }).catchError((error) {
      print('❌ Paylaşım hatası: $error');
    });
  }
  
  // Filtrelenmiş haber listeleri için getter'lar
  List<UserNewsDTO> get _importantNews => _allNews
      .where((news) => news.priority == NewsPriority.YUKSEK || 
                        news.priority == NewsPriority.COK_YUKSEK ||
                        news.priority == NewsPriority.KRITIK)
      .toList();
  List<UserNewsDTO> get _announcements => _allNews
      .where((news) => news.type == NewsType.DUYURU)
      .toList();
  List<UserNewsDTO> get _projects => _allNews
      .where((news) => news.type == NewsType.KAMPANYA || news.type == NewsType.ETKINLIK)
      .toList();

  // Pagination için değişkenler
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasMoreNews = true;
  final ScrollController _newsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Türkçe zaman formatı için
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    
    // Haberleri yükle
    _loadNews();
    _newsScrollController.addListener(_onNewsScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newsScrollController.dispose();
    super.dispose();
  }

  // Scroll ile aşağı inince yeni sayfa yükle
  void _onNewsScroll() {
    if (_newsScrollController.position.pixels >= _newsScrollController.position.maxScrollExtent - 100) {
      if (!_isLoading && _hasMoreNews) {
        _loadNews();
      }
    }
  }

  Future<void> _refreshNews() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _allNews = [];
      _hasMoreNews = true;
    });

    try {
      await _loadNews(refresh: true);
    } catch (e) {
      print('Haberleri yenileme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadNews({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _allNews = [];
        _hasMoreNews = true;
      });
    }
    if (!_hasMoreNews && !refresh) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      apiService.setupTokenInterceptor();
      final newsService = NewsService(apiService: apiService);
      final newsPage = await newsService.getActiveNewsWithCache(
        platform: PlatformType.MOBILE,
        page: _currentPage,
        size: 2,
      );
      setState(() {
        if (refresh) {
          _allNews = newsPage.content;
        } else {
          _allNews = [..._allNews, ...newsPage.content];
        }
        _currentPage = newsPage.pageNumber + 1;
        _totalPages = newsPage.totalPages;
        _hasMoreNews = !newsPage.isLast;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Haberler yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Geri dönme butonu beyaz
        title: const Text(
          'Haberler ve Duyurular',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(text: 'Tümü'),
                Tab(text: 'Önemli'),
                Tab(text: 'Duyurular'),
                Tab(text: 'Projeler'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewsList(_allNews),
          _buildNewsList(_importantNews),
          _buildNewsList(_announcements),
          _buildNewsList(_projects),
        ],
      ),
    );
  }

  Widget _buildNewsList(List<UserNewsDTO> newsList) {
    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      displacement: 40.0,
      strokeWidth: 3.0,
      child: _isLoading && newsList.isEmpty
          ? _buildShimmerLoadingList()
          : newsList.isEmpty
              ? _buildEmptyList()
              : NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    if (scrollNotification is ScrollEndNotification) {
                      _onNewsScroll();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _newsScrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
                    itemCount: newsList.length + (_hasMoreNews ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < newsList.length) {
                        final news = newsList[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: _buildNewsCard(news),
                        );
                      } else {
                        // Yükleniyor göstergesi
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
    );
  }

  Widget _buildShimmerLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: _buildShimmerLoadingList(),
    );
  }

  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.dividerColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Haber bulunamadı',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Şu anda görüntülenecek haber bulunmuyor. Lütfen daha sonra tekrar kontrol edin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshNews,
            icon: const Icon(Icons.refresh),
            label: const Text('Yenile'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(UserNewsDTO news) {
    final bool isImportant = news.priority == NewsPriority.YUKSEK || 
                             news.priority == NewsPriority.COK_YUKSEK ||
                             news.priority == NewsPriority.KRITIK;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showNewsDetails(news),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
            children: [
              // Medya kısmı
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      constraints: const BoxConstraints(maxHeight: 200), // Limit max height
                      child: _buildNewsMedia(news),
                    ),
                  ),
                  
                  // Önemli haber ise üst köşeye etiket ekle
                  if (isImportant)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.star, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Önemli',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
              // İçerik kısmı
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori, Görüntülenme sayısı ve Tarih
                    Row(
                      children: [
                        // Kategori
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(news.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(news.type),
                                size: 14,
                                color: _getCategoryColor(news.type),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getCategoryName(news.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getCategoryColor(news.type),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Görüntülenme sayısı
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: AppTheme.textSecondaryColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${news.viewCount}",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Tarih
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.textSecondaryColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(news.date, locale: 'tr'),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Başlık
                    Text(
                      news.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Özet kaldırıldı
                    const SizedBox(height: 16),
                    
                    // Alt butonlar - Wrap in SingleChildScrollView to prevent overflow
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Detaylar butonu - Esnek genişlik
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.5,
                            ),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.remove_red_eye, size: 18),
                              label: const Text('Detaylar'),
                              onPressed: () => _showNewsDetails(news),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // İkon butonlar - Sabit boyut
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: const Icon(Icons.share_rounded, size: 20),
                              onPressed: () => _shareNews(news),
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: AppTheme.dividerColor,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: const Icon(Icons.favorite_border_rounded, size: 20),
                              onPressed: () {
                                // Beğenme işlemi - gelecekte eklenecek
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Beğenme özelliği yakında eklenecek'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: IconButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: AppTheme.dividerColor,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Haber detayı gösterme fonksiyonu
  void _showNewsDetails(UserNewsDTO news) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailFromIdScreen(newsId: news.id),
      ),
    );
    _refreshNews();
  }
  
  void _playVideo(UserNewsDTO news) {
    // Kullanıcıya normal detay sayfası veya video oynatıcı seçeneği sun
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kapatma çubuğu
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Video veya detay görüntüleme',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.article_rounded, 
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: const Text('Haber Detayını Görüntüle'),
                subtitle: const Text('Haberin tam metnini ve içeriğini okuyun'),
                onTap: () {
                  Navigator.pop(context); // Sheet kapat
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_circle_filled_rounded, 
                    color: Colors.red,
                  ),
                ),
                title: const Text('Videoyu Oynat'),
                subtitle: const Text('Video içeriğini tam ekran izleyin'),
                onTap: () {
                  Navigator.pop(context); // Sheet kapat
                  
                  // Video oynatıcıyı tam ekran olarak aç
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          // Kapatma çubuğu
                          Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[500],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Video başlığı
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              news.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Video player
                          Expanded(
                            child: VideoPlayerWidget(
                              videoUrl: news.videoUrl!,
                              autoPlay: true,
                              looping: false,
                              showControls: true,
                              fitToScreen: true,
                              showCloseButton: true,
                              showFullscreenButton: true,
                              onClosePressed: () => _toggleVideoPlay(news),
                              onFullscreenPressed: () => _showVideoPreview(news),
                            ),
                          ),
                          // Video altındaki açıklama kaldırıldı
                          // Alt butonlar
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.share_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () => _shareNews(news),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.text_snippet_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Video tam ekran fonksiyonu
  void _showVideoPreview(UserNewsDTO news) {
    // Video URL'sinin geçerli olup olmadığını kontrol et
    if (news.videoUrl == null || news.videoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu haber için video bulunamadı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player - ortalanmış, ekranın ortasında
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16/9, // Video için standart aspect ratio
                  child: VideoPlayerWidget(
                    videoUrl: news.videoUrl!,
                    autoPlay: true,
                    looping: false,
                    showControls: true,
                    fitToScreen: true,
                  ),
                ),
              ),
            ),
            
            // Kapatma butonu - sağ üstte, daha belirgin
            Positioned(
              top: 24,
              right: 24,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Alt butonlar (paylaşma ve haber detayı) - İsteğe bağlı, ekranın alt kısmında
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
                      onPressed: () => _shareNews(news),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.text_snippet_rounded,
                        color: Colors.white70,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildNewsMedia(UserNewsDTO news) {
    // Debug: Video URL'sini konsola yazdır
    print('📹 News ID: ${news.id}, Title: ${news.title}');
    print('📹 Video URL: ${news.videoUrl}');
    print('📹 Image URL: ${news.image}');
    print('📹 Thumbnail URL: ${news.thumbnailUrl}');
    
    // Video varsa thumbnail veya video player göster
    if (news.videoUrl != null && news.videoUrl!.isNotEmpty) {
      // Thumbnail varsa göster, yoksa video player göster
      if (news.thumbnailUrl != null && news.thumbnailUrl!.isNotEmpty) {
        print('🖼️ Video thumbnail gösteriliyor: ${news.videoUrl}');
        // Eğer bu video oynatılıyorsa video player göster
        if (isVideoPlaying(news.id)) {
          // Video player göster
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayerWidget(
                        videoUrl: news.videoUrl!,
                        autoPlay: true,
                        looping: false,
                        showControls: true,
                        fitToScreen: true,
                        showCloseButton: true,
                        showFullscreenButton: true,
                        onClosePressed: () => _toggleVideoPlay(news),
                        onFullscreenPressed: () => _showVideoPreview(news),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        // Değilse thumbnail göster
        return GestureDetector(
          onTap: () => _toggleVideoPlay(news),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double height = min(constraints.maxWidth * 9/16, 200);
              return SizedBox(
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      news.thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Thumbnail yükleme hatası: $error');
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.movie, size: 60, color: Colors.grey),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.9),
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
            },
          ),
        );
      } else {
        // Thumbnail yoksa video player göster
        print('📹 Video player gösteriliyor: ${news.videoUrl}');
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double height = min(constraints.maxWidth * 9/16, 200);
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: height,
                child: VideoPlayerWidget(
                  videoUrl: news.videoUrl!,
                  autoPlay: false,
                  looping: false,
                  showControls: true,
                  fitToScreen: true,
                  showCloseButton: true,
                  showFullscreenButton: true,
                  onClosePressed: () => _toggleVideoPlay(news),
                  onFullscreenPressed: () => _showVideoPreview(news),
                ),
              ),
            );
          },
        );
      }
    }
    // Video yoksa resim göster
    if (news.image != null && news.image!.isNotEmpty) {
      print('📷 Resim gösteriliyor: ${news.image}');
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double height = min(constraints.maxWidth * 9/16, 200);
          return SizedBox(
            height: height,
            child: Image.network(
              news.image!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Resim yükleme hatası: $error');
                return Center(
                  child: Icon(
                    _getCategoryIcon(news.type),
                    size: 60,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }
    // Ne video ne de resim varsa ikon göster
    print('🎯 Ne video ne resim var, ikon gösteriliyor');
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double height = min(constraints.maxWidth * 9/16, 200);
        return SizedBox(
          height: height,
          child: Container(
            color: AppTheme.backgroundColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(news.type),
                    size: 64,
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCategoryName(news.type),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
