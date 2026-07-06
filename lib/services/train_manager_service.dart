import 'package:flutter/material.dart';
import '../models/models.dart';

class TrainManagerService extends ChangeNotifier {
  final Map<String, TrainStatus> _trainStatusMap = {};
  final Map<String, String> _trainStatusReason = {};
  final Map<String, int?> _trainDelayMinutes = {};
  final List<TrainStatusLog> _statusLogs = [];
  final List<TrainNotification> _notifications = [];

  Map<String, TrainStatus> get trainStatusMap => _trainStatusMap;
  List<TrainStatusLog> get statusLogs => _statusLogs;
  List<TrainNotification> get notifications => _notifications;

  void initializeTrains(List<TrainSchedule> trains) {
    for (var train in trains) {
      if (!_trainStatusMap.containsKey(train.trainNumber)) {
        _trainStatusMap[train.trainNumber] = TrainStatus.running;
        _trainStatusReason[train.trainNumber] = 'القطار يعمل بشكل طبيعي';
        _trainDelayMinutes[train.trainNumber] = null;
      }
    }
    notifyListeners();
  }

  TrainStatus getTrainStatus(String trainNumber) {
    return _trainStatusMap[trainNumber] ?? TrainStatus.running;
  }

  String getTrainStatusReason(String trainNumber) {
    return _trainStatusReason[trainNumber] ?? 'القطار يعمل بشكل طبيعي';
  }

  int? getTrainDelay(String trainNumber) {
    return _trainDelayMinutes[trainNumber];
  }

  Future<void> updateTrainStatus({
    required String trainNumber,
    required String trainName,
    required TrainStatus newStatus,
    required String reason,
    int? delayMinutes,
    required List<Map<String, dynamic>> affectedUsers,
    required Function(
            String userId, String userEmail, String title, String message)
        sendNotification,
  }) async {
    final oldStatus = _trainStatusMap[trainNumber] ?? TrainStatus.running;

    _trainStatusMap[trainNumber] = newStatus;
    _trainStatusReason[trainNumber] = reason;
    _trainDelayMinutes[trainNumber] = delayMinutes;

    final log = TrainStatusLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trainNumber: trainNumber,
      status: newStatus,
      reason: reason,
      createdAt: DateTime.now(),
      delayMinutes: delayMinutes,
    );
    _statusLogs.insert(0, log);

    if (oldStatus != newStatus) {
      for (var user in affectedUsers) {
        final title = _getNotificationTitle(newStatus, trainNumber, trainName);
        final message =
            _getNotificationMessage(newStatus, trainName, reason, delayMinutes);

        await sendNotification(
          user['userId'],
          user['email'],
          title,
          message,
        );

        _notifications.add(TrainNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user['userId'],
          userEmail: user['email'],
          trainNumber: trainNumber,
          title: title,
          message: message,
          createdAt: DateTime.now(),
          isRead: false,
        ));
      }
    }

    notifyListeners();
  }

  String _getNotificationTitle(
      TrainStatus status, String trainNumber, String trainName) {
    switch (status) {
      case TrainStatus.running:
        return '✅ القطار $trainNumber يعمل بشكل طبيعي';
      case TrainStatus.delayed:
        return '⚠️ تأخر القطار $trainNumber';
      case TrainStatus.cancelled:
        return '❌ إلغاء القطار $trainNumber';
      case TrainStatus.accident:
        return '🚨 عطل في القطار $trainNumber';
    }
  }

  String _getNotificationMessage(
      TrainStatus status, String trainName, String reason, int? delayMinutes) {
    switch (status) {
      case TrainStatus.running:
        return 'القطار $trainName يعمل بشكل طبيعي الآن. ${reason != 'القطار يعمل بشكل طبيعي' ? 'السبب: $reason' : ''}';
      case TrainStatus.delayed:
        return 'القطار $trainName متأخر ${delayMinutes ?? ''} دقيقة. السبب: $reason';
      case TrainStatus.cancelled:
        return 'تم إلغاء القطار $trainName. السبب: $reason. يرجى التواصل مع خدمة العملاء لإعادة الحجز أو استرداد المبلغ.';
      case TrainStatus.accident:
        return 'تم تسجيل عطل في القطار $trainName. السبب: $reason. سيتم إبلاغكم بأي تحديثات جديدة.';
    }
  }

  List<TrainNotification> getUserNotifications(String userId) {
    return _notifications.where((n) => n.userId == userId).toList();
  }

  void markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = TrainNotification(
        id: _notifications[index].id,
        userId: _notifications[index].userId,
        userEmail: _notifications[index].userEmail,
        trainNumber: _notifications[index].trainNumber,
        title: _notifications[index].title,
        message: _notifications[index].message,
        createdAt: _notifications[index].createdAt,
        isRead: true,
      );
      notifyListeners();
    }
  }
}
