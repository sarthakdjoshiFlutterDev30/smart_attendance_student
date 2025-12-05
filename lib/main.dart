import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Student/Splash.dart';
import 'Student/ui/app_theme.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.subscribeToTopic('all');
  print('📢 Subscribed to topic: all');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print('📥 Notification Received (Foreground):');
      print('Title: ${message.notification!.title}');
      print('Body: ${message.notification!.body}');
    }
  });

  runApp(
      const MyApp());
 }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _token;
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        _token = token;
      });
      print('FCM Token: $_token');
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
    _requestCameraPermission();
  }
  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isDenied) {
      // We haven't asked yet, or the user denied it previously but not permanently
      if (await Permission.camera.request().isGranted) {
        print("✅ Camera permission granted");
      } else {
        print("❌ Camera permission denied");
      }
    } else if (status.isPermanentlyDenied) {
      // The user opted to never see the permission request again
      print("⚠️ Camera permission permanently denied. Opening settings.");
      openAppSettings();
    } else if (status.isGranted) {
      print("✅ Camera permission already granted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      home: Splash(),
    );
  }
}
