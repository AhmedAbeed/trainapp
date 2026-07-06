import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'incident_report_screen.dart';
import 'train_status_manager_screen.dart';
import 'issue_ticket_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  List<Booking> _allBookings = [];
  final List<PassengerOnboard> _passengersOnboard = [];
  final List<IncidentReport> _incidentReports = [];

  TrainSchedule? _selectedTrain;
  List<TrainSchedule> _availableTrains = [];
  List<TrainSchedule> _filteredTrains = [];
  bool _trainSelected = false;
  String _searchQuery = '';

  String _filter = 'الكل';
  final _filters = ['الكل', 'صالحة', 'تم التحقق', 'غير صالحة', 'مخالفات'];

  late TabController _tabController;

  int _departedPassengersCount = 0;
  final int _totalSeats = 180;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAvailableTrains();
    _loadData();
  }

  void _loadAvailableTrains() {
    _availableTrains = SampleData.getAllTrains();
    final seen = <String>{};
    _availableTrains = _availableTrains.where((train) {
      if (seen.contains(train.trainNumber)) {
        return false;
      } else {
        seen.add(train.trainNumber);
        return true;
      }
    }).toList();
    _filteredTrains = _availableTrains;

    debugPrint("========== 🚆 القطارات المتاحة للكومسري ==========");
    debugPrint("العدد الإجمالي: ${_availableTrains.length} قطار");
    for (var train in _availableTrains) {
      debugPrint(
          "${train.trainNumber} - ${train.trainName} - ${train.from.name} → ${train.to.name}");
    }
    debugPrint("==================================================");
  }

  void _filterTrains() {
    if (_searchQuery.isEmpty) {
      _filteredTrains = _availableTrains;
    } else {
      _filteredTrains = _availableTrains.where((train) {
        return train.trainNumber.toLowerCase().contains(_searchQuery) ||
            train.trainName.toLowerCase().contains(_searchQuery) ||
            SampleData.getStationName(train.from, true)
                .toLowerCase()
                .contains(_searchQuery) ||
            SampleData.getStationName(train.to, true)
                .toLowerCase()
                .contains(_searchQuery);
      }).toList();
    }
    setState(() {});
  }

  void _loadData() {
    _allBookings = SampleData.getAdminBookings();
    _departedPassengersCount =
        _passengersOnboard.where((p) => p.hasDeparted).length;
  }

  List<Booking> get _filteredBookingsByTrain {
    if (_selectedTrain == null) return [];
    return _allBookings
        .where((b) => b.trainNumber == _selectedTrain!.trainNumber)
        .toList();
  }

  List<Booking> get _filteredBookings {
    if (_filter == 'مخالفات') {
      return [];
    }
    final trainBookings = _filteredBookingsByTrain;
    switch (_filter) {
      case 'صالحة':
        return trainBookings
            .where((b) => b.status == BookingStatus.valid)
            .toList();
      case 'تم التحقق':
        return trainBookings
            .where((b) => b.status == BookingStatus.scanned)
            .toList();
      case 'غير صالحة':
        return trainBookings
            .where((b) => b.status == BookingStatus.invalid)
            .toList();
      default:
        return trainBookings;
    }
  }

  List<PassengerOnboard> get _filteredPassengersByTrain {
    if (_selectedTrain == null) return [];
    return _passengersOnboard
        .where((p) => p.trainNumber == _selectedTrain!.trainNumber)
        .toList();
  }

  List<IncidentReport> get _filteredReportsByTrain {
    if (_selectedTrain == null) return [];
    return _incidentReports
        .where((r) => r.trainNumber == _selectedTrain!.trainNumber)
        .toList();
  }

  void _scanTicket(Booking booking) {
    setState(() {
      final idx =
          _allBookings.indexWhere((b) => b.bookingId == booking.bookingId);
      if (idx != -1) {
        _allBookings[idx] = Booking(
          bookingId: booking.bookingId,
          ticketNumber: booking.ticketNumber,
          passengerName: booking.passengerName,
          trainNumber: booking.trainNumber,
          trainName: booking.trainName,
          from: booking.from,
          to: booking.to,
          departureTime: booking.departureTime,
          arrivalTime: booking.arrivalTime,
          date: booking.date,
          seatClass: booking.seatClass,
          seatNumber: booking.seatNumber,
          price: booking.price,
          status: BookingStatus.scanned,
          stops: booking.stops,
          currentStopIndex: booking.currentStopIndex,
        );
      }

      _passengersOnboard.add(PassengerOnboard(
        id: booking.bookingId,
        name: booking.passengerName,
        seatNumber: booking.seatNumber.toString(),
        trainNumber: booking.trainNumber,
        boardedAt: DateTime.now(),
        hasDeparted: false,
      ));
    });

    _showSnackBar(
        'تم تسجيل دخول ${booking.passengerName}', AppTheme.successGreen);
  }

  void _departPassenger(PassengerOnboard passenger) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد المغادرة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          content: Text('هل تم نزول ${passenger.name} من القطار؟',
              style: GoogleFonts.cairo()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final idx = _passengersOnboard
                      .indexWhere((p) => p.id == passenger.id);
                  if (idx != -1) {
                    _passengersOnboard[idx].hasDeparted = true;
                    _passengersOnboard[idx].departedAt = DateTime.now();
                    _departedPassengersCount++;
                  }
                });
                Navigator.pop(ctx);
                _showSnackBar(
                    'تم تسجيل مغادرة ${passenger.name}', AppTheme.infoBlue);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentDefault),
              child: Text('تأكيد', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  void _issueNewTicket() async {
    if (_selectedTrain == null) {
      _showSnackBar('يرجى اختيار القطار أولاً', AppTheme.warningAmber);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueTicketScreen(selectedTrain: _selectedTrain),
      ),
    );

    if (result != null && result is Booking) {
      setState(() {
        _allBookings.add(result);
      });
      _showSnackBar(
        '✅ تم إصدار تذكرة جديدة للراكب ${result.passengerName}',
        AppTheme.successGreen,
      );
    }
  }

  void _createIncidentReport() async {
    if (_selectedTrain == null) {
      _showSnackBar('يرجى اختيار القطار أولاً', AppTheme.warningAmber);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentReportScreen(selectedTrain: _selectedTrain),
      ),
    );

    if (result != null && result is IncidentReport) {
      setState(() {
        _incidentReports.add(result);
      });
      _showSnackBar(
        '✅ تم إنشاء محضر رقم ${result.reportNumber} للمخالف ${result.passengerName}',
        AppTheme.successGreen,
      );
    }
  }

  void _viewIncidentReport(IncidentReport report) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.surfacePrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تفاصيل المحضر',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogRow('رقم المحضر', report.reportNumber),
                const Divider(height: 10, thickness: 0.5),
                _dialogRow('اسم المخالف', report.passengerName),
                _dialogRow('الرقم القومي', report.nationalId),
                _dialogRow('المحطة', report.station),
                _dialogRow('نوع المخالفة', report.violationType),
                _dialogRow('تاريخ الإنشاء', _formatDate(report.createdAt)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوصف:',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.description,
                        style: GoogleFonts.cairo(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (report.resolved) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            color: AppTheme.successGreen, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'تم حل المحضر',
                          style: GoogleFonts.cairo(
                            color: AppTheme.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إغلاق', style: GoogleFonts.cairo()),
            ),
            if (!report.resolved)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    final index =
                        _incidentReports.indexWhere((r) => r.id == report.id);
                    if (index != -1) {
                      _incidentReports[index] = IncidentReport(
                        id: report.id,
                        reportNumber: report.reportNumber,
                        passengerName: report.passengerName,
                        nationalId: report.nationalId,
                        station: report.station,
                        violationType: report.violationType,
                        description: report.description,
                        createdAt: report.createdAt,
                        resolved: true,
                        trainNumber: report.trainNumber,
                      );
                    }
                  });
                  Navigator.pop(ctx);
                  _showSnackBar('تم تحديث المحضر كحل', AppTheme.successGreen);
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('تسوية المحضر', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _manageTicket(Booking booking) async {
    _showSnackBar('هذه الميزة قيد التطوير', AppTheme.warningAmber);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _verifyTicket(Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.surfacePrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'التحقق من التذكرة',
            style: GoogleFonts.cairo(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogRow('الراكب', booking.passengerName),
              _dialogRow('رقم التذكرة', booking.ticketNumber),
              _dialogRow('الدرجة', booking.seatClass),
              _dialogRow('المقعد', '${booking.seatNumber}'),
              const SizedBox(height: 12),
              StatusBadge(status: booking.status),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إغلاق',
                  style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
            ),
            if (booking.status == BookingStatus.valid)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _scanTicket(booking);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentDefault),
                child: Text('تسجيل الصعود',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _manageTicket(booking);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.infoBlue),
              child: Text('إدارة التذكرة', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text('$label: ',
                style: GoogleFonts.cairo(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.cairo(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;

    if (!_trainSelected || _selectedTrain == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('لوحة الكومسري'),
            backgroundColor: Colors.black87,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  context.read<AppState>().logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey.shade900, Colors.black],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'مرحباً بك في لوحة التحكم',
                        style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر القطار الذي تريد إدارته من القائمة أدناه',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            _searchQuery = value.toLowerCase();
                            _filterTrains();
                          },
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'ابحث برقم القطار أو الاسم أو المحطة...',
                            hintStyle:
                                GoogleFonts.cairo(color: Colors.grey.shade500),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.redAccent),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: Colors.grey.shade400),
                                    onPressed: () {
                                      _searchQuery = '';
                                      _filterTrains();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_filteredTrains.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عدد القطارات: ${_filteredTrains.length}',
                          style: GoogleFonts.cairo(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Text(
                            'نتائج البحث عن: "$_searchQuery"',
                            style: GoogleFonts.cairo(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _filteredTrains.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.train_outlined,
                                  size: 80, color: Colors.grey.shade600),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد قطارات مطابقة للبحث',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'جرب البحث برقم قطار أو محطة مختلفة',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTrains.length,
                          itemBuilder: (ctx, i) {
                            final train = _filteredTrains[i];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTrain = train;
                                    _trainSelected = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.grey.shade800.withValues(alpha: 0.8),
                                        Colors.grey.shade900.withValues(alpha: 0.9),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.redAccent.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.redAccent.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 55,
                                        height: 55,
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.redAccent
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.train,
                                          color: Colors.redAccent,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    train.trainNumber,
                                                    style: GoogleFonts.cairo(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    SampleData.getTrainName(
                                                        train.trainName, true),
                                                    style: GoogleFonts.cairo(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on,
                                                    size: 12,
                                                    color:
                                                        Colors.grey.shade400),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    SampleData.getStationName(
                                                        train.from, true),
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Icon(Icons.arrow_forward,
                                                    size: 10,
                                                    color: Colors.redAccent),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    SampleData.getStationName(
                                                        train.to, true),
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time,
                                                    size: 10,
                                                    color:
                                                        Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${train.departureTime} - ${train.arrivalTime}',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.redAccent.withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.redAccent,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentPassengers =
        _filteredPassengersByTrain.where((p) => !p.hasDeparted).length;
    final totalSeatsForTrain = _totalSeats;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              'لوحة الكومسري - قطار ${_selectedTrain!.trainNumber} (${_selectedTrain!.trainName})'),
          backgroundColor:
              isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                  text: 'التذاكر',
                  icon: Icon(Icons.confirmation_number_outlined)),
              Tab(text: 'الركاب', icon: Icon(Icons.people_outline)),
              Tab(text: 'التقارير', icon: Icon(Icons.report_outlined)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AppState>().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark
                  ? AppTheme.darkSurfacePrimary
                  : AppTheme.lightSurfacePrimary,
              child: Row(
                children: [
                  _statBox(
                      'السعة', '$totalSeatsForTrain', AppTheme.textSecondary),
                  _vDivider(),
                  _statBox('ركاب حالياً', '$currentPassengers',
                      AppTheme.successGreen),
                  _vDivider(),
                  _statBox('غادروا', '$_departedPassengersCount',
                      AppTheme.warningAmber),
                  _vDivider(),
                  _statBox('متبقي', '${totalSeatsForTrain - currentPassengers}',
                      AppTheme.infoBlue),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'نسبة الإشغال: ${totalSeatsForTrain == 0 ? 0 : (currentPassengers / totalSeatsForTrain * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.cairo(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: totalSeatsForTrain == 0
                        ? 0
                        : currentPassengers / totalSeatsForTrain,
                    backgroundColor: AppTheme.surfaceTertiary,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        currentPassengers > totalSeatsForTrain * 0.8
                            ? AppTheme.warningAmber
                            : AppTheme.successGreen),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _issueNewTicket,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('إصدار تذكرة', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _createIncidentReport,
                      icon: const Icon(Icons.warning_amber_outlined, size: 18),
                      label: Text('محضر شغب', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentDefault,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TrainStatusManagerScreen()),
                        );
                      },
                      icon: const Icon(Icons.train_outlined, size: 18),
                      label: Text('حالة القطارات', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.infoBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTicketsTab(),
                  _buildPassengersTab(),
                  _buildReportsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsTab() {
    final trainBookings = _filteredBookingsByTrain;

    if (trainBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('لا توجد تذاكر لهذا القطار',
                style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_filter == 'مخالفات') {
      return _buildReportsTabForFilter();
    }

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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        sel ? AppTheme.accentDefault : AppTheme.surfacePrimary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? AppTheme.accentDefault
                            : AppTheme.surfaceTertiary),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.cairo(
                      color: sel ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredBookings.length,
            itemBuilder: (_, i) {
              final b = _filteredBookings[i];
              return _BookingAdminCard(
                booking: b,
                onScan: () => _scanTicket(b),
                onVerify: () => _verifyTicket(b),
                onManage: () => _manageTicket(b),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTabForFilter() {
    final reports = _filteredReportsByTrain;
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('لا توجد تقارير شغب مسجلة لهذا القطار',
                style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (_, i) {
        final report = reports[i];
        return GestureDetector(
          onTap: () => _viewIncidentReport(report),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfacePrimary,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppTheme.accentDefault.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('محضر رقم ${report.reportNumber}',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentDefault)),
                    Text(_formatDate(report.createdAt),
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('الراكب: ${report.passengerName}',
                    style: GoogleFonts.cairo()),
                Text('المحطة: ${report.station}', style: GoogleFonts.cairo()),
                Text('نوع المخالفة: ${report.violationType}',
                    style: GoogleFonts.cairo()),
                if (report.resolved) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('✓ تم الحل',
                        style: GoogleFonts.cairo(
                            color: AppTheme.successGreen, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPassengersTab() {
    final passengers =
        _filteredPassengersByTrain.where((p) => !p.hasDeparted).toList();

    if (passengers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('لا يوجد ركاب على متن هذا القطار حالياً',
                style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _passengersOnboard.length,
      itemBuilder: (_, i) {
        final p = _passengersOnboard[i];
        if (p.hasDeparted || p.trainNumber != _selectedTrain?.trainNumber) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfacePrimary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.accentDefault.withValues(alpha: 0.2),
                child: Text(p.name[0],
                    style: GoogleFonts.cairo(color: AppTheme.accentDefault)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    Text('مقعد ${p.seatNumber}',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text('صعد: ${_formatTime(p.boardedAt)}',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _departPassenger(p),
                icon: const Icon(Icons.exit_to_app, size: 16),
                label: Text('نزول', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningAmber,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    final reports = _filteredReportsByTrain;

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.report_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('لا توجد تقارير شغب مسجلة لهذا القطار',
                style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createIncidentReport,
              icon: const Icon(Icons.add),
              label: Text('إنشاء أول محضر'),
            ),
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
            decoration: BoxDecoration(
              color: AppTheme.surfacePrimary,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppTheme.accentDefault.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('محضر رقم ${r.reportNumber}',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentDefault)),
                    Text(_formatDate(r.createdAt),
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('الراكب: ${r.passengerName}', style: GoogleFonts.cairo()),
                Text('الرقم القومي: ${r.nationalId}',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppTheme.textSecondary)),
                Text('المحطة: ${r.station}',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppTheme.textSecondary)),
                Text('نوع المخالفة: ${r.violationType}',
                    style: GoogleFonts.cairo()),
                Text('الوصف: ${r.description}',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppTheme.textSecondary)),
                if (r.resolved) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('✓ تم الحل',
                        style: GoogleFonts.cairo(
                            color: AppTheme.successGreen, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.cairo(
                  color: color, fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label,
              style: GoogleFonts.cairo(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
        width: 1,
        height: 40,
        color: AppTheme.surfaceTertiary,
        margin: const EdgeInsets.symmetric(horizontal: 8));
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _BookingAdminCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onScan;
  final VoidCallback onVerify;
  final VoidCallback onManage;

  const _BookingAdminCard({
    required this.booking,
    required this.onScan,
    required this.onVerify,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: booking.status == BookingStatus.scanned
              ? AppTheme.successGreen.withValues(alpha: 0.3)
              : booking.status == BookingStatus.invalid
                  ? AppTheme.accentDefault.withValues(alpha: 0.3)
                  : AppTheme.surfaceTertiary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.passengerName,
                  style: GoogleFonts.cairo(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.ticketNumber,
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'مقعد ${booking.seatNumber}',
                style: GoogleFonts.cairo(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Text(
                booking.seatClass,
                style: GoogleFonts.cairo(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.search, size: 16),
                  label: Text('تفاصيل', style: GoogleFonts.cairo(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.surfaceTertiary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text('إدارة', style: GoogleFonts.cairo(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.infoBlue,
                    side: const BorderSide(color: AppTheme.infoBlue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (booking.status == BookingStatus.valid) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.qr_code_scanner, size: 16),
                    label: Text('صعود',
                        style: GoogleFonts.cairo(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentDefault,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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

  PassengerOnboard({
    required this.id,
    required this.name,
    required this.seatNumber,
    required this.trainNumber,
    required this.boardedAt,
    this.departedAt,
    this.hasDeparted = false,
  });
}
