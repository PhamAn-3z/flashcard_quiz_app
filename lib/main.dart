import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flashcard_quiz_app/providers/auth_provider.dart';
import 'package:flashcard_quiz_app/providers/deck_provider.dart';
import 'package:flashcard_quiz_app/providers/notification_provider.dart';
import 'package:flashcard_quiz_app/providers/transaction_provider.dart';
import 'package:flashcard_quiz_app/screens/login_screen.dart';
import 'package:flashcard_quiz_app/screens/main_navigation.dart';
import 'package:flashcard_quiz_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// -------------------------------------------------------------------------
// BẮT BUỘC: Hàm xử lý thông báo khi App ở chế độ Background hoặc Terminated
// Phải là hàm top-level (ở ngoài class) và có @pragma('vm:entry-point')
// -------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Nhận thông báo khi TẮT/NGẦM app: ${message.notification?.title}");
}

// Khởi tạo thư viện thông báo local cho Foreground
final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Đăng ký Handler cho Background & Terminated
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Cấu hình hiển thị thông báo local khi app đang mở (Foreground)
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await _localNotificationsPlugin.initialize(initializationSettings);

  // Nạp biến môi trường từ file .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Lỗi nạp file .env: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DeckProvider>(
          create: (_) => DeckProvider(),
          update: (_, auth, deck) {
            deck!.updateToken(auth.token);
            return deck;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (_) => TransactionProvider(),
          update: (_, auth, trans) {
            trans!.updateToken(auth.token);
            return trans;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nihongo Flashcard Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            // Đã đăng nhập -> Cho qua bộ cấu hình thông báo rồi vào MainNavigation
            return const NotificationSetupScreen();
          }
          // Chưa đăng nhập -> Chặn ở màn Login
          return const LoginScreen();
        },
      ),
    );
  }
}

// Lớp Wrapper xử lý riêng các tính năng liên quan đến Firebase Messaging
class NotificationSetupScreen extends StatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  State<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    // 1. Xin quyền thông báo từ người dùng (Quan trọng với iOS và Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Người dùng đã cấp quyền thông báo.');

      // 2. Lấy FCM Token của thiết bị
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token hiện tại: $token');

      if (token != null) {
        await _sendTokenToBackend(token);
      }

      // Lắng nghe nếu FCM Token thay đổi (ví dụ: khi app cập nhật)
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token thay đổi: $newToken');
        await _sendTokenToBackend(newToken);
      });

      // 3. LẮNG NGHE TRẠNG THÁI FOREGROUND (App đang mở)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Nhận thông báo khi app đang MỞ: ${message.notification?.title}');

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
        }
      });

      // 4. LẮNG NGHE TRẠNG THÁI BACKGROUND (Bấm vào thông báo khi app chạy ngầm)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Người dùng bấm vào thông báo từ BACKGROUND: ${message.data}');
        _navigateToScreen(message.data);
      });

      // 5. LẮNG NGHE TRẠNG THÁI TERMINATED (Bấm vào thông báo khi app tắt hoàn toàn)
      RemoteMessage? initialMessage =
      await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print(
            'App được mở từ trạng thái TẮT HOÀN TOÀN: ${initialMessage.data}');
        _navigateToScreen(initialMessage.data);
      }
    } else {
      print('Người dùng từ chối quyền thông báo.');
    }
  }

  // Hàm gửi Token lên Backend của bạn
  Future<void> _sendTokenToBackend(String token) async {
    // Lấy token của AuthProvider nếu backend yêu cầu Bearer Token để chứng thực API
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userToken = authProvider.token;

    print("Đã gửi token $token lên Backend thành công với User Token: $userToken");
  }

  // Hàm điều hướng tùy biến dựa trên dữ liệu 'data' đi kèm thông báo
  void _navigateToScreen(Map<String, dynamic> data) {
    // Ví dụ: if (data['type'] == 'chat') { ... }
  }

  @override
  Widget build(BuildContext context) {
    // Trả trực tiếp về MainNavigation vì bọc Auth ngoài MyApp đã lo phần lọc login rồi
    return const MainNavigation();
  }
}