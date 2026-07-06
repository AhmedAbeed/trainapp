import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'services/train_manager_service.dart';
import 'screens/login_screen.dart';
import 'services/notification_helper.dart';

final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📱 إشعار في الخلفية: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();

  await NotificationHelper.initialize();

  final appState = AppState();
  
  appState.onNotificationReceived = (title, body) {
    NotificationHelper.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );

    snackbarKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          body,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.accentDefault,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  };

  if (FirebaseAuth.instance.currentUser != null) {
    await appState.refreshUserData();
    await appState.loadLatestBooking();
  }

  await _initializeFirebaseMessaging();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const ENRApp(),
    ),
  );
}

Future<void> _initializeFirebaseMessaging() async {
  try {
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        NotificationHelper.showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
      }
    });
  } catch (e) {
    debugPrint('❌ Firebase Messaging Error: $e');
  }
}

class ENRApp extends StatelessWidget {
  const ENRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          scaffoldMessengerKey: snackbarKey,
          title: 'Egyptian National Railways',
          debugShowCheckedModeBanner: false,
          theme: appState.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: const LoginScreen(),
          builder: (context, child) {
            return Directionality(
              textDirection:
                  appState.isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },
        );
      },
    );
  }
}
