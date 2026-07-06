import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class QRScannerScreen extends StatefulWidget {
  final TrainSchedule train;
  const QRScannerScreen({super.key, required this.train});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null) return;

    setState(() => _isScanning = false);
    _processTicket(value);
  }

  Future<void> _processTicket(String ticketData) async {
    final parts = ticketData.split('|');
    if (parts.length < 1) {
      _showResultDialog('خطأ', 'بيانات التذكرة غير صالحة', isError: true);
      return;
    }

    final ticketNumber = parts[0];
    
    try {
      final query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('ticketNumber', isEqualTo: ticketNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showResultDialog('غير موجودة', 'هذه التذكرة غير مسجلة في النظام', isError: true);
        return;
      }

      final bookingDoc = query.docs.first;
      final data = bookingDoc.data();
      final currentStatus = data['status'];
      final userId = data['userId'];
      final passengerName = data['passengerName'] ?? 'مسافر';

      if (currentStatus == 'scanned') {
        _showResultDialog('تنبيه', 'هذه التذكرة تم استخدامها مسبقاً!', isError: true);
        return;
      }

      await bookingDoc.reference.update({
        'status': 'scanned',
        'scannedAt': FieldValue.serverTimestamp(),
      });

      if (userId != null) {
        final isArabic = context.read<AppState>().isArabic;
        final title = isArabic ? '🎫 تم التحقق من تذكرتك' : '🎫 Ticket Verified';
        final body = isArabic 
            ? 'أهلاً بك يا $passengerName على متن القطار ${widget.train.trainNumber}. رحلة سعيدة!' 
            : 'Welcome aboard $passengerName, train ${widget.train.trainNumber}. Have a nice trip!';

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'type': 'ticket_scanned',
          'trainNumber': widget.train.trainNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      _showResultDialog('تم التحقق', 'تذكرة $passengerName صالحة. تم تسجيل الصعود بنجاح ✓', isError: false);

    } catch (e) {
      debugPrint('❌ Error validating ticket: $e');
      _showResultDialog('خطأ في النظام', 'حدث خطأ أثناء الاتصال بقاعدة البيانات', isError: true);
    }
  }

  void _showResultDialog(String title, String message, {required bool isError}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, 
                 color: isError ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isScanning = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isError ? Colors.grey : Colors.green,
            ),
            child: const Text('متابعة المسح', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('سكان القطار ${widget.train.trainNumber}'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: _isScanning ? Colors.green : Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              _isScanning ? 'وجّه الكاميرا نحو QR Code التذكرة' : 'جاري التحقق...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
