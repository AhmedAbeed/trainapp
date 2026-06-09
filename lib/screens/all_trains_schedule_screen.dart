import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class AllTrainsScheduleScreen extends StatefulWidget {
  const AllTrainsScheduleScreen({super.key});

  @override
  State<AllTrainsScheduleScreen> createState() =>
      _AllTrainsScheduleScreenState();
}

class _AllTrainsScheduleScreenState extends State<AllTrainsScheduleScreen> {
  List<TrainSchedule> _allTrains = [];
  List<TrainSchedule> _filteredTrains = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRoute = 'الكل';

  // الحصول على جميع المسارات المتاحة
  List<String> get _availableRoutes {
    final isArabic = context.read<AppState>().isArabic;
    final routes = <String>{};
    for (var train in _allTrains) {
      final fromName = SampleData.getStationName(train.from, isArabic);
      final toName = SampleData.getStationName(train.to, isArabic);
      routes.add('$fromName → $toName');
    }
    final routeList = routes.toList();
    routeList.sort();
    final allText = _getAllText();
    return [allText, ...routeList];
  }

  // Helper to get translated "All" text
  String _getAllText() {
    final isArabic = context.read<AppState>().isArabic;
    return isArabic ? 'الكل' : 'All';
  }

  // Helper to update selectedRoute when language changes
  void _updateSelectedRouteOnLanguageChange() {
    if (_selectedRoute == 'الكل' || _selectedRoute == 'All') {
      setState(() {
        _selectedRoute = _getAllText();
        _filterTrains();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTrains();
  }

  void _loadTrains() {
    setState(() => _isLoading = true);
    _allTrains = SampleData.getAllTrains();
    _filteredTrains = _allTrains;
    setState(() => _isLoading = false);
  }

  void _filterTrains() {
    final isArabic = context.read<AppState>().isArabic;

    setState(() {
      _filteredTrains = _allTrains.where((train) {
        // فلترة حسب المسار
        if (_selectedRoute != _getAllText()) {
          final fromName = SampleData.getStationName(train.from, isArabic);
          final toName = SampleData.getStationName(train.to, isArabic);
          final route = '$fromName → $toName';
          if (route != _selectedRoute) return false;
        }

        // فلترة حسب البحث
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final trainNumber = train.trainNumber.toLowerCase();
          final trainName = SampleData.getTrainName(train.trainName, isArabic).toLowerCase();
          final fromName = SampleData.getStationName(train.from, isArabic).toLowerCase();
          final toName = SampleData.getStationName(train.to, isArabic).toLowerCase();

          return trainNumber.contains(query) ||
              trainName.contains(query) ||
              fromName.contains(query) ||
              toName.contains(query);
        }

        return true;
      }).toList();
    });
  }

  // دالة تنسيق الوقت مع ص/م أو AM/PM
  String _formatTime12Hour(String time) {
    final isArabic = context.read<AppState>().isArabic;
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];

      // تحديد ص أو م / AM أو PM
      String period;
      if (isArabic) {
        period = hour >= 12 ? 'م' : 'ص';
      } else {
        period = hour >= 12 ? 'PM' : 'AM';
      }

      int displayHour = hour > 12 ? hour - 12 : hour;
      if (displayHour == 0) displayHour = 12;
      return '$displayHour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  // ✅ دالة الحصول على فترة اليوم المصححة
  String _getTimePeriod(String time, bool isArabic) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);

      if (isArabic) {
        // التصنيف العربي الصحيح
        if (hour >= 0 && hour < 5) return 'ليلي';      // 12ص - 4:59ص
        if (hour >= 5 && hour < 12) return 'صباحي';    // 5ص - 11:59ص
        if (hour >= 12 && hour < 17) return 'ظهري';    // 12م - 4:59م
        if (hour >= 17 && hour < 21) return 'مسائي';   // 5م - 8:59م
        return 'ليلي';                                  // 9م - 11:59م
      } else {
        // التصنيف الإنجليزي الصحيح
        if (hour >= 0 && hour < 5) return 'Night';     // 12am - 4:59am
        if (hour >= 5 && hour < 12) return 'Morning';   // 5am - 11:59am
        if (hour >= 12 && hour < 17) return 'Afternoon'; // 12pm - 4:59pm
        if (hour >= 17 && hour < 21) return 'Evening';   // 5pm - 8:59pm
        return 'Night';                                  // 9pm - 11:59pm
      }
    } catch (e) {
      return '';
    }
  }

  Color _getPeriodColor(String period) {
    switch (period) {
      case 'صباحي':
      case 'Morning':
        return Colors.orange.shade700;
      case 'ظهري':
      case 'Afternoon':
        return Colors.blue.shade600;
      case 'مسائي':
      case 'Evening':
        return Colors.purple.shade400;
      case 'ليلي':
      case 'Night':
        return Colors.indigo.shade700;
      default:
        return Colors.indigo.shade700;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedRouteOnLanguageChange();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final isArabic = appState.isArabic;
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    // Translated texts
    final appBarTitle = isArabic ? 'مواعيد القطارات' : 'Train Schedules';
    final searchHint = isArabic
        ? 'ابحث برقم القطار أو الاسم أو المحطة...'
        : 'Search by train number, name, or station...';
    final noTrainsFound = isArabic
        ? 'لا توجد قطارات مطابقة للبحث'
        : 'No trains match your search';
    final tryDifferentSearch = isArabic
        ? 'جرب البحث برقم قطار أو محطة مختلفة'
        : 'Try searching with a different train number or station';
    final trainsCount = isArabic ? 'عدد القطارات:' : 'Trains count:';
    final searchResultsFor = isArabic ? 'نتائج البحث عن: "' : 'Search results for: "';
    final departureText = isArabic ? 'انطلاق' : 'Departure';
    final arrivalText = isArabic ? 'وصول' : 'Arrival';
    final journeyDuration = isArabic ? 'مدة الرحلة' : 'Duration';
    final stopsText = isArabic ? 'عدد المحطات:' : 'Stops:';
    final stationText = isArabic ? 'محطة' : 'station';

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : AppTheme.lightBgDefault, // ✅ حسب الوضع
        appBar: AppBar(
          title: Text(
            appBarTitle,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? Colors.black : AppTheme.lightBgDefault, // ✅ حسب الوضع
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTrains,
              tooltip: isArabic ? 'تحديث' : 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث والفلتر
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.black : AppTheme.lightSurfacePrimary, // ✅ حسب الوضع
              child: Column(
                children: [
                  // حقل البحث
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : AppTheme.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : AppTheme.accentDefault.withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        _searchQuery = value;
                        _filterTrains();
                      },
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: GoogleFonts.cairo(
                          color: isDark
                              ? Colors.grey.shade500
                              : AppTheme.lightTextSecondary,
                        ),
                        prefixIcon:
                        Icon(Icons.search, color: isDark ? Colors.grey.shade400 : AppTheme.accentDefault),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear,
                              color: isDark ? Colors.grey.shade400 : AppTheme.textSecondary),
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
                  const SizedBox(height: 12),
                  // فلتر المسارات
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _availableRoutes.map((route) {
                        final isSelected = _selectedRoute == route;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(
                              route,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                    ? Colors.grey.shade300
                                    : AppTheme.lightTextPrimary),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedRoute = route;
                                _filterTrains();
                              });
                            },
                            backgroundColor: isDark
                                ? Colors.grey.shade900
                                : AppTheme.lightSurfaceSecondary,
                            selectedColor: AppTheme.accentDefault, // ✅ أحمر زي ما كان
                            checkmarkColor: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // عدد النتائج
            if (_filteredTrains.isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$trainsCount ${_filteredTrains.length}',
                      style: GoogleFonts.cairo(
                        color: isDark
                            ? Colors.grey.shade400
                            : AppTheme.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      Text(
                        '$searchResultsFor$_searchQuery"',
                        style: GoogleFonts.cairo(
                          color: AppTheme.accentDefault, // ✅ أحمر زي ما كان
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            // قائمة القطارات
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTrains.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.train_outlined,
                        size: 80, color: isDark ? Colors.grey.shade600 : AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      noTrainsFound,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: isDark ? Colors.grey.shade400 : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tryDifferentSearch,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade500 : AppTheme.textSecondary,
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
                  return _TrainScheduleCard(
                    train: train,
                    isDark: isDark,
                    isArabic: isArabic,
                    formatTime12Hour: _formatTime12Hour,
                    getTimePeriod: _getTimePeriod,
                    getPeriodColor: _getPeriodColor,
                    departureText: departureText,
                    arrivalText: arrivalText,
                    journeyDuration: journeyDuration,
                    stopsText: stopsText,
                    stationText: stationText,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainScheduleCard extends StatelessWidget {
  final TrainSchedule train;
  final bool isDark;
  final bool isArabic;
  final String Function(String) formatTime12Hour;
  final String Function(String, bool) getTimePeriod;
  final Color Function(String) getPeriodColor;
  final String departureText;
  final String arrivalText;
  final String journeyDuration;
  final String stopsText;
  final String stationText;

  const _TrainScheduleCard({
    required this.train,
    required this.isDark,
    required this.isArabic,
    required this.formatTime12Hour,
    required this.getTimePeriod,
    required this.getPeriodColor,
    required this.departureText,
    required this.arrivalText,
    required this.journeyDuration,
    required this.stopsText,
    required this.stationText,
  });

  @override
  Widget build(BuildContext context) {
    final departurePeriod = getTimePeriod(train.departureTime, isArabic);
    final arrivalPeriod = getTimePeriod(train.arrivalTime, isArabic);
    final departureColor = getPeriodColor(departurePeriod);
    final arrivalColor = getPeriodColor(arrivalPeriod);
    final duration = train.duration;

    // حساب عدد الساعات والدقائق
    String durationText = duration;
    if (!duration.contains(':')) {
      durationText = duration;
    }

    // Stops text
    String stopsDisplay = '$stopsText ${train.stops.length}';
    if (!isArabic) {
      stopsDisplay =
      '${train.stops.length} $stationText${train.stops.length != 1 ? 's' : ''}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900.withValues(alpha: 0.5),
            Colors.black,
          ],
        )
            : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentDefault.withValues(alpha: 0.1),
            AppTheme.lightSurfacePrimary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800
              : AppTheme.accentDefault.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // رأس الكارد (رقم القطار واسمه)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900.withValues(alpha: 0.5)
                  : AppTheme.accentDefault.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDefault, // ✅ أحمر زي ما كان
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    train.trainNumber,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    SampleData.getTrainName(train.trainName, isArabic),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                // أيقونة القطار
                Icon(
                  Icons.train,
                  color: isDark ? Colors.grey.shade500 : AppTheme.accentDefault,
                  size: 24,
                ),
              ],
            ),
          ),
          // محتوى الكارد
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // المسار
                Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade900
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        SampleData.getStationName(train.from, isArabic),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward,
                          size: 16, color: isDark ? Colors.grey.shade500 : AppTheme.accentDefault),
                      const SizedBox(width: 8),
                      Text(
                        SampleData.getStationName(train.to, isArabic),
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // مواعيد الانطلاق والوصول
                Row(
                  children: [
                    // وقت الانطلاق
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: departureColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: departureColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.departure_board,
                                    size: 18, color: departureColor),
                                const SizedBox(width: 4),
                                Text(
                                  departureText,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatTime12Hour(train.departureTime),
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: departureColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: departureColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                departurePeriod,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: departureColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // مدة الرحلة
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.timer,
                              size: 20, color: isDark ? Colors.grey.shade500 : AppTheme.textSecondary),
                          const SizedBox(height: 4),
                          Text(
                            durationText,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentDefault, // ✅ أحمر زي ما كان
                            ),
                          ),
                          Text(
                            journeyDuration,
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // وقت الوصول
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: arrivalColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                          Border.all(color: arrivalColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on,
                                    size: 18, color: arrivalColor),
                                const SizedBox(width: 4),
                                Text(
                                  arrivalText,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatTime12Hour(train.arrivalTime),
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: arrivalColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: arrivalColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                arrivalPeriod,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: arrivalColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // محطات التوقف
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade900
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.train,
                          size: 14, color: isDark ? Colors.grey.shade500 : AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stopsDisplay,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                      if (train.stops.isNotEmpty)
                        Text(
                          SampleData.getStationName(train.stops.first, isArabic),
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : AppTheme.textSecondary,
                          ),
                        ),
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
}