import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import '../services/app_state.dart';
import 'train_list_screen.dart';
import 'all_trains_schedule_screen.dart';

class BookingTab extends StatefulWidget {
  const BookingTab({super.key});

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  String? _fromStation;
  String? _toStation;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadTrainsFromFirebase();
  }

  Future<void> _loadTrainsFromFirebase() async {
    try {
      final snapshot = await _firestore.collection('trains').get();
      final List<TrainSchedule> trains = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final train = TrainSchedule(
          id: doc.id,
          trainNumber: data['trainNumber'] ?? '',
          trainName: data['trainName'] ?? '',
          from: SampleData.stations.firstWhere(
            (s) => s.name == data['from'],
            orElse: () => SampleData.stations[0],
          ),
          to: SampleData.stations.firstWhere(
            (s) => s.name == data['to'],
            orElse: () => SampleData.stations[0],
          ),
          departureTime: data['departureTime'] ?? '',
          arrivalTime: data['arrivalTime'] ?? '',
          duration: data['duration'] ?? '',
          stops: (data['stops'] as List?)
                  ?.map((s) => SampleData.stations.firstWhere(
                        (station) => station.name == s,
                        orElse: () => SampleData.stations[0],
                      ))
                  .toList() ??
              [],
          prices: Map.from(data['prices'] ?? {}),
          availableSeats: Map.from(data['availableSeats'] ?? {}),
        );
        trains.add(train);
      }

      setState(() {}); // trigger rebuild if needed
      debugPrint("✅ تم تحميل ${trains.length} قطار من Firebase");
    } catch (e) {
      debugPrint("❌ خطأ في تحميل القطارات: $e");
    }
  }

  void _search() {
    if (_fromStation == null || _toStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AppState>().isArabic
                ? 'يرجى تحديد نقطة الانطلاق والوجهة'
                : 'Please select departure and destination',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppTheme.accentDefault,
        ),
      );
      return;
    }

    final DateTime finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainListScreen(
          from: _fromStation!,
          to: _toStation!,
          date: finalDateTime,
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.accentDefault),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppTheme.surfaceSecondary,
            hourMinuteTextColor: AppTheme.textPrimary,
            dayPeriodTextColor: AppTheme.accentDefault,
            dialBackgroundColor: AppTheme.surfaceTertiary,
            dialHandColor: AppTheme.accentDefault,
            dialTextColor: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;

    final List<Map<String, String>> popularDestinations = isArabic
        ? [
            {'name': 'الإسكندرية', 'image': 'assets/images/alexandria.jpg'},
            {'name': 'أسوان', 'image': 'assets/images/aswan.jpg'},
            {'name': 'الأقصر', 'image': 'assets/images/luxor.jpg'},
            {'name': 'أسيوط', 'image': 'assets/images/assiut.jpg'},
            {'name': 'بورسعيد', 'image': 'assets/images/portsaid.jpg'},
            {'name': 'المنصورة', 'image': 'assets/images/mansoura.jpg'},
            {'name': 'طنطا', 'image': 'assets/images/tanta.jpg'},
            {'name': 'السويس', 'image': 'assets/images/suez.jpg'},
          ]
        : [
            {'name': 'Alexandria', 'image': 'assets/images/alexandria.jpg'},
            {'name': 'Aswan', 'image': 'assets/images/aswan.jpg'},
            {'name': 'Luxor', 'image': 'assets/images/luxor.jpg'},
            {'name': 'Assiut', 'image': 'assets/images/assiut.jpg'},
            {'name': 'Port Said', 'image': 'assets/images/portsaid.jpg'},
            {'name': 'Mansoura', 'image': 'assets/images/mansoura.jpg'},
            {'name': 'Tanta', 'image': 'assets/images/tanta.jpg'},
            {'name': 'Suez', 'image': 'assets/images/suez.jpg'},
          ];

    final List<String> stationNames = SampleData.stations
        .map((s) => SampleData.getStationName(s, isArabic))
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor:
                isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      const Color(0xFF1A0607),
                      isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentDefault,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ENR',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isArabic
                                  ? 'السكك الحديدية المصرية'
                                  : 'Egyptian National Railways',
                              style: GoogleFonts.cairo(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isArabic
                              ? 'إلى أين تريد\nالسفر اليوم؟'
                              : 'Where do you want\nto travel today?',
                          style: GoogleFonts.cairo(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurfacePrimary
                          : AppTheme.lightSurfacePrimary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: (isDark
                                  ? AppTheme.darkSurfaceTertiary
                                  : AppTheme.lightSurfaceTertiary)
                              .withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        _buildStationSelector(
                          label: isArabic ? 'من' : 'From',
                          icon: Icons.circle_outlined,
                          iconColor: AppTheme.successGreen,
                          value: _fromStation,
                          stationNames: stationNames,
                          onChanged: (v) => setState(() => _fromStation = v),
                          isDark: isDark,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                    height: 1,
                                    color: isDark
                                        ? AppTheme.darkSurfaceTertiary
                                        : AppTheme.lightSurfaceTertiary),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    final tmp = _fromStation;
                                    _fromStation = _toStation;
                                    _toStation = tmp;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkSurfaceSecondary
                                        : AppTheme.lightSurfaceSecondary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: isDark
                                            ? AppTheme.darkSurfaceTertiary
                                            : AppTheme.lightSurfaceTertiary),
                                  ),
                                  child: const Icon(Icons.swap_vert,
                                      color: AppTheme.accentDefault, size: 18),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                    height: 1,
                                    color: isDark
                                        ? AppTheme.darkSurfaceTertiary
                                        : AppTheme.lightSurfaceTertiary),
                              ),
                            ],
                          ),
                        ),
                        _buildStationSelector(
                          label: isArabic ? 'إلى' : 'To',
                          icon: Icons.location_on,
                          iconColor: AppTheme.accentDefault,
                          value: _toStation,
                          stationNames: stationNames,
                          onChanged: (v) => setState(() => _toStation = v),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 90)),
                                    builder: (ctx, child) => Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                            primary: AppTheme.accentDefault),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (d != null) {
                                    setState(() => _selectedDate = d);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkSurfaceSecondary
                                        : AppTheme.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isDark
                                            ? AppTheme.darkSurfaceTertiary
                                            : AppTheme.lightSurfaceTertiary),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          color: AppTheme.accentDefault,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                          style: GoogleFonts.cairo(
                                              color: isDark
                                                  ? AppTheme.darkTextPrimary
                                                  : AppTheme.lightTextPrimary,
                                              fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkSurfaceSecondary
                                        : AppTheme.lightSurfaceSecondary,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isDark
                                            ? AppTheme.darkSurfaceTertiary
                                            : AppTheme.lightSurfaceTertiary),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          color: AppTheme.accentDefault,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedTime.format(context),
                                          style: GoogleFonts.cairo(
                                              color: isDark
                                                  ? AppTheme.darkTextPrimary
                                                  : AppTheme.lightTextPrimary,
                                              fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ENRButton(
                          text: isArabic ? 'ابحث عن رحلات' : 'Search Trains',
                          onPressed: _search,
                          icon: Icons.search,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AllTrainsScheduleScreen()),
                        );
                      },
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(
                        isArabic
                            ? 'عرض جميع مواعيد القطارات'
                            : 'View All Train Schedules',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.infoBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic ? 'الوجهات الشائعة' : 'Popular Destinations',
                    style: GoogleFonts.cairo(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: popularDestinations.length,
                    itemBuilder: (ctx, i) {
                      final destination = popularDestinations[i];
                      final destName = destination['name']!;
                      final imagePath = destination['image']!;

                      return GestureDetector(
                        onTap: () => setState(() => _toStation = destName),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _toStation == destName
                                  ? AppTheme.accentDefault
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _toStation == destName
                                    ? AppTheme.accentDefault.withValues(alpha: 0.3)
                                    : Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            isDark
                                                ? AppTheme.darkSurfacePrimary
                                                : AppTheme.lightSurfacePrimary,
                                            isDark
                                                ? AppTheme.darkSurfaceSecondary
                                                : AppTheme
                                                    .lightSurfaceSecondary,
                                          ],
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.train,
                                          color: isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary,
                                          size: 40,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.7),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _toStation == destName
                                            ? AppTheme.accentDefault
                                            : Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        destName,
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          shadows: const [
                                            Shadow(
                                                offset: Offset(1, 1),
                                                blurRadius: 2),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_toStation == destName)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentDefault,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationSelector({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String? value,
    required List<String> stationNames,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: iconColor, size: 18),
      ),
      dropdownColor: isDark
          ? AppTheme.darkSurfaceSecondary
          : AppTheme.lightSurfaceSecondary,
      style: GoogleFonts.cairo(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontSize: 14),
      items: stationNames
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s,
                    style: GoogleFonts.cairo(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
