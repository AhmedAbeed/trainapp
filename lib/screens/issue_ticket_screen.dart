import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class IssueTicketScreen extends StatefulWidget {
  final TrainSchedule? selectedTrain;

  const IssueTicketScreen({super.key, this.selectedTrain});

  @override
  State<IssueTicketScreen> createState() => _IssueTicketScreenState();
}

class _IssueTicketScreenState extends State<IssueTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // تخزين القيم بالعربي (الأصلي)
  String? _selectedFromStationAr;
  String? _selectedToStationAr;
  String? _selectedTrain;
  String? _selectedClass;
  int? _selectedSeatNumber;
  final DateTime _selectedDate = DateTime.now();

  List<TrainSchedule> _availableTrains = [];
  bool _isLoading = false;
  final int _maxSeats = 50;

  @override
  void initState() {
    super.initState();
    if (widget.selectedTrain != null) {
      _selectedTrain = widget.selectedTrain!.trainNumber;
      _selectedFromStationAr = widget.selectedTrain!.from.name;
      _selectedToStationAr = widget.selectedTrain!.to.name;
      _searchTrains();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _searchTrains() {
    if (_selectedFromStationAr == null || _selectedToStationAr == null) {
      final isArabic = context.read<AppState>().isArabic;
      _showSnackBar(
          isArabic ? 'يرجى اختيار محطة الانطلاق والوصول' : 'Please select departure and arrival stations',
          Colors.orange
      );
      return;
    }

    setState(() {
      _isLoading = true;
      try {
        _availableTrains = SampleData.getTrains(_selectedFromStationAr!, _selectedToStationAr!);
      } catch (e) {
        _availableTrains = [];
      }
      _isLoading = false;
    });

    if (_availableTrains.isEmpty) {
      final isArabic = context.read<AppState>().isArabic;
      _showSnackBar(
          isArabic ? 'لا توجد قطارات متاحة على هذا المسار' : 'No trains available on this route',
          Colors.orange
      );
    } else if (_selectedTrain != null) {
      final stillExists = _availableTrains.any((t) => t.trainNumber == _selectedTrain);
      if (!stillExists) {
        setState(() => _selectedTrain = null);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(String time, bool isArabic) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? (isArabic ? 'م' : 'PM') : (isArabic ? 'ص' : 'AM');
      int displayHour = hour > 12 ? hour - 12 : hour;
      if (displayHour == 0) displayHour = 12;
      return '$displayHour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  void _issueTicket() {
    final isArabic = context.read<AppState>().isArabic;

    if (!_formKey.currentState!.validate()) return;
    if (_selectedFromStationAr == null) {
      _showSnackBar(isArabic ? 'يرجى اختيار محطة الانطلاق' : 'Please select departure station', Colors.orange);
      return;
    }
    if (_selectedToStationAr == null) {
      _showSnackBar(isArabic ? 'يرجى اختيار محطة الوصول' : 'Please select arrival station', Colors.orange);
      return;
    }
    if (_selectedTrain == null) {
      _showSnackBar(isArabic ? 'يرجى اختيار القطار' : 'Please select a train', Colors.orange);
      return;
    }
    if (_selectedClass == null) {
      _showSnackBar(isArabic ? 'يرجى اختيار الدرجة' : 'Please select a class', Colors.orange);
      return;
    }
    if (_selectedSeatNumber == null) {
      _showSnackBar(isArabic ? 'يرجى اختيار رقم المقعد' : 'Please select a seat number', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final selectedTrain = _availableTrains.firstWhere((t) => t.trainNumber == _selectedTrain);
    final price = selectedTrain.prices[_selectedClass!] ?? 100;

    final booking = Booking(
      bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch}',
      ticketNumber: 'ENR-${selectedTrain.trainNumber}-S$_selectedSeatNumber',
      passengerName: _nameCtrl.text.trim(),
      trainNumber: selectedTrain.trainNumber,
      trainName: selectedTrain.trainName,
      from: SampleData.getStation(_selectedFromStationAr!),
      to: SampleData.getStation(_selectedToStationAr!),
      departureTime: selectedTrain.departureTime,
      arrivalTime: selectedTrain.arrivalTime,
      date: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      seatClass: _selectedClass!,
      seatNumber: _selectedSeatNumber!,
      price: price,
      status: BookingStatus.valid,
      stops: selectedTrain.stops,
      currentStopIndex: 0,
    );

    Navigator.pop(context, booking);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final isArabic = appState.isArabic;
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    // قائمة المحطات للعرض (مترجمة حسب اللغة)
    final stationNamesForDisplay = SampleData.mainStations
        .map((s) => SampleData.getStationName(s, isArabic))
        .toList();

    // إيجاد القيمة المعروضة حالياً (المترجمة) من القيمة العربية المخزنة
    String? getDisplayValue(String? arabicValue) {
      if (arabicValue == null) return null;
      if (isArabic) return arabicValue;
      return SampleData.stationNameEn[arabicValue] ?? arabicValue;
    }

    // الحصول على القيمة العربية من القيمة المعروضة
    String? getArabicValue(String? displayValue) {
      if (displayValue == null) return null;
      if (isArabic) return displayValue;
      // البحث عن المفتاح العربي من القيمة المعروضة
      for (var entry in SampleData.stationNameEn.entries) {
        if (entry.value == displayValue) {
          return entry.key;
        }
      }
      return displayValue;
    }

    // النصوص المترجمة
    final appBarTitle = isArabic ? 'إصدار تذكرة جديدة' : 'Issue New Ticket';
    final passengerDataTitle = isArabic ? 'بيانات الراكب' : 'Passenger Data';
    final fullNameLabel = isArabic ? 'الاسم الكامل' : 'Full Name';
    final nationalIdLabel = isArabic ? 'الرقم القومي' : 'National ID';
    final phoneLabel = isArabic ? 'رقم الهاتف' : 'Phone Number';
    final routeTitle = isArabic ? 'مسار الرحلة' : 'Trip Route';
    final fromLabel = isArabic ? 'من' : 'From';
    final toLabel = isArabic ? 'إلى' : 'To';
    final searchButton = isArabic ? 'بحث عن قطارات' : 'Search Trains';
    final selectTrainTitle = isArabic ? 'اختر القطار' : 'Select Train';
    final selectClassTitle = isArabic ? 'اختر الدرجة' : 'Select Class';
    final selectSeatTitle = isArabic ? 'اختر رقم المقعد' : 'Select Seat Number';
    final issueButton = isArabic ? 'إصدار' : 'Issue';

    final classOptions = isArabic
        ? ['درجة أولى', 'درجة ثانية', 'درجة ثالثة']
        : ['First Class', 'Second Class', 'Third Class'];

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle, style: GoogleFonts.cairo()),
          backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
          actions: [
            TextButton.icon(
              onPressed: _isLoading ? null : _issueTicket,
              icon: Icon(Icons.qr_code,
                  color: _isLoading ? AppTheme.textSecondary : AppTheme.accentDefault),
              label: Text(issueButton,
                  style: GoogleFonts.cairo(
                    color: _isLoading ? AppTheme.textSecondary : AppTheme.accentDefault,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بيانات الراكب
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: AppTheme.accentDefault),
                          const SizedBox(width: 8),
                          Text(passengerDataTitle,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameCtrl,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style: GoogleFonts.cairo(),
                        decoration: InputDecoration(
                          labelText: fullNameLabel,
                          labelStyle: GoogleFonts.cairo(),
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) {
                            return isArabic ? 'الاسم مطلوب' : 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nationalIdCtrl,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style: GoogleFonts.cairo(),
                        decoration: InputDecoration(
                          labelText: nationalIdLabel,
                          labelStyle: GoogleFonts.cairo(),
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) {
                            return isArabic ? 'الرقم القومي مطلوب' : 'National ID is required';
                          }
                          if (v.length < 14) {
                            return isArabic ? 'الرقم القومي غير صحيح' : 'Invalid National ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        style: GoogleFonts.cairo(),
                        decoration: InputDecoration(
                          labelText: phoneLabel,
                          labelStyle: GoogleFonts.cairo(),
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v!.isEmpty) {
                            return isArabic ? 'رقم الهاتف مطلوب' : 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // مسار الرحلة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.route, color: AppTheme.accentDefault),
                          const SizedBox(width: 8),
                          Text(routeTitle,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: getDisplayValue(_selectedFromStationAr),
                              decoration: InputDecoration(
                                labelText: fromLabel,
                                labelStyle: GoogleFonts.cairo(),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: stationNamesForDisplay.map((displayName) {
                return DropdownMenuItem<String>(
                  value: displayName,
                  child: Text(displayName, style: GoogleFonts.cairo()),
                );
              }).toList(),
                              onChanged: (displayValue) {
                                setState(() {
                                  _selectedFromStationAr = getArabicValue(displayValue);
                                  _selectedTrain = null;
                                  _selectedClass = null;
                                  _selectedSeatNumber = null;
                                  _availableTrains = [];
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: getDisplayValue(_selectedToStationAr),
                              decoration: InputDecoration(
                                labelText: toLabel,
                                labelStyle: GoogleFonts.cairo(),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              items: stationNamesForDisplay
                                  .where((s) => s != getDisplayValue(_selectedFromStationAr))
                                  .map((displayName) {
                                return DropdownMenuItem<String>(
                                  value: displayName,
                                  child: Text(displayName, style: GoogleFonts.cairo()),
                                );
                              }).toList(),
                              onChanged: (displayValue) {
                                setState(() {
                                  _selectedToStationAr = getArabicValue(displayValue);
                                  _selectedTrain = null;
                                  _selectedClass = null;
                                  _selectedSeatNumber = null;
                                  _availableTrains = [];
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _searchTrains,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.infoBlue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(searchButton, style: GoogleFonts.cairo()),
                        ),
                      ),
                    ],
                  ),
                ),

                // اختيار القطار
                if (_availableTrains.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectTrainTitle,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedTrain,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _availableTrains.map((train) {
                            final trainName = SampleData.getTrainName(train.trainName, isArabic);
                            final timeFormatted = _formatTime(train.departureTime, isArabic);
                            return DropdownMenuItem(
                              value: train.trainNumber,
                              child: Text(
                                '${train.trainNumber} - $trainName - $timeFormatted',
                                style: GoogleFonts.cairo(),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedTrain = v),
                        ),
                      ],
                    ),
                  ),
                ],

                // اختيار الدرجة والمقعد
                if (_selectedTrain != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectClassTitle,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClass,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: classOptions.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo()));
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedClass = v),
                        ),
                        const SizedBox(height: 16),
                        Text(selectSeatTitle,
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_maxSeats, (index) {
                            final seatNum = index + 1;
                            final isSelected = _selectedSeatNumber == seatNum;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedSeatNumber = seatNum),
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.accentDefault
                                      : (isDark
                                      ? AppTheme.darkSurfaceSecondary
                                      : AppTheme.lightSurfaceSecondary),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isSelected
                                          ? AppTheme.accentDefault
                                          : AppTheme.surfaceTertiary),
                                ),
                                child: Center(
                                  child: Text(
                                    '$seatNum',
                                    style: GoogleFonts.cairo(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                          ? AppTheme.darkTextPrimary
                                          : AppTheme.lightTextPrimary),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}