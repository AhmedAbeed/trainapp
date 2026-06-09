import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
            isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _PrivacySection(
                title: isArabic ? 'كيف نستخدم معلوماتك' : 'How We Use Your Information',
                isDark: isDark,
                items: isArabic ? [
                  'تقديم الخدمة',
                  'توفير معلومات وجداول القطارات',
                  'تحسين وظيفة البحث',
                  'تخصيص تجربة المستخدم',
                  'تمكين ميزات الخدمة',
                ] : [
                  'Service Provision',
                  'Provide train information and schedules',
                  'Improve search functionality',
                  'Personalize user experience',
                  'Enable service features',
                ],
              ),
              const SizedBox(height: 16),

              _PrivacySection(
                title: isArabic ? 'التواصل' : 'Communication',
                isDark: isDark,
                items: isArabic ? [
                  'الرد على استفساراتك',
                  'إرسال تحديثات الخدمة',
                  'تقديم دعم العملاء',
                  'مشاركة الإشعارات الهامة',
                ] : [
                  'Respond to your inquiries',
                  'Send service updates',
                  'Provide customer support',
                  'Share important notifications',
                ],
              ),
              const SizedBox(height: 16),

              _PrivacySection(
                title: isArabic ? 'التحليل والتحسين' : 'Analysis & Improvement',
                isDark: isDark,
                items: isArabic ? [
                  'تحليل أنماط الاستخدام',
                  'تحسين جودة الخدمة',
                  'تحسين أداء الموقع',
                  'تطوير ميزات جديدة',
                ] : [
                  'Analyze usage patterns',
                  'Improve service quality',
                  'Improve website performance',
                  'Develop new features',
                ],
              ),
              const SizedBox(height: 16),

              _PrivacySection(
                title: isArabic ? 'الامتثال القانوني' : 'Legal Compliance',
                isDark: isDark,
                items: isArabic ? [
                  'الامتثال للالتزامات القانونية',
                  'حماية سلامة المستخدمين',
                  'منع الاحتيال وإساءة الاستخدام',
                  'تطبيق الشروط',
                ] : [
                  'Comply with legal obligations',
                  'Protect user safety',
                  'Prevent fraud and misuse',
                  'Enforce terms',
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'مشاركة المعلومات' : 'Information Sharing',
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'لا نبيع معلوماتك الشخصية. لا نقوم ببيع أو تأجير أو مشاركة معلوماتك الشخصية مع أطراف ثالثة لأغراض تسويقية.'
                          : 'We do not sell your personal information. We do not sell, rent, or share your personal information with third parties for marketing purposes.',
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic ? 'قد نشارك معلوماتك فقط في الحالات التالية:' : 'We may share your information only in the following cases:',
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(isArabic ? [
                      '• مزودو الخدمة: مع مزودي خدمات موثوقين',
                      '• المتطلبات القانونية: عند الطلب القانوني',
                      '• السلامة والأمان: لحماية حقوق المستخدمين',
                      '• نقل الأعمال: في حال الاندماج أو الاستحواذ',
                      '• الموافقة: بموافقتك الصريحة',
                    ] : [
                      '• Service Providers: With trusted service providers',
                      '• Legal Requirements: When legally required',
                      '• Safety & Security: To protect user rights',
                      '• Business Transfer: In case of merger or acquisition',
                      '• Consent: With your explicit consent',
                    ]).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        item,
                        style: GoogleFonts.cairo(
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'أمان البيانات' : 'Data Security',
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic
                          ? 'نطبق تدابير تقنية وتنظيمية مناسبة لحماية معلوماتك الشخصية.'
                          : 'We apply appropriate technical and organizational measures to protect your personal information.',
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final List<String> items;
  final bool isDark;

  const _PrivacySection({
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.successGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.cairo(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}