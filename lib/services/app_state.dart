import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  UserModel? _currentUser;
  Booking? _currentBooking;
  bool _isAdmin = false;

  bool _isDarkMode = true;
  bool _isArabic = true;
  bool _notificationsEnabled = true;

  Map<String, dynamic>? _qrData;
  StreamSubscription<DocumentSnapshot>? _bookingSubscription;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  // لتجنب تكرار الإشعارات في نفس الجلسة
  final Set<String> _showedNotifIds = {};

  /// ✅ كولباك لإظهار إشعار مرئي في الواجهة (SnackBar / Dialog)
  Function(String title, String body)? onNotificationReceived;

  final Map<String, TrainStatusInfo> _trainStatuses = {};

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // ================= Getters =================
  UserModel? get currentUser => _currentUser;
  Booking? get currentBooking => _currentBooking;
  bool get isAdmin => _isAdmin;
  bool get hasBooking => _currentBooking != null;
  bool get isDarkMode => _isDarkMode;
  bool get isArabic => _isArabic;
  bool get notificationsEnabled => _notificationsEnabled;
  String? get userId => _auth.currentUser?.uid;
  Map<String, dynamic>? get qrData => _qrData;

  TrainStatusInfo? getTrainStatus(String trainNumber) => _trainStatuses[trainNumber];

  // ================= Setters =================
  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setArabic(bool value) {
    _isArabic = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  // ================= ✅ المستمعين (Listeners) =================

  void _startBookingListener(String bookingId) {
    _bookingSubscription?.cancel();
    debugPrint('📡 [Listener] Watching booking: $bookingId');
    _bookingSubscription = _firestore.collection('bookings').doc(bookingId).snapshots().listen((snap) {
      if (snap.exists && snap.data() != null) {
        _currentBooking = _parseBooking(snap.id, snap.data()!);
        notifyListeners();
        debugPrint('🔔 [Listener] Booking status synced: ${_currentBooking?.status}');
      }
    });
  }

  void _startNotificationsListener() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _notificationsSubscription?.cancel();
    debugPrint('📡 [Listener] Watching notifications for user: $uid');

    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final docId = change.doc.id;
          final data = change.doc.data() as Map<String, dynamic>;
          
          if (!_showedNotifIds.contains(docId)) {
            debugPrint('📨 [Listener] New unread notification: ${data['title']}');
            _showedNotifIds.add(docId);
            
            if (onNotificationReceived != null) {
              onNotificationReceived!(data['title'] ?? '', data['body'] ?? '');
            }
            
            change.doc.reference.update({'read': true});
          }
        }
      }
    });
  }

  // ================= ✅ المصادقة (Auth) =================

  Future<void> refreshUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          _currentUser = UserModel(
            id: user.uid,
            name: data?['name'] ?? '',
            email: user.email ?? '',
            phone: data?['phone'] ?? '',
            nationalId: data?['nationalId'] ?? '',
          );
          _startNotificationsListener();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ refreshUserData Error: $e');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      await refreshUserData();
      await loadLatestBooking();
      _isAdmin = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loginWithNameAndEmailAndBooking(String name, String email, bool has) async {
    _currentUser = UserModel(id: _auth.currentUser?.uid ?? '', name: name, email: email, phone: '', nationalId: '');
    _isAdmin = false;
    if (has) await loadLatestBooking();
    _startNotificationsListener();
    notifyListeners();
  }

  Future<void> loginWithBookingStatus(String email, bool has) async {
    _currentUser = UserModel(id: _auth.currentUser?.uid ?? '', name: email.split('@')[0], email: email, phone: '', nationalId: '');
    _isAdmin = false;
    if (has) await loadLatestBooking();
    _startNotificationsListener();
    notifyListeners();
  }

  Future<bool> loginAsAdmin(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      _isAdmin = true;
      _currentUser = null;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String name, String email, String phone, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email.trim(),
        'phone': phone,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp()
      });
      await refreshUserData();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> registerAndLogin(String name, String email, String phone, String password) async {
    _currentUser = UserModel(id: _auth.currentUser?.uid ?? '', name: name, email: email, phone: phone, nationalId: '');
    _isAdmin = false;
    notifyListeners();
  }

  Future<bool> updateUser({required String name, required String email, required String phone}) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('users').doc(uid).update({'name': name, 'email': email.trim(), 'phone': phone});
        _currentUser = UserModel(id: uid, name: name, email: email, phone: phone, nationalId: _currentUser?.nationalId ?? '');
        notifyListeners();
        return true;
      } catch (e) { return false; }
    }
    return false;
  }

  Future<void> logout() async {
    _bookingSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _showedNotifIds.clear();
    await _auth.signOut();
    _currentUser = null;
    _currentBooking = null;
    _isAdmin = false;
    notifyListeners();
  }

  // ================= ✅ الحجوزات (Booking) =================

  Future<void> loadLatestBooking() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await _firestore.collection('bookings')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        _currentBooking = _parseBooking(snap.docs.first.id, snap.docs.first.data());
        _startBookingListener(snap.docs.first.id);
      }
      notifyListeners();
    } catch (e) {
      final all = await _firestore.collection('bookings').where('userId', isEqualTo: uid).get();
      if (all.docs.isNotEmpty) {
        final sorted = all.docs..sort((a, b) => ((b.data()['createdAt'] as Timestamp?)?.seconds ?? 0).compareTo((a.data()['createdAt'] as Timestamp?)?.seconds ?? 0));
        _currentBooking = _parseBooking(sorted.first.id, sorted.first.data());
        _startBookingListener(sorted.first.id);
      }
      notifyListeners();
    }
  }

  Future<void> saveAndSetBooking(Booking booking) async {
    await _firestore.collection('bookings').doc(booking.bookingId).set({
      'bookingId': booking.bookingId,
      'ticketNumber': booking.ticketNumber,
      'passengerName': booking.passengerName,
      'trainNumber': booking.trainNumber,
      'trainName': booking.trainName,
      'from': booking.from.name,
      'to': booking.to.name,
      'departureTime': booking.departureTime,
      'arrivalTime': booking.arrivalTime,
      'date': booking.date,
      'seatClass': booking.seatClass,
      'seatNumber': booking.seatNumber,
      'price': booking.price,
      'status': 'valid',
      'userId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'stops': booking.stops.map((s) => s.name).toList(),
    });
    _currentBooking = booking;
    _startBookingListener(booking.bookingId);
    notifyListeners();
  }

  Booking _parseBooking(String id, Map<String, dynamic> data) {
    return Booking(
      bookingId: id,
      ticketNumber: data['ticketNumber'] ?? '',
      passengerName: data['passengerName'] ?? '',
      trainNumber: data['trainNumber'] ?? '',
      trainName: data['trainName'] ?? '',
      from: SampleData.getStationByName(data['from'] ?? ''),
      to: SampleData.getStationByName(data['to'] ?? ''),
      departureTime: data['departureTime'] ?? '',
      arrivalTime: data['arrivalTime'] ?? '',
      date: data['date'] ?? '',
      seatClass: data['seatClass'] ?? '',
      seatNumber: data['seatNumber'] ?? 0,
      price: data['price'] ?? 0,
      status: data['status'] == 'scanned' ? BookingStatus.scanned : BookingStatus.valid,
      stops: (data['stops'] as List? ?? []).map((s) => SampleData.getStationByName(s.toString())).toList(),
      currentStopIndex: 0,
    );
  }

  // ================= ✅ حالة القطارات (Train Status) =================

  Future<void> updateTrainStatusAndNotify({required String trainNumber, required String trainName, required TrainStatus newStatus, String reason = '', int delayMinutes = 0}) async {
    final statusStr = newStatus.toString().split('.').last;
    await _firestore.collection('train_statuses').doc(trainNumber).set({
      'trainNumber': trainNumber,
      'status': statusStr,
      'reason': reason,
      'delayMinutes': delayMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Future<void> subscribeToTrainTopic(String trainNumber) async {
    try { await _messaging.subscribeToTopic('train_$trainNumber'); } catch (e) {}
  }

  Future<void> unsubscribeFromTrainTopic(String trainNumber) async {
    try { await _messaging.unsubscribeFromTopic('train_$trainNumber'); } catch (e) {}
  }
}

class TrainStatusInfo {
  final String trainNumber;
  final TrainStatus status;
  final String reason;
  final int delayMinutes;
  final DateTime updatedAt;
  const TrainStatusInfo({required this.trainNumber, required this.status, required this.reason, required this.delayMinutes, required this.updatedAt});
}
