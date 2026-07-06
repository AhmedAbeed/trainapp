import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/app_state.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      await firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      final appState = context.read<AppState>();

      await appState.registerAndLogin(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 2)),
            (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ Register Error Code: ${e.code}');
      debugPrint('❌ Register Error Message: ${e.message}');
      debugPrint('═══════════════════════════════════════');

      setState(() {
        final isArabic = context.read<AppState>().isArabic;
        if (e.code == 'email-already-in-use') {
          _errorMessage = isArabic
              ? 'البريد الإلكتروني مستخدم بالفعل. يرجى تسجيل الدخول'
              : 'Email already in use. Please login.';
        } else if (e.code == 'weak-password') {
          _errorMessage = isArabic ? 'كلمة المرور ضعيفة (6 أحرف على الأقل)' : 'Weak password (min 6 characters)';
        } else if (e.code == 'invalid-email') {
          _errorMessage = isArabic ? 'البريد الإلكتروني غير صالح' : 'Invalid email';
        } else if (e.code == 'network-request-failed') {
          _errorMessage = isArabic ? 'مشكلة في الاتصال بالإنترنت' : 'Network connection issue';
        } else {
          _errorMessage = isArabic ? 'حدث خطأ: ${e.message}' : 'Error: ${e.message}';
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    final appBarTitle = isArabic ? 'إنشاء حساب جديد' : 'Create New Account';
    final sectionTitle = isArabic ? 'مرحباً بك!' : 'Welcome!';
    final sectionSubtitle = isArabic ? 'أنشئ حسابك وابدأ رحلتك' : 'Create your account and start your journey';
    final fullNameLabel = isArabic ? 'الاسم الكامل' : 'Full Name';
    final emailLabel = isArabic ? 'البريد الإلكتروني' : 'Email';
    final phoneLabel = isArabic ? 'رقم الهاتف' : 'Phone Number';
    final passwordLabel = isArabic ? 'كلمة المرور' : 'Password';
    final confirmPasswordLabel = isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
    final registerBtn = isArabic ? 'إنشاء الحساب' : 'Create Account';
    final termsText = isArabic
        ? 'بالتسجيل، أنت توافق على شروط الاستخدام وسياسة الخصوصية'
        : 'By signing up, you agree to the Terms of Use and Privacy Policy';
    final requiredField = isArabic ? 'مطلوب' : 'Required';
    final invalidEmail = isArabic ? 'بريد إلكتروني غير صالح' : 'Invalid email address';
    final shortPassword = isArabic ? 'كلمة المرور قصيرة جداً (6 أحرف على الأقل)' : 'Password is too short (min 6 characters)';
    final passwordMismatch = isArabic ? 'كلمات المرور غير متطابقة' : 'Passwords do not match';

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle, style: GoogleFonts.cairo()),
          leading: IconButton(
            icon: Icon(isArabic ? Icons.arrow_back_ios_new : Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfacePrimary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentDefault.withValues(alpha: 0.3)),
              ),
              child: DropdownButton<bool>(
                value: isArabic,
                underline: const SizedBox(),
                icon: Icon(Icons.language, color: AppTheme.accentDefault, size: 20),
                style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 14),
                dropdownColor: AppTheme.surfacePrimary,
                items: const [
                  DropdownMenuItem(value: true, child: Text('العربية')),
                  DropdownMenuItem(value: false, child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) appState.setArabic(value);
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(title: sectionTitle, subtitle: sectionSubtitle),
                const SizedBox(height: 32),
                ENRTextField(
                  label: fullNameLabel,
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? requiredField : null,
                ),
                const SizedBox(height: 16),
                ENRTextField(
                  label: emailLabel,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v!.isEmpty) return requiredField;
                    if (!v.contains('@')) return invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ENRTextField(
                  label: phoneLabel,
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (v) => v!.isEmpty ? requiredField : null,
                ),
                const SizedBox(height: 16),
                ENRTextField(
                  label: passwordLabel,
                  controller: _passCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v!.isEmpty) return requiredField;
                    if (v.length < 6) return shortPassword;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ENRTextField(
                  label: confirmPasswordLabel,
                  controller: _confirmPassCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v!.isEmpty) return requiredField;
                    if (v != _passCtrl.text) return passwordMismatch;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_errorMessage!, style: GoogleFonts.cairo(color: Colors.red.shade300, fontSize: 13)),
                  ),
                const SizedBox(height: 16),
                ENRButton(
                  text: registerBtn,
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    termsText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
