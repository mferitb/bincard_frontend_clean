import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/video_player_widget.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Örnek video URL'leri
  final List<Map<String, dynamic>> _sampleVideos = [
    {
      'title': 'Sample Video 1',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'description': 'Big Buck Bunny - Test videosu',
    },
    {
      'title': 'Sample Video 2', 
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'description': 'Elephants Dream - Test videosu',
    },
    {
      'title': 'Sample Video 3',
      'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'description': 'For Bigger Blazes - Test videosu',
    },
  ];

  int _selectedVideoIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Video Player',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoPlayerSection(),
              const SizedBox(height: 24),
              _buildVideoInfo(),
              const SizedBox(height: 24),
              _buildVideoList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayerSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16/9,
        child: VideoPlayerWidget(
          videoUrl: _sampleVideos[_selectedVideoIndex]['url'],
          autoPlay: false,
          looping: false,
          showControls: true,
          fitToScreen: true,
          maxHeight: MediaQuery.of(context).size.height * 0.6, // Ekranın max %60'ı
          minHeight: 200, // Minimum 200px
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    final currentVideo = _sampleVideos[_selectedVideoIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentVideo['title'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentVideo['description'],
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.video_library,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Video ${_selectedVideoIndex + 1} / ${_sampleVideos.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diğer Videolar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sampleVideos.length,
          itemBuilder: (context, index) {
            final video = _sampleVideos[index];
            final isSelected = index == _selectedVideoIndex;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: Text(
                  video['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                  ),
                ),
                subtitle: Text(
                  video['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.play_circle_filled,
                        color: AppTheme.primaryColor,
                        size: 32,
                      )
                    : Icon(
                        Icons.play_circle_outline,
                        color: Colors.grey,
                        size: 32,
                      ),
                onTap: () {
                  setState(() {
                    _selectedVideoIndex = index;
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
