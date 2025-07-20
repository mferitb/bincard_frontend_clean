import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:io';

class AppFeedbackScreen extends StatefulWidget {
  const AppFeedbackScreen({super.key});

  @override
  State<AppFeedbackScreen> createState() => _AppFeedbackScreenState();
}

class _AppFeedbackScreenState extends State<AppFeedbackScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _isAnonymous = false;
  int _rating = 0;
  String _selectedCategory = 'Genel';
  File? _screenshotFile;

  // Geri bildirim kategorileri
  final List<String> _categories = [
    'Genel',
    'Kullanılabilirlik',
    'Tasarım',
    'Performans',
    'Özellik İsteği',
    'Hata Bildirimi',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Uygulama Geri Bildirimi'),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildRatingSection(),
                const SizedBox(height: 24),
                _buildCategorySection(),
                const SizedBox(height: 24),
                _buildFeedbackInput(),
                const SizedBox(height: 16),
                _buildScreenshotSection(),
                const SizedBox(height: 16),
                _buildContactSection(),
                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.infoColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Geri Bildirimlerin Bize Ulaşır',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Uygulamamızı geliştirmek için görüşleriniz bizim için değerli. '
              'Lütfen deneyiminizi puanlayın ve düşüncelerinizi paylaşın.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uygulamamızı Puanlayın',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: index < _rating ? AppTheme.accentColor : Colors.grey,
                size: 36,
              ),
              onPressed: () {
                setState(() {
                  _rating = index + 1;
                });
              },
            );
          }),
        ),
        Center(
          child: Text(
            _rating > 0 ? _getRatingText(_rating) : 'Henüz puanlanmadı',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  _rating > 0
                      ? AppTheme.textPrimaryColor
                      : AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Çok kötü';
      case 2:
        return 'Kötü';
      case 3:
        return 'Orta';
      case 4:
        return 'İyi';
      case 5:
        return 'Çok iyi';
      default:
        return '';
    }
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geri Bildirim Kategorisi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              items:
                  _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geri Bildiriminiz',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _feedbackController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Deneyiminizi veya önerilerinizi buraya yazın...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen geri bildiriminizi yazın';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildScreenshotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ekran Görüntüsü (İsteğe Bağlı)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            _showImageOptionsDialog();
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                _screenshotFile != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _screenshotFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                    : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 36,
                            color: AppTheme.primaryColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ekran görüntüsü eklemek için dokunun',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'İletişim Bilgileri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'Anonim',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Switch(
                  value: _isAnonymous,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _isAnonymous = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_isAnonymous)
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'E-posta adresiniz',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (!_isAnonymous && (value == null || value.isEmpty)) {
                return 'Lütfen e-posta adresinizi girin';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Text('Geri Bildirimi Gönder'),
      ),
    );
  }

  void _showImageOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('Galeriden Seç'),
                  onTap: () {
                    Navigator.pop(context);
                    // Gerçek uygulamada: _getImageFromGallery();
                    _showSnackbar('Galeriden görüntü seçme özelliği eklenecek');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.screenshot, color: AppTheme.infoColor),
                  title: const Text('Ekran Görüntüsü Al'),
                  onTap: () {
                    Navigator.pop(context);
                    // Gerçek uygulamada: _takeScreenshot();
                    _showSnackbar('Ekran görüntüsü alma özelliği eklenecek');
                  },
                ),
                if (_screenshotFile != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: AppTheme.errorColor),
                    title: const Text('Görüntüyü Kaldır'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _screenshotFile = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      if (_rating == 0) {
        _showSnackbar('Lütfen uygulamayı puanlayın');
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      // Simüle edilmiş gönderme işlemi
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        setState(() {
          _isSubmitting = false;
        });

        _showSuccessDialog();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successColor),
                const SizedBox(width: 8),
                const Text('Teşekkürler!'),
              ],
            ),
            content: const Text(
              'Geri bildiriminiz için teşekkür ederiz. Uygulamayı geliştirmek için değerli görüşlerinizi dikkate alacağız.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Dialog'u kapat
                  Navigator.pop(context); // Ekranı kapat
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Tamam'),
              ),
            ],
          ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
