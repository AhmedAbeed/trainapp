import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import 'booking_tab.dart';
import 'ticket_screen.dart';
import 'track_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 2});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasBooking = appState.hasBooking;
    final isArabic = appState.isArabic;

    final pages = hasBooking
        ? [
            const TicketScreen(),
            const TrackScreen(),
            const BookingTab(),
            const ProfileScreen(),
          ]
        : [
            const BookingTab(),
            const ProfileScreen(),
          ];

    final navItems = hasBooking
        ? [
            _navItem(Icons.confirmation_number_outlined,
                Icons.confirmation_number, isArabic ? 'تذكرتي' : 'My Ticket'),
            _navItem(
                Icons.map_outlined, Icons.map, isArabic ? 'رحلتي' : 'My Trip'),
            _navItem(
                Icons.train_outlined, Icons.train, isArabic ? 'احجز' : 'Book'),
            _navItem(Icons.person_outline, Icons.person,
                isArabic ? 'حسابي' : 'Account'),
          ]
        : [
            _navItem(
                Icons.train_outlined, Icons.train, isArabic ? 'احجز' : 'Book'),
            _navItem(Icons.person_outline, Icons.person,
                isArabic ? 'حسابي' : 'Account'),
          ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: hasBooking && _currentIndex == 1
            ? null
            : AppBar(
                title: Text(
                  _getTitle(isArabic, hasBooking, _currentIndex),
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: appState.isDarkMode
                    ? AppTheme.darkBgDefault
                    : AppTheme.lightBgDefault,
                actions: [
                  if (appState.notificationsEnabled)
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        );
                      },
                    ),
                ],
              ),
        body: IndexedStack(
          index: _currentIndex.clamp(0, pages.length - 1),
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: appState.isDarkMode
                ? AppTheme.darkSurfacePrimary
                : AppTheme.lightSurfacePrimary,
            border: Border(
              top: BorderSide(
                color: appState.isDarkMode
                    ? AppTheme.darkSurfaceTertiary
                    : AppTheme.lightSurfaceTertiary,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: List.generate(navItems.length, (i) {
                  final item = navItems[i];
                  final selected = _currentIndex == i;
                  final textColor = selected
                      ? AppTheme.accentDefault
                      : (appState.isDarkMode
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              selected
                                  ? item['activeIcon'] as IconData
                                  : item['icon'] as IconData,
                              key: ValueKey(selected),
                              color: textColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            style: GoogleFonts.cairo(
                              color: textColor,
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTitle(bool isArabic, bool hasBooking, int index) {
    if (!hasBooking) {
      return isArabic ? 'احجز رحلتك' : 'Book Your Trip';
    }

    switch (index) {
      case 0:
        return isArabic ? 'تذكرتي' : 'My Ticket';
      case 1:
        return '';
      case 2:
        return isArabic ? 'احجز رحلتك' : 'Book Your Trip';
      case 3:
        return isArabic ? 'حسابي' : 'My Account';
      default:
        return '';
    }
  }

  Map<String, dynamic> _navItem(
      IconData icon, IconData activeIcon, String label) {
    return {'icon': icon, 'activeIcon': activeIcon, 'label': label};
  }
}
