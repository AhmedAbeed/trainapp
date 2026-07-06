import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'مركز المساعدة' : 'Help Center',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.contact_support_outlined,
                      size: 60,
                      color: AppTheme.accentDefault,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic ? 'ابق على تواصل' : 'Stay Connected',
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'يسعدنا سماعك. أرسل لنا رسالة وسنرد عليك في أقرب وقت ممكن.'
                          : 'We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _ContactCard(
                      icon: Icons.email_outlined,
                      title: isArabic ? 'البريد الإلكتروني' : 'Email',
                      value: 'support@trains.com',
                      isDark: isDark,
                      onTap: () => _sendEmail('support@trains.com'),
                    ),
                    const SizedBox(height: 12),

                    _ContactCard(
                      icon: Icons.access_time_outlined,
                      title: isArabic ? 'مدة الرد' : 'Response Time',
                      value: isArabic ? 'عادةً نرد خلال ٢٤-٤٨ ساعة' : 'Usually respond within 24-48 hours',
                      isDark: isDark,
                      showArrow: false,
                    ),
                    const SizedBox(height: 12),

                    _ContactCard(
                      icon: Icons.work_outline,
                      title: isArabic ? 'ساعات العمل' : 'Working Hours',
                      value: isArabic
                          ? 'الأحد - الخميس: ٩:٠٠ صباحاً - ٦:٠٠ مساءً (بتوقيت القاهرة)'
                          : 'Sunday - Thursday: 9:00 AM - 6:00 PM (Cairo Time)',
                      isDark: isDark,
                      showArrow: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: AppTheme.accentDefault, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          isArabic ? 'أسئلة شائعة' : 'Frequently Asked Questions',
                          style: GoogleFonts.cairo(
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _FaqItem(
                      question: isArabic ? 'كيف يمكنني إلغاء حجزي؟' : 'How can I cancel my booking?',
                      answer: isArabic
                          ? 'يمكنك إلغاء الحجز من خلال الذهاب إلى صفحة "رحلتي" ثم الضغط على زر إلغاء الحجز.'
                          : 'You can cancel your booking by going to "My Trip" page and clicking the cancel button.',
                      isDark: isDark,
                    ),
                    const Divider(color: AppTheme.surfaceTertiary),
                    _FaqItem(
                      question: isArabic ? 'كيف أغير مقعدي؟' : 'How do I change my seat?',
                      answer: isArabic
                          ? 'يمكنك تغيير مقعدك من خلال صفحة تفاصيل الرحلة قبل 48 ساعة من موعد القطار.'
                          : 'You can change your seat through the trip details page up to 48 hours before departure.',
                      isDark: isDark,
                    ),
                    const Divider(color: AppTheme.surfaceTertiary),
                    _FaqItem(
                      question: isArabic ? 'هل يمكنني استرداد ثمن التذكرة؟' : 'Can I get a refund?',
                      answer: isArabic
                          ? 'نعم، يمكنك استرداد التذكرة بالكامل إذا تم الإلغاء قبل 24 ساعة من موعد الرحلة.'
                          : 'Yes, you can get a full refund if you cancel 24 hours before departure.',
                      isDark: isDark,
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

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isDark;
  final bool showArrow;
  final VoidCallback? onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isDark,
    this.showArrow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentDefault.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.accentDefault, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.cairo(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isDark;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isDark,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.cairo(
                      color: widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.accentDefault,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.answer,
              style: GoogleFonts.cairo(
                color: widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
