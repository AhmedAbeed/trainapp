import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/models.dart';
import 'conductor_dashboard.dart';
import 'train_status_manager_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class TrainSelectionScreen extends StatefulWidget {
  const TrainSelectionScreen({super.key});

  @override
  State<TrainSelectionScreen> createState() => _TrainSelectionScreenState();
}

class _TrainSelectionScreenState extends State<TrainSelectionScreen> {
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
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (!ctx.mounted) return;
              ctx.read<AppState>().logout();
              Navigator.pushAndRemoveUntil(ctx, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isArabic ? 'تسجيل خروج' : 'Logout', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  List<TrainSchedule> _allTrains = [];
  List<TrainSchedule> _filteredTrains = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTrains();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadTrains() {
    setState(() => _isLoading = true);
    _allTrains = SampleData.getAllTrains();

    final seen = <String>{};
    _allTrains = _allTrains.where((train) {
      if (seen.contains(train.trainNumber)) {
        return false;
      } else {
        seen.add(train.trainNumber);
        return true;
      }
    }).toList();

    _filteredTrains = _allTrains;

    debugPrint("========== 🚆 القطارات المتاحة للكوميسيري ==========");
    debugPrint("العدد الإجمالي: ${_allTrains.length}");
    setState(() => _isLoading = false);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterTrains();
    });
  }

  void _filterTrains() {
    if (_searchQuery.isEmpty) {
      _filteredTrains = _allTrains;
    } else {
      _filteredTrains = _allTrains.where((train) {
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
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredTrains = _allTrains;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final isArabic = context.watch<AppState>().isArabic;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'لوحة تحكم الكوميسيري' : 'Commissary Dashboard',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor:
              isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTrains,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                color: Colors.orange.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainStatusManagerScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic
                                    ? 'إدارة حالات القطارات'
                                    : 'Train Status Management',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isArabic
                                    ? 'تحديث حالة القطار (تأخير / إلغاء / تغيير رصيف) وإرسال إشعارات للركاب'
                                    : 'Update train status (delay/cancel/platform change) and notify passengers',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.orange.shade800,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: isDark
                  ? AppTheme.darkSurfacePrimary
                  : AppTheme.lightSurfacePrimary,
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'ابحث برقم القطار...'
                      : 'Search by train number...',
                  hintStyle: GoogleFonts.cairo(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  prefixIcon: Icon(Icons.search, color: AppTheme.accentDefault),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon:
                              Icon(Icons.clear, color: AppTheme.textSecondary),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.darkSurfaceTertiary
                          : AppTheme.lightSurfaceTertiary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.darkSurfaceTertiary
                          : AppTheme.lightSurfaceTertiary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.accentDefault),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isArabic
                        ? 'اختر قطاراً للبدء في رحلة الكوميسيري'
                        : 'Select a train to start your commissary trip',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'القطارات المتاحة' : 'Available Trains',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  Text(
                    '${_filteredTrains.length} ${isArabic ? 'قطار' : 'trains'}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTrains.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.train_outlined,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isArabic
                                    ? 'لا توجد قطارات تطابق البحث'
                                    : 'No trains match your search',
                                style: GoogleFonts.cairo(
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTrains.length,
                          itemBuilder: (ctx, i) {
                            final train = _filteredTrains[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppTheme.accentDefault.withValues(alpha: 0.2),
                                  child: Icon(Icons.train,
                                      color: AppTheme.accentDefault),
                                ),
                                title: Text(
                                  '${train.trainNumber} - ${SampleData.getTrainName(train.trainName, isArabic)}',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 12,
                                          color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${SampleData.getStationName(train.from, isArabic)} → ${SampleData.getStationName(train.to, isArabic)}',
                                          style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.accentDefault.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.arrow_forward_ios,
                                      size: 14, color: AppTheme.accentDefault),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ConductorDashboard(train: train),
                                    ),
                                  );
                                },
                              ),
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
