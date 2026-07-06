import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import '../services/app_state.dart';
import 'payment_screen.dart';

class TrainBookingScreen extends StatefulWidget {
  final TrainSchedule train;
  final DateTime date;

  const TrainBookingScreen(
      {super.key, required this.train, required this.date});

  @override
  State<TrainBookingScreen> createState() => _TrainBookingScreenState();
}

class _TrainBookingScreenState extends State<TrainBookingScreen> {
  String? _selectedClass;
  int? _selectedSeatNumber;
  Set<int> _bookedSeats = {};
  bool _isLoadingSeats = false;

  int get _maxSeats {
    if (_selectedClass == null) return 50;
    return widget.train.availableSeats[_selectedClass] ?? 50;
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadBookedSeats() async {
    if (_selectedClass == null) return;
    setState(() => _isLoadingSeats = true);
    try {
      final dateString = '${widget.date.day}/${widget.date.month}/${widget.date.year}';
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('trainNumber', isEqualTo: widget.train.trainNumber)
          .where('date', isEqualTo: dateString)
          .where('seatClass', isEqualTo: _selectedClass)
          .where('status', whereIn: ['valid', 'scanned'])
          .get();

      setState(() {
        _bookedSeats = snapshot.docs
            .map((doc) => (doc.data()['seatNumber'] as num).toInt())
            .toSet();
        _isLoadingSeats = false;
      });
    } catch (e) {
      setState(() => _isLoadingSeats = false);
      debugPrint('❌ Error loading booked seats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;

    final classes = widget.train.prices.keys.toList();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'تفاصيل الرحلة' : 'Trip Details'),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentDefault.withValues(alpha: 0.2),
                      isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.accentDefault.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          SampleData.getTrainName(widget.train.trainName, isArabic),
                          style: GoogleFonts.cairo(
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentDefault,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '# ${widget.train.trainNumber}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _timeStation(
                            widget.train.departureTime,
                            SampleData.getStationName(widget.train.from, isArabic),
                            isDark,
                            isRight: false),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                widget.train.duration,
                                style: GoogleFonts.cairo(
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                      height: 1.5,
                                      color: isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
                                      border: Border.all(
                                          color: AppTheme.accentDefault,
                                          width: 1.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.train,
                                        color: AppTheme.accentDefault,
                                        size: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _timeStation(
                            widget.train.arrivalTime,
                            SampleData.getStationName(widget.train.to, isArabic),
                            isDark,
                            isRight: true),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                isArabic ? 'محطات التوقف' : 'Stops',
                style: GoogleFonts.cairo(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: List.generate(widget.train.stops.length, (i) {
                    final stop = widget.train.stops[i];
                    final isLast = i == widget.train.stops.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppTheme.accentDefault
                                    : isLast
                                    ? AppTheme.successGreen
                                    : isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: i == 0
                                      ? AppTheme.accentDefault
                                      : isLast
                                      ? AppTheme.successGreen
                                      : isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  width: 2,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 1.5,
                                height: 30,
                                color: isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary,
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: Text(
                            SampleData.getStationName(stop, isArabic),
                            style: GoogleFonts.cairo(
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                isArabic ? 'اختر الدرجة' : 'Select Class',
                style: GoogleFonts.cairo(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...classes.map((cls) {
                final price = widget.train.prices[cls]!;
                final seats = widget.train.availableSeats[cls]!;
                final selected = _selectedClass == cls;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedClass = cls;
                      _selectedSeatNumber = null;
                      _bookedSeats = {};
                    });
                    _loadBookedSeats();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accentDefault.withValues(alpha: 0.1)
                          : (isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppTheme.accentDefault
                            : (isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? AppTheme.accentDefault
                                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? Center(
                            child: Icon(Icons.circle,
                                color: AppTheme.accentDefault, size: 10),
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SampleData.getClassName(cls, isArabic),
                                style: GoogleFonts.cairo(
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isArabic ? '$seats مقعد متاح' : '$seats seats available',
                                style: GoogleFonts.cairo(
                                  color: seats < 10
                                      ? AppTheme.warningAmber
                                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$price ${isArabic ? 'جنيه' : 'EGP'}',
                          style: GoogleFonts.cairo(
                            color: selected
                                ? AppTheme.accentDefault
                                : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              if (_selectedClass != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'اختر رقم المقعد' : 'Select Seat Number',
                      style: GoogleFonts.cairo(
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isLoadingSeats)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: List.generate(_maxSeats, (index) {
                          final seatNumber = index + 1;
                          final isBooked = _bookedSeats.contains(seatNumber);
                          final isSelected = _selectedSeatNumber == seatNumber;

                          return GestureDetector(
                            onTap: isBooked ? null : () {
                              setState(() {
                                _selectedSeatNumber = seatNumber;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isBooked 
                                    ? Colors.red.withOpacity(0.2)
                                    : isSelected
                                        ? AppTheme.accentDefault
                                        : (isDark ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isBooked 
                                      ? Colors.red.withOpacity(0.5)
                                      : isSelected
                                          ? AppTheme.accentDefault
                                          : (isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: isBooked 
                                    ? const Icon(Icons.close, color: Colors.red, size: 16)
                                    : Text(
                                        '$seatNumber',
                                        style: GoogleFonts.cairo(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              ENRButton(
                text: isArabic ? 'متابعة للدفع' : 'Proceed to Payment',
                onPressed: () {
                  if (_selectedClass == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            isArabic ? 'يرجى اختيار الدرجة' : 'Please select a class',
                            style: GoogleFonts.cairo()),
                        backgroundColor: AppTheme.accentDefault,
                      ),
                    );
                    return;
                  }
                  if (_selectedSeatNumber == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            isArabic ? 'يرجى اختيار رقم المقعد' : 'Please select a seat number',
                            style: GoogleFonts.cairo()),
                        backgroundColor: AppTheme.accentDefault,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        train: widget.train,
                        selectedClass: _selectedClass!,
                        selectedSeatNumber: _selectedSeatNumber!,
                        date: widget.date,
                      ),
                    ),
                  );
                },
                icon: Icons.payment,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeStation(String time, String station, bool isDark, {bool isRight = false}) {
    return Column(
      crossAxisAlignment:
      isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: GoogleFonts.inter(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          station,
          style: GoogleFonts.cairo(
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
