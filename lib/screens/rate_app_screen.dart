import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  double _rating = 0;
  String _feedbackText = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'تقييم التطبيق' : 'Rate App',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppTheme.bgDefault,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfacePrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_rate_rounded,
                      color: AppTheme.warningAmber,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isArabic ? 'قيم تجربتك مع التطبيق' : 'Rate your experience',
                      style: GoogleFonts.cairo(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic
                          ? 'شاركنا رأيك لنساعد في تحسين التطبيق'
                          : 'Share your feedback to help us improve',
                      style: GoogleFonts.cairo(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() => _rating = index + 1.0);
                          },
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: AppTheme.warningAmber,
                            size: 48,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _rating > 0
                          ? _getRatingText(isArabic)
                          : '',
                      style: GoogleFonts.cairo(
                        color: AppTheme.accentDefault,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.surfaceTertiary),
                      ),
                      child: TextField(
                        maxLines: 4,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        decoration: InputDecoration(
                          hintText: isArabic
                              ? 'اكتب تعليقك هنا (اختياري)'
                              : 'Write your feedback here (optional)',
                          hintStyle: GoogleFonts.cairo(
                            color: AppTheme.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (value) => _feedbackText = value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ENRButton(
                text: isArabic ? 'إرسال التقييم' : 'Submit Rating',
                onPressed: () {
                  if (_rating > 0) {
                    _submitRating(context, isArabic, _feedbackText);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic ? 'الرجاء اختيار تقييم أولاً' : 'Please select a rating first',
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: AppTheme.warningAmber,
                      ),
                    );
                  }
                },
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(bool isArabic) {
    if (_rating == 5) return isArabic ? 'ممتاز! 5 نجوم' : 'Excellent! 5 Stars';
    if (_rating >= 4) return isArabic ? 'جيد جداً 4 نجوم' : 'Very Good 4 Stars';
    if (_rating >= 3) return isArabic ? 'جيد 3 نجوم' : 'Good 3 Stars';
    if (_rating >= 2) return isArabic ? 'مقبول نجمتان' : 'Fair 2 Stars';
    return isArabic ? 'سيء نجمة واحدة' : 'Poor 1 Star';
  }

  void _submitRating(BuildContext context, bool isArabic, String feedback) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfacePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          Icons.check_circle_outline,
          color: AppTheme.successGreen,
          size: 60,
        ),
        content: Text(
          isArabic
              ? 'شكراً لتقييمك التطبيق! \nتقييمك يساعدنا في التحسين المستمر.'
              : 'Thank you for rating the app! \nYour feedback helps us improve continuously.',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: AppTheme.textPrimary,
            fontSize: 16,
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentDefault,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                isArabic ? 'حسناً' : 'OK',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}