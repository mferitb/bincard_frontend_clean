import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../models/news/user_news_dto.dart';
import 'news_detail_screen.dart';

class NewsDetailFromIdScreen extends StatefulWidget {
  final int newsId;

  const NewsDetailFromIdScreen({super.key, required this.newsId});

  @override
  State<NewsDetailFromIdScreen> createState() => _NewsDetailFromIdScreenState();
}

class _NewsDetailFromIdScreenState extends State<NewsDetailFromIdScreen> {
  final NewsService _newsService = NewsService();
  bool _isLoading = true;
  UserNewsDTO? _news;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadNewsById();
  }

  Future<void> _loadNewsById() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // ID'ye göre haberi getir
      final news = await _newsService.getNewsById(widget.newsId);

      if (news != null) {
        if (mounted) {
          setState(() {
            _news = news;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Haber bulunamadı.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Haber yüklenirken bir hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Haber Yükleniyor', style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_news != null) {
      // Haber bulundu, haber detay sayfasını göster
      return NewsDetailScreen(news: _news!);
    } else {
      // Haber bulunamadı, hata mesajı göster
      return Scaffold(
        appBar: AppBar(
          title: const Text('Haber Bulunamadı', style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'Haber bulunamadı',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/news');
                },
                child: const Text('Tüm Haberlere Dön'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
