import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import 'train_booking_screen.dart';

class TrainListScreen extends StatelessWidget {
  final String from;
  final String to;
  final DateTime date;

  const TrainListScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
  });

  String _formatTime12Hour(String time, bool isArabic) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final period = hour >= 12
          ? (isArabic ? 'م' : 'PM')
          : (isArabic ? 'ص' : 'AM');

      int displayHour = hour > 12 ? hour - 12 : hour;
      if (displayHour == 0) displayHour = 12;
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  Color _getTimeColor(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      if (hour >= 5 && hour < 12) return Colors.orange.shade700;
      if (hour >= 12 && hour < 17) return Colors.blue.shade600;
      if (hour >= 17 && hour < 21) return Colors.purple.shade400;
      return Colors.indigo.shade700;
    } catch (e) {
      return AppTheme.accentDefault;
    }
  }

  IconData _getTimeIcon(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      if (hour >= 5 && hour < 12) return Icons.wb_sunny;
      if (hour >= 12 && hour < 17) return Icons.wb_sunny_outlined;
      if (hour >= 17 && hour < 21) return Icons.brightness_4;
      return Icons.brightness_2;
    } catch (e) {
      return Icons.access_time;
    }
  }

  String _getTimePeriod(String time, bool isArabic) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      if (isArabic) {
        if (hour >= 5 && hour < 12) return 'صباحي';
        if (hour >= 12 && hour < 17) return 'ظهري';
        if (hour >= 17 && hour < 21) return 'مسائي';
        return 'ليلي';
      } else {
        if (hour >= 5 && hour < 12) return 'Morning';
        if (hour >= 12 && hour < 17) return 'Afternoon';
        if (hour >= 17 && hour < 21) return 'Evening';
        return 'Night';
      }
    } catch (e) {
      return '';
    }
  }

  String _getStationDisplayName(String stationName, bool isArabic) {
    final stationList = SampleData.allStations;
    Station? foundStation;

    for (var station in stationList) {
      if (station.name == stationName) {
        foundStation = station;
        break;
      }
      final enName = SampleData.stationNameEn[station.name];
      if (enName == stationName) {
        foundStation = station;
        break;
      }
    }

    if (foundStation != null) {
      return SampleData.getStationName(foundStation, isArabic);
    }

    return stationName;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;

    final fromDisplay = _getStationDisplayName(from, isArabic);
    final toDisplay = _getStationDisplayName(to, isArabic);

    final allTrains = SampleData.getTrains(from, to);

    final filteredTrains = allTrains.where((train) {
      final timeParts = train.departureTime.split(':');
      final trainHour = int.parse(timeParts[0]);
      final trainMinute = int.parse(timeParts[1]);

      final trainDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        trainHour,
        trainMinute,
      );

      final now = DateTime.now();

      if (DateTime(date.year, date.month, date.day)
          .isBefore(DateTime(now.year, now.month, now.day))) {
        return false;
      }

      return trainDateTime.isAfter(date) && trainDateTime.isAfter(now);
    }).toList();

    final sortedTrains = List.of(filteredTrains)
      ..sort((a, b) {
        final timeA = int.parse(a.departureTime.split(':')[0]);
        final timeB = int.parse(b.departureTime.split(':')[0]);
        return timeA.compareTo(timeB);
      });

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '$fromDisplay → $toDisplay',
            style: GoogleFonts.cairo(),
          ),
          leading: IconButton(
            icon: Icon(isArabic ? Icons.arrow_back_ios_new : Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor:
          isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark
                  ? AppTheme.darkSurfacePrimary
                  : AppTheme.lightSurfacePrimary,
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: AppTheme.accentDefault, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: GoogleFonts.cairo(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 14,
                    color: isDark
                        ? AppTheme.darkSurfaceTertiary
                        : AppTheme.lightSurfaceTertiary,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time,
                      color: AppTheme.accentDefault, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime12Hour('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}', isArabic),
                    style: GoogleFonts.cairo(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 14,
                    color: isDark
                        ? AppTheme.darkSurfaceTertiary
                        : AppTheme.lightSurfaceTertiary,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.train, color: AppTheme.accentDefault, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    sortedTrains.length == 1
                        ? (isArabic ? 'رحلة واحدة متاحة' : '1 trip available')
                        : (sortedTrains.isEmpty
                        ? (isArabic ? 'لا توجد رحلات' : 'No trips')
                        : (isArabic
                        ? '${sortedTrains.length} رحلات متاحة'
                        : '${sortedTrains.length} trips available')),
                    style: GoogleFonts.cairo(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (sortedTrains.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.train_outlined,
                        size: 80,
                        color: isDark
                            ? AppTheme.darkTextSecondary.withValues(alpha: 0.5)
                            : AppTheme.lightTextSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isArabic ? 'لا توجد رحلات متاحة' : 'No trips available',
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic
                            ? 'لا توجد رحلات في هذا الوقت المختار\nحاول تغيير الوقت أو التاريخ'
                            : 'No trips available at this time\nTry changing the time or date',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: isDark
                              ? AppTheme.darkTextSecondary.withValues(alpha: 0.7)
                              : AppTheme.lightTextSecondary.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedTrains.length,
                  itemBuilder: (ctx, i) => _TrainCard(
                    train: sortedTrains[i],
                    date: date,
                    isDark: isDark,
                    isArabic: isArabic,
                    formatTime12Hour: _formatTime12Hour,
                    getTimeColor: _getTimeColor,
                    getTimeIcon: _getTimeIcon,
                    getTimePeriod: _getTimePeriod,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrainCard extends StatelessWidget {
  final TrainSchedule train;
  final DateTime date;
  final bool isDark;
  final bool isArabic;
  final String Function(String, bool) formatTime12Hour;
  final Color Function(String) getTimeColor;
  final IconData Function(String) getTimeIcon;
  final String Function(String, bool) getTimePeriod;

  const _TrainCard({
    required this.train,
    required this.date,
    required this.isDark,
    required this.isArabic,
    required this.formatTime12Hour,
    required this.getTimeColor,
    required this.getTimeIcon,
    required this.getTimePeriod,
  });

  @override
  Widget build(BuildContext context) {
    final cheapestClass =
    train.prices.entries.reduce((a, b) => a.value < b.value ? a : b);
    final departurePeriod = getTimePeriod(train.departureTime, isArabic);
    final departureColor = getTimeColor(train.departureTime);
    final departureIcon = getTimeIcon(train.departureTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color:
        isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark
              ? AppTheme.darkSurfaceTertiary
              : AppTheme.lightSurfaceTertiary)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TrainBookingScreen(train: train, date: date),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentDefault.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            train.trainNumber,
                            style: GoogleFonts.inter(
                              color: AppTheme.accentDefault,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          SampleData.getTrainName(train.trainName, isArabic),
                          style: GoogleFonts.cairo(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.successGreen.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        isArabic ? 'متاح' : 'Available',
                        style: GoogleFonts.cairo(
                          color: AppTheme.successGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(departureIcon,
                                  color: departureColor, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                formatTime12Hour(train.departureTime, isArabic),
                                style: GoogleFonts.inter(
                                  color: departureColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            SampleData.getStationName(train.from, isArabic),
                            style: GoogleFonts.cairo(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (departurePeriod.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: departureColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                departurePeriod,
                                style: GoogleFonts.cairo(
                                  color: departureColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            train.duration,
                            style: GoogleFonts.cairo(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentDefault,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.darkSurfaceTertiary
                                      : AppTheme.lightSurfaceTertiary,
                                ),
                              ),
                              const Icon(Icons.train,
                                  color: AppTheme.accentDefault, size: 18),
                              Expanded(
                                child: Container(
                                  height: 1.5,
                                  color: isDark
                                      ? AppTheme.darkSurfaceTertiary
                                      : AppTheme.lightSurfaceTertiary,
                                ),
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? '${train.stops.length} محطات'
                                : '${train.stops.length} stop${train.stops.length != 1 ? 's' : ''}',
                            style: GoogleFonts.cairo(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatTime12Hour(train.arrivalTime, isArabic),
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            SampleData.getStationName(train.to, isArabic),
                            style: GoogleFonts.cairo(
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  color: (isDark
                      ? AppTheme.darkSurfaceTertiary
                      : AppTheme.lightSurfaceTertiary)
                      .withValues(alpha: 0.5),
                  height: 1,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'يبدأ من' : 'Starting from',
                          style: GoogleFonts.cairo(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${cheapestClass.value} ${isArabic ? 'جنيه' : 'EGP'}',
                          style: GoogleFonts.cairo(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentDefault,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isArabic ? 'احجز الآن' : 'Book Now',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
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
      ),
    );
  }
}
