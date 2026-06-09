import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import 'notifications_screen.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final booking = appState.currentBooking;
    final isArabic = appState.isArabic;
    final isDark = appState.isDarkMode;

    if (booking == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.train_outlined, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'لا توجد رحلة حالية' : 'No current trip',
                style: GoogleFonts.cairo(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic ? 'قم بحجز تذكرة لعرض تفاصيل رحلتك' : 'Book a ticket to view your trip details',
                style: GoogleFonts.cairo(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ التأكد من وجود stops
    if (booking.stops.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            isArabic ? 'لا توجد محطات متاحة لهذه الرحلة' : 'No stations available for this trip',
            style: GoogleFonts.cairo(color: AppTheme.textSecondary),
          ),
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
              title: Text(
                isArabic ? 'رحلتي' : 'My Trip',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
              actions: [
                if (appState.notificationsEnabled)
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.accentDefault,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Journey header
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.train, color: AppTheme.accentDefault, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  SampleData.getTrainName(booking.trainName, isArabic),
                                  style: GoogleFonts.cairo(
                                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${SampleData.getStationName(booking.from, isArabic)} → ${SampleData.getStationName(booking.to, isArabic)}',
                                  style: GoogleFonts.cairo(
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              isArabic ? 'في الطريق' : 'On the way',
                              style: GoogleFonts.cairo(color: AppTheme.successGreen, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Live position
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
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isArabic ? 'الموقع الحالي' : 'Current Location',
                                style: GoogleFonts.cairo(
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isArabic
                                ? 'بالقرب من: ${booking.stops[booking.currentStopIndex].name}'
                                : 'Near: ${SampleData.getStationName(booking.stops[booking.currentStopIndex], isArabic)}',
                            style: GoogleFonts.cairo(
                                color: AppTheme.successGreen, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isArabic
                                ? 'متبقي ${booking.stops.length - booking.currentStopIndex - 1} محطات للوصول'
                                : '${booking.stops.length - booking.currentStopIndex - 1} stations left to arrive',
                            style: GoogleFonts.cairo(
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stops timeline
                    Text(
                      isArabic ? 'خط السير' : 'Route',
                      style: GoogleFonts.cairo(
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: List.generate(booking.stops.length, (i) {
                          final stop = booking.stops[i];
                          final isPast = i < booking.currentStopIndex;
                          final isCurrent = i == booking.currentStopIndex;
                          final isLast = i == booking.stops.length - 1;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? AppTheme.accentDefault
                                          : isPast
                                          ? AppTheme.successGreen
                                          : isDark
                                          ? AppTheme.darkSurfaceSecondary
                                          : AppTheme.lightSurfaceSecondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppTheme.accentDefault
                                            : isPast
                                            ? AppTheme.successGreen
                                            : isDark
                                            ? AppTheme.darkSurfaceTertiary
                                            : AppTheme.lightSurfaceTertiary,
                                        width: 2,
                                      ),
                                    ),
                                    child: isCurrent
                                        ? const Icon(Icons.train, color: Colors.white, size: 10)
                                        : isPast
                                        ? const Icon(Icons.check, color: Colors.white, size: 10)
                                        : null,
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 36,
                                      color: isPast
                                          ? AppTheme.successGreen
                                          : isDark
                                          ? AppTheme.darkSurfaceTertiary
                                          : AppTheme.lightSurfaceTertiary,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2, bottom: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        SampleData.getStationName(stop, isArabic),
                                        style: GoogleFonts.cairo(
                                          color: isCurrent
                                              ? AppTheme.accentDefault
                                              : isPast
                                              ? isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary
                                              : isDark
                                              ? AppTheme.darkTextPrimary
                                              : AppTheme.lightTextPrimary,
                                          fontSize: 14,
                                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                                        ),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentDefault.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isArabic ? 'هنا الآن' : 'Here now',
                                            style: GoogleFonts.cairo(
                                                color: AppTheme.accentDefault, fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Map button
                    GestureDetector(
                      onTap: () => setState(() => _showMap = !_showMap),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _showMap ? AppTheme.accentDefault : (isDark ? AppTheme.darkSurfaceTertiary : AppTheme.lightSurfaceTertiary),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _showMap ? Icons.map : Icons.map_outlined,
                              color: AppTheme.accentDefault,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _showMap
                                  ? (isArabic ? 'إخفاء الخريطة' : 'Hide Map')
                                  : (isArabic ? 'اضغط لعرض الخريطة' : 'Tap to show map'),
                              style: GoogleFonts.cairo(
                                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Icon(
                              _showMap ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showMap) ...[
                      const SizedBox(height: 12),
                      _MapWidget(booking: booking, isDarkMode: isDark),
                    ],

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

class _MapWidget extends StatelessWidget {
  final Booking booking;
  final bool isDarkMode;

  const _MapWidget({required this.booking, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    // ✅ التأكد من وجود stops
    if (booking.stops.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurfaceSecondary : AppTheme.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'لا توجد خريطة متاحة',
            style: GoogleFonts.cairo(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final currentStation = booking.stops[booking.currentStopIndex];
    final center = LatLng(currentStation.lat, currentStation.lng);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 280,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 7,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.enr.train',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: booking.stops.map((s) => LatLng(s.lat, s.lng)).toList(),
                  color: AppTheme.accentDefault,
                  strokeWidth: 3,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                ...booking.stops.asMap().entries.map((e) {
                  final i = e.key;
                  final stop = e.value;
                  final isCurrent = i == booking.currentStopIndex;
                  return Marker(
                    point: LatLng(stop.lat, stop.lng),
                    width: isCurrent ? 40 : 24,
                    height: isCurrent ? 40 : 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent ? AppTheme.accentDefault : (isDarkMode ? AppTheme.darkSurfacePrimary : AppTheme.lightSurfacePrimary),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent ? AppTheme.accentDefault : (isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                          width: 2,
                        ),
                        boxShadow: isCurrent
                            ? [BoxShadow(color: AppTheme.accentDefault.withValues(alpha: 0.5), blurRadius: 10)]
                            : [],
                      ),
                      child: Icon(
                        isCurrent ? Icons.train : Icons.circle,
                        color: isCurrent ? Colors.white : (isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        size: isCurrent ? 20 : 8,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}