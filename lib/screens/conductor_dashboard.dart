import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import 'incident_report_screen.dart';
import 'issue_ticket_screen.dart';
import 'train_status_manager_screen.dart';
import 'qr_scanner_screen.dart';
import 'login_screen.dart';

class ConductorDashboard extends StatefulWidget {
  final TrainSchedule train;
  const ConductorDashboard({super.key, required this.train});

  @override
  State<ConductorDashboard> createState() => _ConductorDashboardState();
}

class _ConductorDashboardState extends State<ConductorDashboard>
    with SingleTickerProviderStateMixin {
  List<Booking> _allBookings = [];
  final List<PassengerOnboard> _passengersOnboard = [];
  final List<IncidentReport> _incidentReports = [];

  String _filter = 'الكل';
  final _filters = ['الكل', 'صالحة', 'تم التحقق'];
  late TabController _tabController;

  int _currentPassengersCount = 0;
  int _departedPassengersCount = 0;
  final int _totalSeats = 180;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  BookingStatus _parseStatus(String? status) {
    switch (status) {
      case 'scanned': return BookingStatus.scanned;
      case 'invalid': return BookingStatus.invalid;
      case 'valid':
      default: return BookingStatus.valid;
    }
  }

  void _loadData() {
    setState(() => _isLoading = true);
    FirebaseFirestore.instance
        .collection('bookings')
        .where('trainNumber', isEqualTo: widget.train.trainNumber)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final bookings = snapshot.docs.map((doc) {
          final data = doc.data();
          return Booking(
            bookingId: doc.id,
            ticketNumber: data['ticketNumber'] ?? '',
            passengerName: data['passengerName'] ?? '',
            trainNumber: data['trainNumber'] ?? '',
            trainName: data['trainName'] ?? '',
            from: SampleData.getStation(data['from'] ?? 'القاهرة'),
            to: SampleData.getStation(data['to'] ?? 'الإسكندرية'),
            departureTime: data['departureTime'] ?? '',
            arrivalTime: data['arrivalTime'] ?? '',
            date: data['date'] ?? '',
            seatClass: data['seatClass'] ?? '',
            seatNumber: data['seatNumber'] ?? 0,
            price: data['price'] ?? 0,
            status: _parseStatus(data['status']),
            stops: [],
            currentStopIndex: 0,
          );
        }).toList();

        setState(() {
          _allBookings = bookings;
          _isLoading = false;
          _currentPassengersCount = bookings.where((b) => b.status == BookingStatus.scanned).length;
        });
      }
    });
  }

  List<Booking> get _filteredBookings {
    switch (_filter) {
      case 'صالحة': return _allBookings.where((b) => b.status == BookingStatus.valid).toList();
      case 'تم التحقق': return _allBookings.where((b) => b.status == BookingStatus.scanned).toList();
      case 'غير صالحة': return _allBookings.where((b) => b.status == BookingStatus.invalid).toList();
      default: return _allBookings;
    }
  }

  List<PassengerOnboard> get _filteredPassengersByTrain => _passengersOnboard;
  List<IncidentReport> get _filteredReportsByTrain => _incidentReports;

  Future<void> _scanTicket(Booking booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.bookingId)
          .update({'status': 'scanned'});

      await _sendNotificationToUser(booking);

      if (mounted) {
        _showSnackBar('تم تسجيل دخول ${booking.passengerName} بنجاح', AppTheme.successGreen);
      }
    } catch (e) {
      debugPrint('❌ Scan Error: $e');
    }
  }

  Future<void> _sendNotificationToUser(Booking booking) async {
    try {
      final String? userId = await _getUserIdOfBooking(booking.bookingId);
      if (userId == null) return;

      final isArabic = context.read<AppState>().isArabic;
      final title = isArabic ? '🎫 تم التحقق من تذكرتك' : '🎫 Ticket Verified';
      final body = isArabic 
          ? 'أهلاً بك على متن القطار ${booking.trainNumber}. رحلة سعيدة!' 
          : 'Welcome aboard train ${booking.trainNumber}. Have a nice trip!';

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'ticket_scanned',
        'trainNumber': booking.trainNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      await FirebaseFirestore.instance.collection('fcm_requests').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': {
          'type': 'ticket_scanned',
          'bookingId': booking.bookingId,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Notification failed: $e');
    }
  }

  Future<String?> _getUserIdOfBooking(String bookingId) async {
    final doc = await FirebaseFirestore.instance.collection('bookings').doc(bookingId).get();
    return doc.data()?['userId'] as String?;
  }

  void _departPassenger(PassengerOnboard passenger) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد المغادرة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          content: Text('هل تم نزول ${passenger.name} من القطار؟', style: GoogleFonts.cairo()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final idx = _passengersOnboard.indexWhere((p) => p.id == passenger.id);
                  if (idx != -1) {
                    _passengersOnboard[idx].hasDeparted = true;
                    _passengersOnboard[idx].departedAt = DateTime.now();
                    _currentPassengersCount--;
                    _departedPassengersCount++;
                  }
                });
                Navigator.pop(ctx);
                _showSnackBar('تم تسجيل مغادرة ${passenger.name}', AppTheme.infoBlue);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentDefault),
              child: Text('تأكيد', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  void _issueNewTicket() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const IssueTicketScreen()));
    if (result != null && result is Booking) {
      _showSnackBar('✅ تم إصدار تذكرة جديدة', AppTheme.successGreen);
    }
  }

  void _createIncidentReport() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentReportScreen()));
    if (result != null && result is IncidentReport) {
      _showSnackBar('✅ تم إنشاء محضر رقم ${result.reportNumber}', AppTheme.warningAmber);
    }
  }

  void _viewIncidentReport(IncidentReport report) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تفاصيل المحضر', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('رقم المحضر', report.reportNumber),
              _detailRow('المخالف', report.passengerName),
              _detailRow('الرقم القومي', report.nationalId),
              _detailRow('المحطة', report.station),
              _detailRow('نوع المخالفة', report.violationType),
              _detailRow('الوصف', report.description),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إغلاق', style: GoogleFonts.cairo())),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text('$label: ', style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 12))),
          Expanded(child: Text(value, style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 12))),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isArabic = context.read<AppState>().isArabic;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(isArabic ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟' : 'Are you sure you want to logout?', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isArabic ? 'إلغاء' : 'Cancel', style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              context.read<AppState>().logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isArabic ? 'تسجيل خروج' : 'Logout', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('قطار ${widget.train.trainNumber}', style: GoogleFonts.cairo()),
          backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
          actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () => _showLogoutDialog(context))],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(SampleData.getTrainName(widget.train.trainName, isArabic), style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              Text('${widget.train.trainNumber} | ${SampleData.getStationName(widget.train.from, isArabic)} → ${SampleData.getStationName(widget.train.to, isArabic)}', style: GoogleFonts.cairo(fontSize: 12)),
            ],
          ),
          backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: isArabic ? 'التذاكر' : 'Tickets', icon: const Icon(Icons.confirmation_number_outlined)),
              Tab(text: isArabic ? 'الركاب' : 'Passengers', icon: const Icon(Icons.people_outline)),
              Tab(text: isArabic ? 'التقارير' : 'Reports', icon: const Icon(Icons.report_outlined)),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () => _showLogoutDialog(context))],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
              child: Row(
                children: [
                  _infoBox(isArabic ? 'عدد التذاكر' : 'Tickets Count', '${_allBookings.length}', AppTheme.accentDefault),
                  _infoBox(isArabic ? 'ركاب حالياً' : 'Current Passengers', '$_currentPassengersCount', AppTheme.successGreen),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _issueNewTicket,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(isArabic ? 'إصدار تذكرة' : 'Issue Ticket'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createIncidentReport,
                          icon: const Icon(Icons.warning_amber_outlined, size: 18),
                          label: Text(isArabic ? 'محضر شغب' : 'Incident Report'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentDefault, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainStatusManagerScreen())),
                          icon: const Icon(Icons.train_outlined, size: 18),
                          label: Text(isArabic ? 'حالة القطارات' : 'Train Status'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoBlue, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QRScannerScreen(train: widget.train))),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: Text(isArabic ? 'مسح QR Code' : 'Scan QR Code'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTicketsTab(isDark, isArabic),
                  _buildPassengersTab(isDark, isArabic),
                  _buildReportsTab(isDark, isArabic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.cairo(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTicketsTab(bool isDark, bool isArabic) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (_, i) {
              final f = _filters[i];
              final sel = _filter == f;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: sel ? AppTheme.accentDefault : AppTheme.surfacePrimary, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? AppTheme.accentDefault : AppTheme.surfaceTertiary)),
                  child: Text(f, style: GoogleFonts.cairo(color: sel ? Colors.white : AppTheme.textSecondary)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _filteredBookings.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.confirmation_number_outlined, size: 64, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                Text(isArabic ? 'لا توجد تذاكر في هذا الفلتر' : 'No tickets in this filter', style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredBookings.length,
            itemBuilder: (_, i) {
              final b = _filteredBookings[i];
              return _TicketCard(booking: b, onScan: () => _scanTicket(b), isDark: isDark, isArabic: isArabic);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPassengersTab(bool isDark, bool isArabic) {
    final passengers = _filteredPassengersByTrain.where((p) => !p.hasDeparted).toList();
    if (passengers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(isArabic ? 'لا يوجد ركاب على متن هذا القطار حالياً' : 'No passengers onboard currently', style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: passengers.length,
      itemBuilder: (_, i) {
        final p = passengers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.surfacePrimary, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppTheme.accentDefault.withValues(alpha: 0.2), child: Text(p.name.isNotEmpty ? p.name[0] : '?', style: GoogleFonts.cairo(color: AppTheme.accentDefault))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)), Text('${isArabic ? "مقعد" : "Seat"} ${p.seatNumber}', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary))])),
              ElevatedButton.icon(onPressed: () => _departPassenger(p), icon: const Icon(Icons.exit_to_app, size: 16), label: Text(isArabic ? 'نزول' : 'Depart'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningAmber)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsTab(bool isDark, bool isArabic) {
    final reports = _filteredReportsByTrain;
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_outlined, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(isArabic ? 'لا توجد تقارير شغب مسجلة' : 'No incident reports recorded', style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _createIncidentReport, icon: const Icon(Icons.add), label: Text(isArabic ? 'إنشاء أول محضر' : 'Create First Report')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (_, i) {
        final r = reports[i];
        return GestureDetector(
          onTap: () => _viewIncidentReport(r),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surfacePrimary, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.accentDefault.withValues(alpha: 0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${isArabic ? "محضر رقم" : "Report No"} ${r.reportNumber}', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: AppTheme.accentDefault)), Text('${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}', style: GoogleFonts.cairo(fontSize: 11))]),
                const SizedBox(height: 8),
                Text('${isArabic ? "المخالف" : "Violator"}: ${r.passengerName}', style: GoogleFonts.cairo()),
                Text('${isArabic ? "المخالفة" : "Violation"}: ${r.violationType}', style: GoogleFonts.cairo(fontSize: 12)),
                if (r.resolved) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppTheme.successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(isArabic ? '✓ تم الحل' : '✓ Resolved', style: GoogleFonts.cairo(color: AppTheme.successGreen, fontSize: 12))),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onScan;
  final bool isDark;
  final bool isArabic;

  const _TicketCard({required this.booking, required this.onScan, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfacePrimary, borderRadius: BorderRadius.circular(14), border: Border.all(color: booking.status == BookingStatus.scanned ? AppTheme.successGreen.withValues(alpha: 0.3) : booking.status == BookingStatus.invalid ? AppTheme.accentDefault.withValues(alpha: 0.3) : AppTheme.surfaceTertiary.withValues(alpha: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(booking.passengerName, style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700))), _StatusBadge(status: booking.status, isArabic: isArabic)]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(booking.ticketNumber, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12))),
            const SizedBox(width: 12),
            Text('${isArabic ? "مقعد" : "Seat"} ${booking.seatNumber}', style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentDefault.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.seatClass,
                style: GoogleFonts.cairo(color: AppTheme.accentDefault, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ]),          const SizedBox(height: 12),
          if (booking.status == BookingStatus.valid) SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onScan, icon: const Icon(Icons.qr_code_scanner, size: 16), label: Text(isArabic ? 'صعود' : 'Board'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentDefault, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookingStatus status;
  final bool isArabic;
  const _StatusBadge({required this.status, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    switch (status) {
      case BookingStatus.valid: text = isArabic ? 'صالحة' : 'Valid'; color = AppTheme.successGreen; break;
      case BookingStatus.scanned: text = isArabic ? 'تم الاستخدام' : 'Used'; color = AppTheme.warningAmber; break;
      case BookingStatus.invalid: text = isArabic ? 'غير صالحة' : 'Invalid'; color = AppTheme.accentDefault; break;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Text(text, style: GoogleFonts.cairo(color: color, fontSize: 11, fontWeight: FontWeight.w600)));
  }
}

class PassengerOnboard {
  final String id;
  final String name;
  final String seatNumber;
  final String trainNumber;
  final DateTime boardedAt;
  DateTime? departedAt;
  bool hasDeparted;
  PassengerOnboard({required this.id, required this.name, required this.seatNumber, required this.trainNumber, required this.boardedAt, this.departedAt, this.hasDeparted = false});
}
