import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isArabic = appState.isArabic;
    final userId = appState.userId;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'الإشعارات' : 'Notifications',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: appState.isDarkMode
              ? AppTheme.darkBgDefault
              : AppTheme.lightBgDefault,
          actions: [
            TextButton.icon(
              onPressed: () async {
                if (userId != null) {
                  final batch = FirebaseFirestore.instance.batch();
                  final notifications = await FirebaseFirestore.instance
                      .collection('notifications')
                      .where('userId', isEqualTo: userId)
                      .get();

                  for (var doc in notifications.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isArabic
                          ? 'تم حذف جميع الإشعارات'
                          : 'All notifications deleted'),
                      backgroundColor: AppTheme.accentDefault,
                    ),
                  );
                }
              },
              icon: Icon(Icons.delete_outline, size: 20),
              label: Text(isArabic ? 'حذف الكل' : 'Delete All'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
        body: userId == null
            ? Center(
                child: Text(
                  isArabic ? 'يرجى تسجيل الدخول أولاً' : 'Please login first',
                  style: GoogleFonts.cairo(),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: userId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isArabic
                                ? 'لا توجد إشعارات حالياً'
                                : 'No notifications yet',
                            style: GoogleFonts.cairo(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic
                                ? 'سيظهر هنا إشعارات حالة القطارات والتحديثات'
                                : 'Train status updates will appear here',
                            style: GoogleFonts.cairo(
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final notifications = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (ctx, index) {
                      final doc = notifications[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return _NotificationCard(
                        id: doc.id,
                        title: data['title'] ?? '',
                        message: data['body'] ?? '',
                        time: data['createdAt'] != null
                            ? _formatTime(data['createdAt'], isArabic)
                            : isArabic
                                ? 'الآن'
                                : 'Now',
                        isRead: data['isRead'] ?? false,
                        status: data['status'] ?? 'info',
                        trainNumber: data['trainNumber'],
                        onTap: () async {
                          if (!(data['isRead'] ?? false)) {
                            await doc.reference.update({'isRead': true});
                          }
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp, bool isArabic) {
    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Now';
    } else if (difference.inHours < 1) {
      return isArabic
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return isArabic
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return isArabic
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _NotificationCard extends StatefulWidget {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String status;
  final String? trainNumber;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.status,
    this.trainNumber,
    required this.onTap,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppState>(context).isDarkMode;

    Color getStatusColor() {
      switch (widget.status) {
        case 'delayed':
          return Colors.orange;
        case 'cancelled':
          return Colors.red;
        case 'accident':
          return Colors.red.shade900;
        case 'running':
          return Colors.green;
        default:
          return AppTheme.accentDefault;
      }
    }

    IconData getStatusIcon() {
      switch (widget.status) {
        case 'delayed':
          return Icons.timer_outlined;
        case 'cancelled':
          return Icons.cancel_outlined;
        case 'accident':
          return Icons.warning_amber_rounded;
        case 'running':
          return Icons.check_circle_outline;
        default:
          return Icons.notifications_outlined;
      }
    }

    return GestureDetector(
      onTap: () {
        widget.onTap();
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.isRead
              ? (isDark
                  ? AppTheme.darkSurfacePrimary.withValues(alpha: 0.5)
                  : AppTheme.lightSurfacePrimary.withValues(alpha: 0.5))
              : (isDark
                  ? AppTheme.darkSurfacePrimary
                  : AppTheme.lightSurfacePrimary),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isRead
                ? (isDark
                        ? AppTheme.darkSurfaceTertiary
                        : AppTheme.lightSurfaceTertiary)
                    .withValues(alpha: 0.3)
                : getStatusColor().withValues(alpha: 0.5),
            width: widget.isRead ? 0.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.isRead
                          ? (isDark
                              ? AppTheme.darkSurfaceTertiary
                              : AppTheme.lightSurfaceTertiary)
                          : getStatusColor().withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      getStatusIcon(),
                      color: widget.isRead
                          ? AppTheme.textSecondary
                          : getStatusColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: GoogleFonts.cairo(
                                  color: widget.isRead
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (widget.trainNumber != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: getStatusColor().withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.trainNumber!,
                                  style: GoogleFonts.cairo(
                                    color: getStatusColor(),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: GoogleFonts.cairo(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: AppTheme.textSecondary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.time,
                              style: GoogleFonts.cairo(
                                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            if (!widget.isRead)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: getStatusColor(),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'جديد',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.message.length > 100)
              Container(
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppTheme.darkSurfaceSecondary
                          : AppTheme.lightSurfaceSecondary)
                      .withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                          style: GoogleFonts.cairo(
                            color: AppTheme.accentDefault,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: AppTheme.accentDefault,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
