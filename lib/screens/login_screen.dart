import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_widgets.dart';
import '../services/app_state.dart';

import 'register_screen.dart';
import 'home_screen.dart';
import 'train_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false;
  String? _errorMessage;

  late AnimationController _logoAnim;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = CurvedAnimation(parent: _logoAnim, curve: Curves.elasticOut);
    _logoAnim.forward();

    // ✅ تسجيل خروج تلقائي عند فتح التطبيق عشان يظهر Login
    FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _logoAnim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;

      if (_isAdmin) {
        await auth.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        if (!mounted) return;
        final state = context.read<AppState>();
        await state.loginAsAdmin(_emailCtrl.text, _passCtrl.text);

        if (!mounted) return;
        // ✅ بعد تسجيل الدخول - نروح لشاشة اختيار القطار (للكوميسيري)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrainSelectionScreen()),
        );
      } else {
        final userCredential = await auth.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        final userData = userDoc.data();

        // ✅ جلب عدد الحجوزات فقط لمعرفة إذا كان المستخدم لديه حجز
        final bookingsCount = await firestore
            .collection('bookings')
            .where('userId', isEqualTo: userCredential.user!.uid)
            .count()
            .get();

        final hasBooking = (bookingsCount.count ?? 0) > 0;

        if (!mounted) return;
        final state = context.read<AppState>();

        // ✅ loginWithNameAndEmailAndBooking يستدعي loadLatestBooking تلقائياً
        if (userData != null && userData['name'] != null) {
          await state.loginWithNameAndEmailAndBooking(
            userData['name'],
            _emailCtrl.text.trim(),
            hasBooking,
          );
        } else {
          await state.loginWithBookingStatus(
            _emailCtrl.text.trim(),
            hasBooking,
          );
        }

        if (!mounted) return;
        if (hasBooking) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 0)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 2)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ Firebase Auth Error Code: ${e.code}');
      debugPrint('❌ Firebase Auth Error Message: ${e.message}');
      debugPrint('═══════════════════════════════════════');

      setState(() {
        final isArabic = context.read<AppState>().isArabic;
        if (e.code == 'user-not-found') {
          _errorMessage = isArabic
              ? 'لا يوجد حساب بهذا البريد. يرجى التسجيل أولاً'
              : 'No account found with this email. Please register first.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = isArabic ? 'كلمة المرور غير صحيحة' : 'Wrong password';
        } else if (e.code == 'invalid-email') {
          _errorMessage =
              isArabic ? 'البريد الإلكتروني غير صالح' : 'Invalid email';
        } else if (e.code == 'network-request-failed') {
          _errorMessage = isArabic
              ? 'مشكلة في الاتصال بالإنترنت'
              : 'Network connection issue';
        } else if (e.code == 'too-many-requests') {
          _errorMessage = isArabic
              ? 'تم إرسال العديد من المحاولات. حاول لاحقاً'
              : 'Too many requests. Try again later.';
        } else {
          _errorMessage =
              isArabic ? 'حدث خطأ: ${e.message}' : 'Error: ${e.message}';
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

    final appTitle = isArabic ? 'قطار مصر' : 'Masr Train';
    final subtitle =
        isArabic ? 'سافر بسهولة وأمان' : 'Travel easily and safely';
    final userBtn = isArabic ? 'مستخدم' : 'User';
    final adminBtn = isArabic ? 'مدير / كومسري' : 'Admin / Commissary';
    final emailLabel = isArabic ? 'البريد الإلكتروني' : 'Email';
    final passwordLabel = isArabic ? 'كلمة المرور' : 'Password';
    final forgotPassword = isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
    final loginBtn = isArabic ? 'تسجيل الدخول' : 'Login';
    final noAccount = isArabic ? 'ليس لديك حساب؟' : "Don't have an account?";
    final createAccount = isArabic ? 'إنشاء حساب' : 'Create Account';

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/train_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.5),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: DropdownButton<bool>(
                            value: isArabic,
                            underline: const SizedBox(),
                            icon: Icon(Icons.language,
                                color: Colors.red, size: 20),
                            style: GoogleFonts.cairo(
                                color: Colors.white, fontSize: 14),
                            dropdownColor: const Color(0xFF1A1A1A),
                            items: const [
                              DropdownMenuItem(
                                  value: true, child: Text('العربية')),
                              DropdownMenuItem(
                                  value: false, child: Text('English')),
                            ],
                            onChanged: (value) {
                              if (value != null) appState.setArabic(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                )
                              ],
                              image: DecorationImage(
                                image: AssetImage('assets/images/logo.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            appTitle,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _buildToggleBtn(userBtn, false, isArabic),
                                  _buildToggleBtn(adminBtn, true, isArabic),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  ENRTextField(
                                    label: emailLabel,
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.email_outlined,
                                    validator: (v) => v!.isEmpty
                                        ? (isArabic ? 'مطلوب' : 'Required')
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  ENRTextField(
                                    label: passwordLabel,
                                    controller: _passCtrl,
                                    obscureText: true,
                                    prefixIcon: Icons.lock_outline,
                                    validator: (v) => v!.isEmpty
                                        ? (isArabic ? 'مطلوب' : 'Required')
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  if (_errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.cairo(
                                            color: Colors.red.shade300,
                                            fontSize: 13),
                                      ),
                                    ),
                                  Align(
                                    alignment: isArabic
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        forgotPassword,
                                        style: GoogleFonts.cairo(
                                            color: Colors.red, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ENRButton(
                                    text: loginBtn,
                                    onPressed: _login,
                                    isLoading: _isLoading,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (!_isAdmin)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    noAccount,
                                    style: GoogleFonts.cairo(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    ),
                                    child: Text(
                                      createAccount,
                                      style: GoogleFonts.cairo(
                                        color: Colors.red,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isAdminBtn, bool isArabic) {
    final selected = _isAdmin == isAdminBtn;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isAdmin = isAdminBtn),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
