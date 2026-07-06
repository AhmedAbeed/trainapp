import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/models.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToTrainStatus();
    });
  }

  void _listenToTrainStatus() {
    final appState = context.read<AppState>();
    final trainNumber = appState.currentBooking?.trainNumber;
    if (trainNumber == null) return;

    FirebaseFirestore.instance
        .collection('train_statuses')
        .doc(trainNumber)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        final data = snap.data() as Map<String, dynamic>;
        final statusStr = data['status'] ?? 'running';
        TrainStatus status = TrainStatus.running;
        switch (statusStr) {
          case 'delayed': status = TrainStatus.delayed; break;
          case 'cancelled': status = TrainStatus.cancelled; break;
          case 'accident': status = TrainStatus.accident; break;
        }
        
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final booking = appState.currentBooking;
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;

    if (booking == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentDefault),
        ),
      );
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(isArabic ? 'تذكرتي' : 'My Ticket', style: GoogleFonts.cairo()),
              backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _TicketCard(booking: booking, isDark: isDark, isArabic: isArabic),
                    const SizedBox(height: 20),
                    _QRSection(booking: booking, isDark: isDark, isArabic: isArabic),
                    const SizedBox(height: 20),
                    _StatusSection(booking: booking, isDark: isDark, isArabic: isArabic),
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
}

class _TicketCard extends StatelessWidget {
  final Booking booking;
  final bool isDark;
  final bool isArabic;

  const _TicketCard({required this.booking, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentDefault.withValues(alpha: 0.15), Colors.transparent],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ENR', style: GoogleFonts.inter(color: AppTheme.accentDefault, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    _StatusBadge(status: booking.status, isDark: isDark, isArabic: isArabic),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.departureTime, style: GoogleFonts.inter(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
                          Text(SampleData.getStationName(booking.from, isArabic), style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: AppTheme.accentDefault, size: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(booking.arrivalTime, style: GoogleFonts.inter(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
                          Text(SampleData.getStationName(booking.to, isArabic), style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Row(
              children: [
                Container(width: 20, height: 20, decoration: BoxDecoration(color: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault, shape: BoxShape.circle)),
                Expanded(
                  child: LayoutBuilder(builder: (_, c) {
                    return Flex(
                      direction: Axis.horizontal,
                      children: List.generate((c.maxWidth / 8).floor(), (_) => Container(width: 4, height: 1.5, color: isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary, margin: const EdgeInsets.symmetric(horizontal: 2))),
                    );
                  }),
                ),
                Container(width: 20, height: 20, decoration: BoxDecoration(color: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault, shape: BoxShape.circle)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _infoItem(isArabic ? 'رقم القطار' : 'Train No.', booking.trainNumber, isDark),
                    _infoItem(isArabic ? 'الدرجة' : 'Class', SampleData.getClassName(booking.seatClass, isArabic), isDark),
                    _infoItem(isArabic ? 'المقعد' : 'Seat', '${booking.seatNumber}', isDark),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _infoItem(isArabic ? 'التاريخ' : 'Date', booking.date, isDark),
                    _infoItem(isArabic ? 'الراكب' : 'Passenger', booking.passengerName, isDark),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: AppTheme.accentDefault, size: 16),
                      const SizedBox(width: 8),
                      Text('${isArabic ? 'رقم التذكرة:' : 'Ticket No.:'} ${booking.ticketNumber}', style: GoogleFonts.inter(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value, style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QRSection extends StatelessWidget {
  final Booking booking;
  final bool isDark;
  final bool isArabic;

  const _QRSection({required this.booking, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(isArabic ? 'رمز الاستجابة السريعة' : 'QR Code', style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(isArabic ? 'اعرض هذا الرمز للكومسري' : 'Show this code to the conductor', style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: QrImageView(data: '${booking.ticketNumber}|${booking.passengerName}|${booking.trainNumber}', version: QrVersions.auto, size: 160, backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final Booking booking;
  final bool isDark;
  final bool isArabic;

  const _StatusSection({required this.booking, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    String statusText;
    if (booking.status == BookingStatus.scanned) {
      statusText = isArabic ? 'تم تسجيل الدخول للقطار' : 'Checked in to train';
    } else if (booking.status == BookingStatus.valid) {
      statusText = isArabic ? 'التذكرة صالحة للسفر' : 'Ticket is valid for travel';
    } else {
      statusText = isArabic ? 'التذكرة غير صالحة' : 'Ticket is invalid';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isArabic ? 'حالة التذكرة' : 'Ticket Status', style: GoogleFonts.cairo(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              _StatusBadge(status: booking.status, isDark: isDark, isArabic: isArabic),
            ],
          ),
          const SizedBox(height: 16),
          _statusInfo(statusText, booking.status == BookingStatus.scanned ? AppTheme.warningAmber : booking.status == BookingStatus.valid ? AppTheme.successGreen : AppTheme.accentDefault, isDark),
        ],
      ),
    );
  }

  Widget _statusInfo(String msg, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 10),
          Text(msg, style: GoogleFonts.cairo(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool isDark;
  final bool isArabic;

  const _StatusBadge({required this.status, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;

    switch (status) {
      case BookingStatus.valid:
        text = isArabic ? 'صالحة' : 'Valid';
        color = AppTheme.successGreen;
        break;
      case BookingStatus.scanned:
        text = isArabic ? 'تم الاستخدام' : 'Used';
        color = AppTheme.warningAmber;
        break;
      case BookingStatus.invalid:
        text = isArabic ? 'غير صالحة' : 'Invalid';
        color = AppTheme.accentDefault;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: GoogleFonts.cairo(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
