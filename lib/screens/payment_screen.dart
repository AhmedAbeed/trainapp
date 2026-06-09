import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final TrainSchedule train;
  final String selectedClass;
  final int selectedSeatNumber;
  final DateTime date;

  const PaymentScreen({
    super.key,
    required this.train,
    required this.selectedClass,
    required this.selectedSeatNumber,
    required this.date,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _paymentMethod = 0; // 0=card, 1=wallet, 2=cash
  bool _isProcessing = false;
  final _cardCtrl = TextEditingController(text: '4242 4242 4242 4242');
  final _expiryCtrl = TextEditingController(text: '12/26');
  final _cvvCtrl = TextEditingController(text: '123');

  Future<void> _pay() async {
    setState(() => _isProcessing = true);
    
    // محاكاة وقت المعالجة
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final appState = context.read<AppState>();
    final isArabic = appState.isArabic;
    final String dateString = '${widget.date.day}/${widget.date.month}/${widget.date.year}';

    try {
      // ✅ استخدام Firestore Transaction لضمان عدم حجز المقعد مرتين (Race Condition)
      final bookingId = 'BK-${DateTime.now().millisecondsSinceEpoch}';
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. التحقق من توفر المقعد (قراءة)
        final conflictQuery = await FirebaseFirestore.instance
            .collection('bookings')
            .where('trainNumber', isEqualTo: widget.train.trainNumber)
            .where('date', isEqualTo: dateString)
            .where('seatNumber', isEqualTo: widget.selectedSeatNumber)
            .where('status', whereIn: ['valid', 'scanned'])
            .get();

        if (conflictQuery.docs.isNotEmpty) {
          throw Exception('SEAT_TAKEN');
        }

        // 2. إذا كان متاحاً، يتم الحجز (كتابة)
        transaction.set(bookingRef, {
          'bookingId': bookingId,
          'ticketNumber': 'ENR-${widget.train.trainNumber}-S${widget.selectedSeatNumber}',
          'passengerName': appState.currentUser?.name ?? (isArabic ? 'الراكب' : 'Passenger'),
          'trainNumber': widget.train.trainNumber,
          'trainName': widget.train.trainName,
          'from': widget.train.from.name,
          'to': widget.train.to.name,
          'departureTime': widget.train.departureTime,
          'arrivalTime': widget.train.arrivalTime,
          'date': dateString,
          'seatClass': widget.selectedClass,
          'seatNumber': widget.selectedSeatNumber,
          'price': widget.train.prices[widget.selectedClass]!,
          'status': 'valid',
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'stops': widget.train.stops.map((s) => s.name).toList(),
          'currentStopIndex': 0,
        });
      });

      // نجح الحجز في Firestore، الآن نقوم بتحديث الحالة المحلية
      final booking = Booking(
        bookingId: bookingId,
        ticketNumber: 'ENR-${widget.train.trainNumber}-S${widget.selectedSeatNumber}',
        passengerName: appState.currentUser?.name ?? (isArabic ? 'الراكب' : 'Passenger'),
        trainNumber: widget.train.trainNumber,
        trainName: widget.train.trainName,
        from: widget.train.from,
        to: widget.train.to,
        departureTime: widget.train.departureTime,
        arrivalTime: widget.train.arrivalTime,
        date: dateString,
        seatClass: widget.selectedClass,
        seatNumber: widget.selectedSeatNumber,
        price: widget.train.prices[widget.selectedClass]!,
        status: BookingStatus.valid,
        stops: widget.train.stops,
        currentStopIndex: 0,
      );

      // حفظ في AppState (سيقوم بعمل set مكرر ولكنه يضمن مزامنة التنبيهات والـ Topic)
      await appState.saveAndSetBooking(booking);

      if (!mounted) return;

      // التوجه إلى HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 0)),
        (r) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تم الحجز بنجاح! 🎉' : 'Booking successful! 🎉',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } on Exception catch (e) {
      if (e.toString().contains('SEAT_TAKEN')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic 
              ? 'عذراً، المقعد ${widget.selectedSeatNumber} تم حجزه للتو. يرجى اختيار مقعد آخر.' 
              : 'Sorry, seat ${widget.selectedSeatNumber} was just booked. Please choose another seat.'),
          backgroundColor: Colors.red,
        ));
        Navigator.pop(context); // العودة لصفحة اختيار المقاعد
      } else {
        debugPrint('❌ Payment Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isArabic ? 'حدث خطأ أثناء الدفع، يرجى المحاولة مرة أخرى.' : 'Payment error, please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;
    final price = widget.train.prices[widget.selectedClass]!;

    final List<Map<String, dynamic>> methods = isArabic
        ? [
      {'icon': Icons.credit_card, 'label': 'بطاقة بنكية'},
      {'icon': Icons.account_balance_wallet, 'label': 'محفظة إلكترونية'},
      {'icon': Icons.money, 'label': 'دفع عند الشباك'},
    ]
        : [
      {'icon': Icons.credit_card, 'label': 'Bank Card'},
      {'icon': Icons.account_balance_wallet, 'label': 'Wallet'},
      {'icon': Icons.money, 'label': 'Cash at Counter'},
    ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'إتمام الدفع' : 'Payment'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary).withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      isArabic ? 'ملخص الرحلة' : 'Trip Summary',
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _summaryRow(isArabic ? 'القطار' : 'Train', SampleData.getTrainName(widget.train.trainName, isArabic), isDark),
                    _summaryRow(isArabic ? 'رقم القطار' : 'Train No.', widget.train.trainNumber, isDark),
                    _summaryRow(isArabic ? 'من' : 'From', SampleData.getStationName(widget.train.from, isArabic), isDark),
                    _summaryRow(isArabic ? 'إلى' : 'To', SampleData.getStationName(widget.train.to, isArabic), isDark),
                    _summaryRow(isArabic ? 'الموعد' : 'Time', '${widget.train.departureTime} → ${widget.train.arrivalTime}', isDark),
                    _summaryRow(isArabic ? 'الدرجة' : 'Class', SampleData.getClassName(widget.selectedClass, isArabic), isDark),
                    _summaryRow(isArabic ? 'رقم المقعد' : 'Seat No.', '${widget.selectedSeatNumber}', isDark),
                    Divider(color: isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isArabic ? 'الإجمالي' : 'Total',
                            style: GoogleFonts.cairo(
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        Text('$price ${isArabic ? 'جنيه' : 'EGP'}',
                            style: GoogleFonts.cairo(
                                color: AppTheme.accentDefault,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                isArabic ? 'طريقة الدفع' : 'Payment Method',
                style: GoogleFonts.cairo(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(methods.length, (i) {
                  final m = methods[i];
                  final sel = _paymentMethod == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMethod = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(left: i < methods.length - 1 ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.accentDefault.withValues(alpha: 0.1) : (isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? AppTheme.accentDefault : (isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary),
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(m['icon'] as IconData,
                                color: sel ? AppTheme.accentDefault : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary), size: 22),
                            const SizedBox(height: 6),
                            Text(
                              m['label'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: sel ? AppTheme.accentDefault : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                fontSize: 11,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),

              if (_paymentMethod == 0) ...[
                const SizedBox(height: 20),
                Text(
                  isArabic ? 'بيانات البطاقة' : 'Card Details',
                  style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.inter(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 16, letterSpacing: 2),
                  decoration: InputDecoration(
                    labelText: isArabic ? 'رقم البطاقة' : 'Card Number',
                    prefixIcon: Icon(Icons.credit_card, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryCtrl,
                        textAlign: TextAlign.left,
                        textDirection: TextDirection.ltr,
                        style: GoogleFonts.inter(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 14),
                        decoration: InputDecoration(labelText: isArabic ? 'تاريخ الانتهاء' : 'Expiry Date'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvCtrl,
                        textAlign: TextAlign.left,
                        textDirection: TextDirection.ltr,
                        obscureText: true,
                        style: GoogleFonts.inter(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 14),
                        decoration: const InputDecoration(labelText: 'CVV'),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              ENRButton(
                text: isArabic ? 'ادفع $price جنيه' : 'Pay $price EGP',
                onPressed: _pay,
                isLoading: _isProcessing,
                icon: Icons.lock_outline,
              ),

              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security, color: AppTheme.successGreen, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isArabic ? 'دفع آمن ومشفر' : 'Secure & Encrypted Payment',
                      style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12),
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

  Widget _summaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
