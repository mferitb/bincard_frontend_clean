import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Kullanım Koşulları',
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
              _buildLastUpdatedInfo(),
              const SizedBox(height: 24),
              _buildTermsSection(
                title: '1. Hizmet Kullanımı',
                content: '''
Şehir Kart uygulamasını kullanarak, bu koşulları kabul etmiş olursunuz. Uygulama, toplu taşıma kartlarınızı yönetmenize, bakiye yüklemenize ve seyahat geçmişinizi görüntülemenize olanak tanır.

Uygulama hizmetlerini kullanmak için en az 18 yaşında olmanız veya ebeveyn/vasi gözetiminde olmanız gerekmektedir. Hesabınızın güvenliğinden siz sorumlusunuz ve şifrenizi kimseyle paylaşmamalısınız.

Şehir Kart uygulaması, herhangi bir zamanda ve herhangi bir nedenle hizmetlerini değiştirme, askıya alma veya sonlandırma hakkını saklı tutar.
''',
              ),
              _buildTermsSection(
                title: '2. Ödeme ve İadeler',
                content: '''
Uygulama üzerinden yapılan tüm ödemeler, seçtiğiniz ödeme yöntemi aracılığıyla gerçekleştirilir. Bakiye yükleme işlemleri anında gerçekleşir ve geri alınamaz.

Teknik bir hata nedeniyle bakiyeniz yüklenmezse, müşteri hizmetleriyle iletişime geçebilirsiniz. İşlem kanıtlarını sunmanız gerekebilir.

Abonelik satın alımları için, abonelik süresi başladıktan sonra iade yapılmaz. Aboneliğinizi istediğiniz zaman iptal edebilirsiniz, ancak kalan süre için ücret iadesi yapılmaz.
''',
              ),
              _buildTermsSection(
                title: '3. Kullanıcı İçeriği ve Davranışı',
                content: '''
Uygulama içinde paylaştığınız tüm içeriklerden (yorumlar, fotoğraflar, geri bildirimler) siz sorumlusunuz. Yasadışı, tehditkar, taciz edici, müstehcen, iftira niteliğinde veya başka şekilde uygunsuz içerik paylaşmamayı kabul edersiniz.

Şehir Kart, uygunsuz olduğu düşünülen herhangi bir içeriği kaldırma hakkını saklı tutar. Tekrarlanan ihlaller, hesabınızın askıya alınmasına veya sonlandırılmasına neden olabilir.

Uygulamayı, başkalarının kullanımını engelleyecek veya sistemlere zarar verecek şekilde kullanmamayı kabul edersiniz.
''',
              ),
              _buildTermsSection(
                title: '4. Gizlilik ve Veri Kullanımı',
                content: '''
Kişisel verilerinizin nasıl toplandığı, kullanıldığı ve paylaşıldığı hakkında bilgi için Gizlilik Politikamıza bakın. Uygulamayı kullanarak, Gizlilik Politikasında açıklanan veri uygulamalarını kabul etmiş olursunuz.

Uygulama, hizmetleri iyileştirmek için anonim kullanım verileri toplayabilir. Bu verilere konum bilgileri, cihaz bilgileri ve uygulama kullanım istatistikleri dahildir.

Hesabınızı silmeyi seçerseniz, kişisel verileriniz Gizlilik Politikamızda belirtildiği şekilde silinecek veya anonimleştirilecektir.
''',
              ),
              _buildTermsSection(
                title: '5. Fikri Mülkiyet Hakları',
                content: '''
Şehir Kart uygulaması ve içeriği (metin, grafikler, logolar, simgeler, görüntüler ve yazılım dahil), Şehir Kart'a veya lisans verenlere aittir ve telif hakkı, ticari marka ve diğer fikri mülkiyet yasaları tarafından korunmaktadır.

Uygulamayı kullanmanız, bu fikri mülkiyeti kopyalama, değiştirme, dağıtma veya satma hakkı vermez. Uygulama içeriğini yalnızca kişisel, ticari olmayan kullanım için görüntüleyebilirsiniz.

Geri bildirim veya öneriler göndererek, Şehir Kart'a bu geri bildirimi herhangi bir kısıtlama olmaksızın kullanma hakkı vermiş olursunuz.
''',
              ),
              _buildTermsSection(
                title: '6. Sorumluluk Sınırlaması',
                content: '''
Şehir Kart uygulaması "olduğu gibi" ve "mevcut olduğu şekliyle" sunulmaktadır, herhangi bir garanti olmaksızın. Uygulama kesintisiz veya hatasız çalışmayabilir.

Şehir Kart, uygulamanın kullanımından kaynaklanan veya bununla bağlantılı herhangi bir doğrudan, dolaylı, arızi, özel veya sonuç olarak ortaya çıkan zararlardan sorumlu değildir.

Bazı yargı bölgeleri belirli garantilerin hariç tutulmasına veya sorumluluğun sınırlandırılmasına izin vermez, bu nedenle yukarıdaki sınırlamalar sizin için geçerli olmayabilir.
''',
              ),
              _buildTermsSection(
                title: '7. Değişiklikler ve Fesih',
                content: '''
Şehir Kart, bu kullanım koşullarını herhangi bir zamanda değiştirebilir. Değişiklikler, uygulama içinde veya e-posta yoluyla bildirilecektir. Değişikliklerin yayınlanmasından sonra uygulamayı kullanmaya devam etmeniz, güncellenmiş koşulları kabul ettiğiniz anlamına gelir.

Şehir Kart, herhangi bir zamanda ve herhangi bir nedenle, önceden bildirimde bulunmaksızın hesabınızı askıya alabilir veya sonlandırabilir.

Bu koşulları ihlal etmeniz durumunda, hesabınıza erişiminiz derhal ve bildirimde bulunmaksızın sonlandırılabilir.
''',
              ),
              _buildTermsSection(
                title: '8. Genel Hükümler',
                content: '''
Bu koşullar, siz ve Şehir Kart arasındaki tam anlaşmayı temsil eder ve uygulama kullanımınızla ilgili önceki tüm anlaşmaları geçersiz kılar.

Bu koşulların herhangi bir hükmünün geçersiz veya uygulanamaz olduğu tespit edilirse, kalan hükümler tam olarak yürürlükte kalacaktır.

Bu koşullardan doğan veya bunlarla bağlantılı herhangi bir anlaşmazlık, Türkiye Cumhuriyeti yasalarına göre yönetilecek ve Türkiye mahkemelerinin münhasır yargı yetkisine tabi olacaktır.
''',
              ),
              _buildTermsSection(
                title: '9. İletişim',
                content: '''
Bu kullanım koşulları hakkında sorularınız veya endişeleriniz varsa, lütfen support@sehirkart.com.tr adresinden bizimle iletişime geçin.

Şehir Kart
Adres: Cumhuriyet Cad. No:123, 34000, İstanbul, Türkiye
Telefon: (0212) 123 45 67
''',
              ),
              const SizedBox(height: 32),
              _buildAcceptButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.infoColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppTheme.infoColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Son Güncelleme Tarihi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1 Haziran 2025',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Anladım ve Kabul Ediyorum',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 