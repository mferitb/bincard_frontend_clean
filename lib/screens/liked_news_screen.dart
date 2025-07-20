import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../theme/app_theme.dart';
import '../models/news/user_news_dto.dart';
import '../services/news_service.dart';
import 'news_detail_from_id_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class LikedNewsScreen extends StatefulWidget {
  const LikedNewsScreen({Key? key}) : super(key: key);

  @override
  State<LikedNewsScreen> createState() => _LikedNewsScreenState();
}

class _LikedNewsScreenState extends State<LikedNewsScreen> with RouteAware {
  List<UserNewsDTO> _likedNews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikedNews();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteObserver'a abone ol
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    // RouteObserver'dan çık
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Başka bir sayfadan geri dönülünce tetiklenir
    _fetchLikedNews();
  }

  Future<void> _fetchLikedNews() async {
    setState(() => _isLoading = true);
    final newsService = NewsService();
    final likedNews = await newsService.getLikedNews();
    setState(() {
      _likedNews = likedNews;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Beğendiğim Haberler', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedNews.isEmpty
              ? const Center(child: Text('Henüz beğendiğiniz bir haber yok.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _likedNews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final news = _likedNews[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.article, color: AppTheme.primaryColor),
                        title: Text(news.title),
                        subtitle: Text(news.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsDetailFromIdScreen(newsId: news.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 