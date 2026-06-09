import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'help_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final isArabic = appState.isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
              actions: [
                // ✅ زر اختيار اللغة في AppBar
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.accentDefault.withValues(alpha: 0.3),
                    ),
                  ),
                  child: DropdownButton<bool>(
                    value: isArabic,
                    underline: const SizedBox(),
                    icon: Icon(Icons.language, color: AppTheme.accentDefault, size: 20),
                    style: GoogleFonts.cairo(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      fontSize: 14,
                    ),
                    dropdownColor: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                    items: const [
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Text('العربية'),
                      ),
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        appState.setArabic(value);
                      }
                    },
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showEditDialog(context, user, appState),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.accentDefault.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.accentDefault, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  user?.name.substring(0, 1).toUpperCase() ?? (isArabic ? 'م' : 'U'),
                                  style: GoogleFonts.cairo(
                                      color: AppTheme.accentDefault,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => _showEditDialog(context, user, appState),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user?.name ?? (isArabic ? 'المستخدم' : 'User'),
                                  style: GoogleFonts.cairo(
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.edit, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, size: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.accentDefault.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.accentDefault.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              isArabic ? 'مستخدم نشط' : 'Active User',
                              style: GoogleFonts.cairo(color: AppTheme.accentDefault, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Personal info
                    _Section(
                      title: isArabic ? 'البيانات الشخصية' : 'Personal Information',
                      isDark: isDark,
                      children: [
                        _InfoTile(
                          icon: Icons.person_outline,
                          label: isArabic ? 'الاسم الكامل' : 'Full Name',
                          value: user?.name ?? '-',
                          isDark: isDark,
                        ),
                        _InfoTile(
                          icon: Icons.email_outlined,
                          label: isArabic ? 'البريد الإلكتروني' : 'Email',
                          value: user?.email ?? '-',
                          isDark: isDark,
                        ),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: isArabic ? 'رقم الهاتف' : 'Phone Number',
                          value: user?.phone ?? '-',
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Settings
                    _Section(
                      title: isArabic ? 'الإعدادات' : 'Settings',
                      isDark: isDark,
                      children: [
                        _ToggleTile(
                          icon: Icons.notifications_outlined,
                          label: isArabic ? 'الإشعارات' : 'Notifications',
                          onChanged: (value) {
                            appState.setNotificationsEnabled(value);
                            if (value) {
                              _showNotification(context, appState);
                            }
                          },
                          initial: appState.notificationsEnabled,
                          isDark: isDark,
                        ),
                        // ✅ ملاحظة: زر اللغة موجود في AppBar وليس هنا
                        _ToggleTile(
                          icon: Icons.dark_mode_outlined,
                          label: isArabic ? 'الوضع الداكن' : 'Dark Mode',
                          onChanged: (value) {
                            appState.setDarkMode(value);
                          },
                          initial: appState.isDarkMode,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Support
                    _Section(
                      title: isArabic ? 'الدعم' : 'Support',
                      isDark: isDark,
                      children: [
                        _ActionTile(
                          icon: Icons.notifications_none_outlined,
                          label: isArabic ? 'الإشعارات' : 'Notifications',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                          isDark: isDark,
                        ),
                        _ActionTile(
                          icon: Icons.help_outline,
                          label: isArabic ? 'مركز المساعدة' : 'Help Center',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HelpScreen()),
                            );
                          },
                          isDark: isDark,
                        ),
                        _ActionTile(
                          icon: Icons.policy_outlined,
                          label: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                            );
                          },
                          isDark: isDark,
                        ),
                        _ActionTile(
                          icon: Icons.star_outline,
                          label: isArabic ? 'تقييم التطبيق' : 'Rate App',
                          onTap: () {
                            _showRatingDialog(context, appState);
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    ENRButton(
                      text: isArabic ? 'تسجيل الخروج' : 'Logout',
                      onPressed: () {
                        _showLogoutDialog(context, appState);
                      },
                      color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                      textColor: AppTheme.accentDefault,
                      icon: Icons.logout,
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, user, AppState appState) {
    final isDark = appState.isDarkMode;
    final isArabic = appState.isArabic;
    final nameCtrl = TextEditingController(text: user?.name);
    final emailCtrl = TextEditingController(text: user?.email);
    final phoneCtrl = TextEditingController(text: user?.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
        title: Text(
          isArabic ? 'تعديل البيانات الشخصية' : 'Edit Personal Info',
          style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ENRTextField(
              label: isArabic ? 'الاسم الكامل' : 'Full Name',
              controller: nameCtrl,
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            ENRTextField(
              label: isArabic ? 'البريد الإلكتروني' : 'Email',
              controller: emailCtrl,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 12),
            ENRTextField(
              label: isArabic ? 'رقم الهاتف' : 'Phone Number',
              controller: phoneCtrl,
              prefixIcon: Icons.phone_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isArabic ? 'إلغاء' : 'Cancel',
              style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              appState.updateUser(
                name: nameCtrl.text,
                email: emailCtrl.text,
                phone: phoneCtrl.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic ? 'تم تحديث البيانات بنجاح' : 'Profile updated successfully',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentDefault,
            ),
            child: Text(
              isArabic ? 'حفظ' : 'Save',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotification(BuildContext context, AppState appState) {
    final isArabic = appState.isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? 'تم تفعيل الإشعارات' : 'Notifications enabled',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _showRatingDialog(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final isArabic = appState.isArabic;
    double rating = 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
        title: Text(
          isArabic ? 'قيم التطبيق' : 'Rate App',
          style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic ? 'ما مدى رضاك عن التطبيق؟' : 'How satisfied are you with the app?',
              style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() => rating = index + 1.0);
                      },
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: AppTheme.warningAmber,
                        size: 40,
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isArabic ? 'لاحقاً' : 'Later',
              style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic
                        ? 'شكراً لتقييمك ${rating.toStringAsFixed(0)} نجوم 🌟'
                        : 'Thanks for rating $rating stars 🌟',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentDefault,
            ),
            child: Text(
              isArabic ? 'إرسال' : 'Submit',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final isArabic = appState.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
        title: Text(
          isArabic ? 'تسجيل الخروج' : 'Logout',
          style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
        ),
        content: Text(
          isArabic ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟' : 'Are you sure you want to logout?',
          style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isArabic ? 'إلغاء' : 'Cancel',
              style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              appState.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentDefault,
            ),
            child: Text(
              isArabic ? 'تسجيل خروج' : 'Logout',
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _Section({required this.title, required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentDefault, size: 20),
      title: Text(label, style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12)),
      subtitle: Text(value, style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 14)),
      dense: true,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool initial;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.onChanged,
    required this.isDark,
    this.initial = false,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool value = initial;
        return ListTile(
          leading: Icon(icon, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, size: 20),
          title: Text(label, style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 14)),
          trailing: Switch(
            value: value,
            onChanged: (v) {
              setState(() => value = v);
              onChanged(v);
            },
            activeThumbColor: AppTheme.accentDefault,
            inactiveThumbColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            inactiveTrackColor: isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary,
          ),
          dense: true,
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionTile({required this.icon, required this.label, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, size: 20),
      title: Text(label, style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, size: 14),
      onTap: onTap,
      dense: true,
    );
  }
}