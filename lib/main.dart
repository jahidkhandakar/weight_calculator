// lib/main.dart
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shurjopay/utilities/functions.dart';
// Controllers / Services
import 'package:weight_calculator/mvc/controllers/auth_controller.dart';
import 'package:weight_calculator/mvc/controllers/payment_history_controller.dart';
import 'package:weight_calculator/mvc/views/pages/image_capture_rule_page.dart';
import 'package:weight_calculator/services/auth_service.dart';
// Pages
import 'package:weight_calculator/mvc/views/pages/aruco_marker_download_page.dart';
import 'package:weight_calculator/mvc/views/pages/faq_page.dart';
import 'package:weight_calculator/mvc/views/pages/payment_history_page.dart';
import 'package:weight_calculator/mvc/views/pages/pricing_policy_page.dart';
import 'package:weight_calculator/mvc/views/pages/user_profile.dart';
import 'package:weight_calculator/mvc/views/pages/aruco_marker.dart';
import 'package:weight_calculator/mvc/views/pages/about_page.dart';
import 'package:weight_calculator/mvc/views/pages/howto_guide.dart';
import 'package:weight_calculator/mvc/views/pages/credit_page.dart';
// Screens
import 'package:weight_calculator/mvc/views/screens/login_screen.dart';
import 'package:weight_calculator/mvc/views/screens/signup_screen.dart';
import 'package:weight_calculator/mvc/views/screens/home_screen.dart';
import 'package:weight_calculator/mvc/views/screens/request_otp_screen.dart';
import 'package:weight_calculator/mvc/views/screens/verify_otp_screen.dart';
import 'package:weight_calculator/mvc/views/screens/change_password_screen.dart';
// Error handling (centralized flow)
import 'package:weight_calculator/utils/errors/error_handler.dart';

late List<CameraDescription> cameras; // Global camera list

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Third-party init
  await initializeShurjopay(environment: "sandbox");
  await GetStorage.init();
  cameras = await availableCameras();

  // Global error hooks
  _setupGlobalErrorHooks();

  // Auth-expired -> snackbar + logout + redirect
  _setupAuthExpiredHandler();

  runApp(const WeightCalculator());
}

void _setupGlobalErrorHooks() {
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler.I.handle(details.exception, stack: details.stack);
  };
  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    ErrorHandler.I.handle(error, stack: stack);
    return true; // mark as handled
  };
}

void _setupAuthExpiredHandler() {
  ErrorHandler.I.onAuthExpired = ({bool silent = true}) async {
    // Clean snackbar without BuildContext
    Get.rawSnackbar(
      title: 'Error',
      message: 'Your session expired, sign in again',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.red.withOpacity(0.95),
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      icon: const Icon(Icons.lock_outline, color: Colors.white),
    );

    // Give it a beat to render before route change
    await Future.delayed(const Duration(milliseconds: 300));

    // Clear tokens
    final box = GetStorage();
    await box.remove('access_token');
    await box.remove('refresh_token');
    await box.remove('user');

    // Navigate to login
    if (Get.currentRoute != '/login') {
      Get.offAllNamed('/login');
    }
  };
}

// Centralized DI
class AppBindings extends Bindings {
  AppBindings();
  @override
  void dependencies() {
    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.lazyPut<PaymentHistoryController>(() => PaymentHistoryController(), fenix: true);
  }
}

class WeightCalculator extends StatelessWidget {
  const WeightCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    final token = GetStorage().read('access_token')?.toString();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weight Calculator',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialBinding: AppBindings(), // <— single place for DI
      home: (token != null && token.isNotEmpty) ? HomeScreen() : LoginScreen(),
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/signup', page: () => SignupScreen()),
        GetPage(name: '/home', page: () => HomeScreen()),
        GetPage(name: '/howto', page: () => HowToGuide()),
        GetPage(name: '/about', page: () => AboutPage()),
        GetPage(name: '/aruco', page: () => ArucoMarker()),
        GetPage(name: '/profile', page: () => UserProfile()),
        GetPage(name: '/credits', page: () => CreditPage()),
        GetPage(name: '/request_otp', page: () => RequestOtpScreen()),
        GetPage(name: '/verify_otp', page: () => VerifyOtpScreen()),
        GetPage(name: '/change_pass', page: () => ChangePasswordScreen()),
        GetPage(name: '/aruco_pdf', page: () => ArucoMarkerDownloadPage()),
        GetPage(name: '/faq', page: () => FaqPage()),
        GetPage(name: '/pricing', page: () => PricingPolicyPage()),
        GetPage(name: '/history', page: () => PaymentHistoryPage()),
        GetPage(name: '/image_rules', page: () => ImageCaptureRulePage()),
      ],
    );
  }
}
