import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dart:io';
import '../widgets/custom_message.dart';

class ReportProblemScreen extends StatefulWidget {
  final String? busNumber;
  final String? busRoute;

  const ReportProblemScreen({super.key, this.busNumber, this.busRoute});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _problemType = 'Gecikme';
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  DateTime? _problemDate;
  TimeOfDay? _problemTime;
  final List<File> _images = [];
  bool _isSubmitting = false;

  final List<String> _problemTypes = [
    'Gecikme',
    'Erken Kalkış',
    'İptal Edilen Sefer',
    'Kalabalık Araç',
    'Güvenlik Sorunu',
    'Temizlik Sorunu',
    'Şoför Davranışı',
    'Teknik Arıza',
    'Kart Okuyucu Sorunu',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    // Eğer dışarıdan bir otobüs numarası geldiyse kontrolcüye ata
    if (widget.busNumber != null) {
      _busNumberController.text = widget.busNumber!;
    }

    // Varsayılan olarak bugünün tarihini ve şu anki saati ayarla
    _problemDate = DateTime.now();
    _problemTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Sorun Bildir'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader(),
              const SizedBox(height: 24),
              _buildSectionTitle('Sorun Türü'),
              const SizedBox(height: 8),
              _buildProblemTypeDropdown(),
              const SizedBox(height: 16),
              _buildSectionTitle('Otobüs Bilgileri'),
              const SizedBox(height: 8),
              _buildBusNumberInput(),
              const SizedBox(height: 16),
              _buildSectionTitle('Sorun Zamanı'),
              const SizedBox(height: 8),
              _buildDateTimePickers(),
              const SizedBox(height: 16),
              _buildSectionTitle('Konum'),
              const SizedBox(height: 8),
              _buildLocationInput(),
              const SizedBox(height: 16),
              _buildSectionTitle('Detaylı Açıklama'),
              const SizedBox(height: 8),
              _buildDescriptionInput(),
              const SizedBox(height: 16),
              _buildSectionTitle('Fotoğraf Ekle (İsteğe Bağlı)'),
              const SizedBox(height: 8),
              _buildImagePicker(),
              const SizedBox(height: 16),
              _buildSectionTitle('İletişim Bilgileri (İsteğe Bağlı)'),
              const SizedBox(height: 8),
              _buildContactInput(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.report_problem, color: AppTheme.errorColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Toplu Taşıma Sorun Bildirimi',
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
              'Yaşadığınız sorunu bildirerek hizmet kalitemizi artırmamıza yardımcı olabilirsiniz. Bildiriminiz ilgili birimlere iletilecektir.',
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

  Widget _buildProblemTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _problemType,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(8),
          items:
              _problemTypes.map((type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _problemType = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildBusNumberInput() {
    return TextFormField(
      controller: _busNumberController,
      decoration: InputDecoration(
        labelText: 'Otobüs Numarası / Hat',
        hintText: 'Örn: 11A veya 34 ABC 123',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.directions_bus),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen otobüs numarası veya hat bilgisi girin';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimePickers() {
    final formattedDate =
        _problemDate != null
            ? "${_problemDate!.day}/${_problemDate!.month}/${_problemDate!.year}"
            : "Tarih seçin";

    final formattedTime =
        _problemTime != null
            ? "${_problemTime!.hour}:${_problemTime!.minute.toString().padLeft(2, '0')}"
            : "Saat seçin";

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _problemDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppTheme.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setState(() {
                  _problemDate = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(formattedDate),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: _problemTime ?? TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppTheme.primaryColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setState(() {
                  _problemTime = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(formattedTime),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInput() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Konum/Durak',
        hintText: 'Örn: Merkez Durağı',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: IconButton(
          icon: Icon(Icons.my_location, color: AppTheme.primaryColor),
          onPressed: () {
            // Gerçek uygulamada konum servisleri kullanılabilir
            CustomMessage.show(
              context,
              message: 'Konum alınıyor...',
              type: MessageType.info,
            );
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Lütfen konum bilgisi girin';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        hintText: 'Sorunu detaylı açıklayın',
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

  Widget _buildImagePicker() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeriden Seç'),
                onPressed: () => _pickImage('gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotoğraf Çek'),
                onPressed: () => _pickImage('camera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _images.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage(String source) async {
    try {
      // Not: gerçek uygulamada image_picker paketi kullanılmalı
      // Simülasyon için şimdilik sadece bildirim gösteriyoruz

      // Simülasyon bildirimi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${source == 'camera' ? 'Kamera' : 'Galeri'} ile fotoğraf ekleme simüle edildi',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf seçilirken bir hata oluştu')),
      );
    }
  }

  Widget _buildContactInput() {
    return TextFormField(
      controller: _contactController,
      decoration: InputDecoration(
        labelText: 'Telefon veya E-posta',
        hintText: 'Size ulaşabilmemiz için (isteğe bağlı)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.contact_phone),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          // Telefon veya e-posta validasyonu yapılabilir
          // Şimdilik basit bir kontrol yeterli
          if (value.length < 5) {
            return 'Geçerli bir iletişim bilgisi girin';
          }
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
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
                : const Text('Şikayeti Gönder'),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Burada gerçek bir API çağrısı yapılacak
      // Şimdilik simüle ediyoruz
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      // Başarılı iletim mesajı
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bildiriminiz başarıyla iletildi. En kısa sürede incelenecektir.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundVariant1,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bildirim No: #${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
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
    }
  }
}
