import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _feedbackType = 'Öneri';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  int _rating = 4;
  bool _isSubmitting = false;
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();

  // Türkçe label -> Backend enum eşlemesi
  final Map<String, String> _feedbackTypeMap = {
    'Öneri': 'SUGGESTION',
    'Şikayet': 'COMPLAINT',
    'Teknik Hata': 'TECHNICAL_ISSUE',
    'Diğer': 'OTHER',
  };

  final List<String> _feedbackTypes = [
    'Öneri',
    'Şikayet',
    'Teknik Hata',
    'Diğer',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Uygulama Geri Bildirimi',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Geri Bildirim Türü'),
              const SizedBox(height: 8),
              _buildFeedbackTypeDropdown(),
              const SizedBox(height: 16),
              _buildSectionTitle('Değerlendirme'),
              const SizedBox(height: 8),
              _buildRatingBar(),
              const SizedBox(height: 16),
              _buildSectionTitle('Başlık'),
              const SizedBox(height: 8),
              _buildTitleInput(),
              const SizedBox(height: 16),
              _buildSectionTitle('Detaylı Açıklama'),
              const SizedBox(height: 8),
              _buildDescriptionInput(),
              const SizedBox(height: 16),
              _buildSectionTitle('Fotoğraf (isteğe bağlı)'),
              const SizedBox(height: 8),
              _buildPhotoPicker(),
              const SizedBox(height: 16),
              _buildSectionTitle('İletişim Bilgileri (İsteğe Bağlı)'),
              const SizedBox(height: 8),
              _buildEmailInput(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
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
                    'Uygulamamızı geliştirmemize yardımcı olun',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Görüşleriniz bizim için önemli. Uygulamamızı nasıl daha iyi hale getirebileceğimiz konusunda bize geri bildirim gönderebilirsiniz.',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildFeedbackTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _feedbackType,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(8),
          items:
              _feedbackTypes.map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _feedbackType = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildRatingBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: index < _rating ? AppTheme.accentColor : Colors.grey,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1;
            });
          },
        );
      }),
    );
  }

  Widget _buildTitleInput() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        hintText: 'Geri bildiriminiz için kısa bir başlık yazın',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen bir başlık girin';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        hintText: 'Lütfen detaylı açıklama yazın',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen açıklama girin';
        }
        if (value.length < 10) {
          return 'Açıklama en az 10 karakter olmalıdır';
        }
        return null;
      },
    );
  }

  Widget _buildEmailInput() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'E-posta adresiniz (isteğe bağlı)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          // Basit e-posta doğrulaması
          bool emailValid = RegExp(
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
          ).hasMatch(value);
          if (!emailValid) {
            return 'Geçerli bir e-posta adresi girin';
          }
        }
        return null;
      },
    );
  }

  Widget _buildPhotoPicker() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _pickPhoto,
          icon: const Icon(Icons.photo),
          label: const Text('Fotoğraf Seç'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        _selectedPhoto != null
            ? Expanded(
                child: Text(
                  _selectedPhoto!.path.split('/').last,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : const Text('Seçilmedi', style: TextStyle(fontSize: 13, color: Colors.grey)),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.grey,
        ),
        child:
            _isSubmitting
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Gönderiliyor...'),
                  ],
                )
                : const Text('Geri Bildirimi Gönder'),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        final apiService = ApiService();
        apiService.setupTokenInterceptor();
        final formData = FormData.fromMap({
          'subject': _titleController.text.trim(),
          'message': _descriptionController.text.trim(),
          'type': _feedbackTypeMap[_feedbackType] ?? 'OTHER',
          'source': 'mobil',
          if (_selectedPhoto != null)
            'photo': await MultipartFile.fromFile(_selectedPhoto!.path, filename: _selectedPhoto!.path.split('/').last),
        });
        final response = await apiService.dio.post(
          ApiConstants.baseUrl + '/feedback/send',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        if (response.statusCode == 200 || response.statusCode == 201) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  const Text('Teşekkürler!'),
                ],
              ),
              content: const Text(
                'Geri bildiriminiz başarıyla gönderildi. Değerli görüşleriniz için teşekkür ederiz.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Dialog'u kapat
                    Navigator.pop(context); // Sayfayı kapat
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        } else {
          _showErrorDialog('Geri bildirim gönderilemedi. Lütfen tekrar deneyin.');
        }
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorDialog('Bir hata oluştu: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Hata'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
