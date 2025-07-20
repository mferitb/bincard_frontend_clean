import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;
  final double? maxHeight;
  final double? minHeight;
  final bool fitToScreen;
  final bool showThumbnail;
  final bool showFullscreenButton;
  final bool showCloseButton;
  final VoidCallback? onFullscreenPressed;
  final VoidCallback? onClosePressed;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
    this.maxHeight,
    this.minHeight,
    this.fitToScreen = true,
    this.showThumbnail = false,
    this.showFullscreenButton = false,
    this.showCloseButton = false,
    this.onFullscreenPressed,
    this.onClosePressed,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      String videoUrl = widget.videoUrl;
      
      // URL'nin geçerli olup olmadığını kontrol et
      if (videoUrl.isEmpty) {
        throw Exception('Video URL boş olamaz');
      }
      
      // Cloudinary URL'sini video player için optimize et
      if (videoUrl.contains('cloudinary.com') && videoUrl.contains('/video/upload/')) {
        // Cloudinary video URL'sini doğru formata çevir
        videoUrl = videoUrl.replaceAll('/video/upload/', '/video/upload/f_mp4,q_auto/');
        debugPrint('🎥 Cloudinary URL optimize edildi: $videoUrl');
      }
      
      debugPrint('🎥 Video yükleniyor: $videoUrl');
      
      // Video URL'sine göre controller oluştur
      if (videoUrl.startsWith('http') || videoUrl.startsWith('https')) {
        // Network video
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        // Asset video
        _controller = VideoPlayerController.asset(videoUrl);
      }

      // Controller'ı başlat
      await _controller!.initialize();

      // Ayarları uygula
      _controller!.setLooping(widget.looping);
      
      if (widget.autoPlay) {
        await _controller!.play();
        _isPlaying = true;
      }

      // Listener ekle
      _controller!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      
      debugPrint('✅ Video başarıyla yüklendi');
      debugPrint('🎥 Video çözünürlüğü: ${_controller!.value.size}');
      debugPrint('🎥 Video aspect ratio: ${_controller!.value.aspectRatio}');
      debugPrint('🎥 Optimal height: ${_getOptimalHeight()}');
      
    } catch (e) {
      debugPrint('❌ Video yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video yüklenirken hata oluştu: $e';
        });
      }
    }
  }

  // Video çözünürlüğüne göre optimal aspect ratio hesapla
  double _getOptimalAspectRatio() {
    if (!_isInitialized || _controller == null) {
      return widget.aspectRatio ?? 16 / 9; // Default aspect ratio
    }
    
    final videoSize = _controller!.value.size;
    final videoAspectRatio = _controller!.value.aspectRatio;
    
    debugPrint('🎥 Video boyutu: ${videoSize.width}x${videoSize.height}');
    debugPrint('🎥 Video aspect ratio: $videoAspectRatio');
    
    // Eğer widget'ta specific aspect ratio belirtilmişse onu kullan
    if (widget.aspectRatio != null) {
      return widget.aspectRatio!;
    }
    
    // Video aspect ratio geçersizse default kullan
    if (videoAspectRatio <= 0 || videoAspectRatio.isNaN || videoAspectRatio.isInfinite) {
      return 16 / 9;
    }
    
    return videoAspectRatio;
  }

  // Video çözünürlüğüne göre container height hesapla
  double _getOptimalHeight() {
    if (!_isInitialized || !mounted || _controller == null) {
      return widget.minHeight ?? 200; // Default height
    }
    
    // Eğer fitToScreen false ise, sadece aspect ratio kullan
    if (!widget.fitToScreen) {
      final screenWidth = MediaQuery.of(context).size.width - 32;
      final aspectRatio = _getOptimalAspectRatio();
      return screenWidth / aspectRatio;
    }
    
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width - 32; // Padding çıkarılmış
    final screenHeight = screenSize.height;
    final aspectRatio = _getOptimalAspectRatio();
    
    // Aspect ratio'ya göre height hesapla
    double calculatedHeight = screenWidth / aspectRatio;
    
    // Widget parametrelerinden limitler al, yoksa ekran boyutuna göre dinamik limitler
    final defaultHeight = widget.minHeight ?? (screenHeight * 0.25); // Ekranın %25'i
    final maxHeight = widget.maxHeight ?? (screenHeight * 0.4);
    
    // Min/max değerleri arasında sınırla
    calculatedHeight = calculatedHeight.clamp(defaultHeight, maxHeight);
    
    debugPrint('🎥 Hesaplanan video yüksekliği: $calculatedHeight');
    
    return calculatedHeight;
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      setState(() {
        _isPlaying = _controller!.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          _controller!.play();
          _isPlaying = true;
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Thumbnail'dan video player'a geçiş
  void _switchToVideoPlayer() {
    if (widget.showThumbnail) {
      setState(() {
        // Video kontrolcüsünü yükle
        _isInitialized = false;
      });
      
      // Video player'ı başlat
      _initializeVideoPlayer().then((_) {
        if (mounted) {
          setState(() {
            // Thumbnail modunu kapat
            // Bu setState VideoPlayerWidget'ın build metodunu yeniden çalıştırır
            // ve _buildVideoPlayer() metodunun normal video player'ı oluşturmasını sağlar
          });
          
          // Videoyu oynat
          _controller!.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return _buildVideoPlayer();
  }

  Widget _buildErrorWidget() {
    // Error durumunda da widget parametrelerine uygun height kullan
    final screenHeight = MediaQuery.of(context).size.height;
    final defaultHeight = widget.minHeight ?? (screenHeight * 0.25); // Ekranın %25'i
    final maxHeight = widget.maxHeight ?? (screenHeight * 0.4);
    
    return Container(
      height: defaultHeight.clamp(150, maxHeight),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Video Hatası',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    // Loading durumunda da widget parametrelerine uygun height kullan
    final screenHeight = MediaQuery.of(context).size.height;
    final defaultHeight = widget.minHeight ?? (screenHeight * 0.25); // Ekranın %25'i
    final maxHeight = widget.maxHeight ?? (screenHeight * 0.4);
    
    return Container(
      height: defaultHeight.clamp(150, maxHeight),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Video yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null) {
      return _buildErrorWidget();
    }
    
    final aspectRatio = _getOptimalAspectRatio();
    
    // We no longer use a fixed height Container to wrap the video player
    // This allows the player to properly respect the AspectRatio constraints from its parent
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Video player
          AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          
          // Kontroller overlay
          if (widget.showControls)
            GestureDetector(
              onTap: _toggleControls,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: _buildVideoControls(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    if (_controller == null) {
      return const SizedBox.shrink();
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use constraints to build responsive controls
        final bool isSmallScreen = constraints.maxHeight < 200;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Üst kontroller - kapatma butonu ve tam ekran butonu
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Kapatma butonu (sol üst)
                  if (widget.showCloseButton && widget.onClosePressed != null)
                    GestureDetector(
                      onTap: widget.onClosePressed,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  // Tam ekran butonu (sağ üst)
                  if (widget.showFullscreenButton && widget.onFullscreenPressed != null)
                    GestureDetector(
                      onTap: widget.onFullscreenPressed,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Orta kontroller (play/pause)
            Center(
              child: IconButton(
                iconSize: isSmallScreen ? 40 : 64,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white,
                ),
                onPressed: _togglePlayPause,
                padding: EdgeInsets.zero,
              ),
            ),
            
            // Alt kontroller (progress bar ve zaman)
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress bar
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppTheme.primaryColor,
                      bufferedColor: Colors.white.withOpacity(0.3),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  if (!isSmallScreen) const SizedBox(height: 4),
                  // Zaman bilgisi - only show on larger screens
                  if (!isSmallScreen)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_controller!.value.position),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formatDuration(_controller!.value.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
