import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/notification_helper.dart';

class TrainStatusManagerScreen extends StatefulWidget {
  const TrainStatusManagerScreen({super.key});

  @override
  State<TrainStatusManagerScreen> createState() =>
      _TrainStatusManagerScreenState();
}

class _TrainStatusManagerScreenState extends State<TrainStatusManagerScreen> {
  TrainStatus? _selectedStatus;
  String? _selectedTrainNumber;
  final _reasonCtrl = TextEditingController();
  int? _delayMinutes;
  bool _isUpdating = false;
  bool _isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatus() async {
    if (_selectedTrainNumber == null) {
      _showSnackBar('يرجى اختيار القطار', Colors.orange);
      return;
    }
    if (_selectedStatus == null) {
      _showSnackBar('يرجى اختيار الحالة', Colors.orange);
      return;
    }
    if (_reasonCtrl.text.isEmpty) {
      _showSnackBar('يرجى كتابة سبب التغيير', Colors.orange);
      return;
    }

    if (_selectedStatus == TrainStatus.delayed && _delayMinutes == null) {
      _showSnackBar('يرجى إدخال مدة التأخير', Colors.orange);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final statusString = _selectedStatus.toString().split('.').last;
      final isArabic = context.read<AppState>().isArabic;

      // ✅ 1. حفظ الحالة في train_statuses (ليظهر للجميع فوراً)
      await _firestore
          .collection('train_statuses')
          .doc(_selectedTrainNumber)
          .set({
        'trainNumber': _selectedTrainNumber,
        'status': statusString,
        'reason': _reasonCtrl.text,
        'delayMinutes': _delayMinutes ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ 2. جلب كل الحجوزات (valid + scanned) مش بس valid
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('trainNumber', isEqualTo: _selectedTrainNumber)
          .where('status', whereIn: ['valid', 'scanned'])
          .get();

      final notificationTitle =
          _getNotificationTitle(statusString, _selectedTrainNumber!, isArabic);
      final notificationBody = _getNotificationBody(
          statusString, _reasonCtrl.text, _delayMinutes, isArabic);

      // ✅ 3. حفظ إشعار لكل مستخدم باستخدام batch لضمان الأداء
      final batch = _firestore.batch();
      final seenUserIds = <String>{};
      int notificationsCount = 0;

      for (var bookingDoc in bookingsSnapshot.docs) {
        final userId = (bookingDoc.data() as Map<String, dynamic>)['userId'];
        if (userId != null && userId.isNotEmpty && !seenUserIds.contains(userId)) {
          seenUserIds.add(userId);
          final notifRef = _firestore.collection('notifications').doc();
          batch.set(notifRef, {
            'userId': userId,
            'title': notificationTitle,
            'body': notificationBody,
            'trainNumber': _selectedTrainNumber,
            'status': statusString,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
          notificationsCount++;
        }
      }
      if (notificationsCount > 0) {
        await batch.commit();
      }

      // ✅ 4. تحديث AppState (المحلي)
      context.read<AppState>().updateTrainStatusAndNotify(
        trainNumber: _selectedTrainNumber!,
        trainName: _selectedTrainNumber!, // أو اسم القطار لو متوفر
        newStatus: _selectedStatus!,
        reason: _reasonCtrl.text,
        delayMinutes: _delayMinutes ?? 0,
      );

      // ✅ إظهار إشعار محلي للمستخدم الحالي (الكوميسيري)
      await NotificationHelper.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notificationTitle,
        body: notificationBody,
      );

      _showSnackBar(
          '✅ تم تحديث حالة القطار وإرسال $notificationsCount إشعار للمستخدمين',
          AppTheme.successGreen);

      _reasonCtrl.clear();
      setState(() {
        _delayMinutes = null;
        _selectedStatus = null;
        _selectedTrainNumber = null;
      });
    } catch (e) {
      debugPrint("❌ خطأ في تحديث الحالة: $e");
      _showSnackBar('حدث خطأ أثناء تحديث الحالة', AppTheme.accentDefault);
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  String _getNotificationTitle(
      String status, String trainNumber, bool isArabic) {
    switch (status) {
      case 'delayed':
        return isArabic
            ? '⚠️ تأخير القطار $trainNumber'
            : '⚠️ Train $trainNumber Delayed';
      case 'cancelled':
        return isArabic
            ? '❌ إلغاء القطار $trainNumber'
            : '❌ Train $trainNumber Cancelled';
      case 'accident':
        return isArabic
            ? '🚨 حادث / عطل القطار $trainNumber'
            : '🚨 Train $trainNumber Accident';
      case 'running':
        return isArabic
            ? '✅ القطار $trainNumber يعمل بشكل طبيعي'
            : '✅ Train $trainNumber Running Normally';
      default:
        return isArabic
            ? '🚆 تحديث القطار $trainNumber'
            : '🚆 Train $trainNumber Update';
    }
  }

  String _getNotificationBody(
      String status, String reason, int? delayMinutes, bool isArabic) {
    switch (status) {
      case 'delayed':
        return isArabic
            ? 'القطار متأخر $delayMinutes دقيقة. السبب: $reason'
            : 'Train delayed by $delayMinutes minutes. Reason: $reason';
      case 'cancelled':
        return isArabic
            ? 'تم إلغاء القطار. السبب: $reason'
            : 'Train cancelled. Reason: $reason';
      case 'accident':
        return isArabic
            ? 'تم الإبلاغ عن حادث/عطل في القطار. السبب: $reason'
            : 'Accident/breakdown reported on train. Reason: $reason';
      case 'running':
        return isArabic
            ? 'القطار يعمل بشكل طبيعي. $reason'
            : 'Train is running normally. $reason';
      default:
        return isArabic
            ? 'تم تحديث حالة القطار: $reason'
            : 'Train status updated: $reason';
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _statusColor(TrainStatus s) {
    switch (s) {
      case TrainStatus.running:
        return Colors.green;
      case TrainStatus.delayed:
        return Colors.orange;
      case TrainStatus.cancelled:
        return Colors.red;
      case TrainStatus.accident:
        return Colors.red.shade900;
    }
  }

  IconData _statusIcon(TrainStatus s) {
    switch (s) {
      case TrainStatus.running:
        return Icons.check_circle_outline;
      case TrainStatus.delayed:
        return Icons.access_time;
      case TrainStatus.cancelled:
        return Icons.cancel_outlined;
      case TrainStatus.accident:
        return Icons.warning_amber_rounded;
    }
  }

  String _statusLabel(TrainStatus s, bool isArabic) {
    switch (s) {
      case TrainStatus.running:
        return isArabic ? 'يعمل بشكل طبيعي' : 'Running';
      case TrainStatus.delayed:
        return isArabic ? 'متأخر' : 'Delayed';
      case TrainStatus.cancelled:
        return isArabic ? 'ملغي' : 'Cancelled';
      case TrainStatus.accident:
        return isArabic ? 'حادث / عطل' : 'Accident';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final isArabic = context.watch<AppState>().isArabic;
    final trainsList = SampleData.getTrainsList(isArabic);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'إدارة حالات القطارات' : 'Train Status Management',
            style: GoogleFonts.cairo(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري تحميل القطارات...'),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'إدارة حالات القطارات' : 'Train Status Management',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor:
              isDark ? AppTheme.darkBgDefault : AppTheme.lightBgDefault,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ إحصائيات القطارات
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfacePrimary
                      : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'عدد القطارات المتاحة' : 'Available Trains',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentDefault,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${trainsList.length}',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ اختيار القطار
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfacePrimary
                      : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'اختر القطار' : 'Select Train',
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTrainNumber,
                      hint: Text(
                        isArabic ? '-- اختر القطار --' : '-- Select Train --',
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.train,
                            color: AppTheme.accentDefault),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      isExpanded: true,
                      items: trainsList.map((train) {
                        return DropdownMenuItem<String>(
                          value: train['number'],
                          child: Row(
                            children: [
                              const Icon(Icons.train,
                                  size: 16, color: AppTheme.accentDefault),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  train['display']!,
                                  style: GoogleFonts.cairo(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTrainNumber = value;
                          _selectedStatus = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ✅ اختيار الحالة الجديدة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfacePrimary
                      : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'اختر الحالة الجديدة' : 'Select New Status',
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: TrainStatus.values.map((status) {
                        final isSelected = _selectedStatus == status;
                        final color = _statusColor(status);
                        return GestureDetector(
                          onTap: () => setState(() => _selectedStatus = status),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : (isDark
                                      ? AppTheme.darkSurfaceSecondary
                                      : AppTheme.lightSurfaceSecondary),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: color, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(status),
                                    color: isSelected ? Colors.white : color,
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _statusLabel(status, isArabic),
                                  style: GoogleFonts.cairo(
                                    color: isSelected ? Colors.white : color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // ✅ مدة التأخير
              if (_selectedStatus == TrainStatus.delayed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurfacePrimary
                        : AppTheme.lightSurfacePrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isArabic
                                ? 'مدة التأخير (بالدقائق)'
                                : 'Delay Duration (minutes)',
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _delayMinutes = int.tryParse(value),
                        decoration: InputDecoration(
                          hintText: isArabic ? 'مثال: 30' : 'Example: 30',
                          prefixIcon: const Icon(Icons.timer,
                              size: 20, color: Colors.grey),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ✅ سبب التغيير
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurfacePrimary
                      : AppTheme.lightSurfacePrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note,
                            color: AppTheme.accentDefault, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'سبب التغيير' : 'Reason for Change',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: isArabic
                            ? 'مثال: عطل فني في المحرك، سوء الأحوال الجوية...'
                            : 'Example: Technical engine failure, bad weather...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ✅ زر التحديث
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _updateStatus,
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.update, size: 22),
                  label: Text(
                    _isUpdating
                        ? (isArabic ? 'جاري التحديث...' : 'Updating...')
                        : (isArabic
                            ? 'تحديث حالة القطار'
                            : 'Update Train Status'),
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentDefault,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
