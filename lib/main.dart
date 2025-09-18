import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:camera/camera.dart';
import 'package:shurjopay/utilities/functions.dart';
// Controllers / Services
import 'package:weight_calculator/mvc/controllers/auth_controller.dart';
import 'package:weight_calculator/mvc/views/pages/aruco_marker_download_page.dart';
import 'package:weight_calculator/services/auth_service.dart';
// Screens & Pages
import 'package:weight_calculator/mvc/views/screens/login_screen.dart';
import 'package:weight_calculator/mvc/views/screens/signup_screen.dart';
import 'package:weight_calculator/mvc/views/screens/home_screen.dart';
import 'package:weight_calculator/mvc/views/screens/request_otp_screen.dart';
import 'package:weight_calculator/mvc/views/screens/verify_otp_screen.dart';
import 'package:weight_calculator/mvc/views/screens/change_password_screen.dart';
import 'package:weight_calculator/mvc/views/pages/user_profile.dart';
import 'package:weight_calculator/mvc/views/pages/aruco_marker.dart';
import 'package:weight_calculator/mvc/views/pages/about_page.dart';
import 'package:weight_calculator/mvc/views/pages/howto_guide.dart';
import 'package:weight_calculator/mvc/views/pages/credit_page.dart';
// Error handling (the new centralized flow)
import 'package:weight_calculator/utils/errors/error_handler.dart';

late List<CameraDescription> cameras; // Global camera list

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Third-party init
  await initializeShurjopay(environment: "sandbox");
  await GetStorage.init();
  cameras = await availableCameras();

  // DI
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<AuthController>(AuthController(), permanent: true);

  // Global error -> one professional snackbar
  _setupGlobalErrorHooks();

  // When AUTH_EXPIRED happens anywhere, do a single silent logout + route to /login
  ErrorHandler.I.onAuthExpired = ({bool silent = true}) async {
    final box = GetStorage();
    await box.remove('access_token');
    await box.remove('refresh_token');
    await box.remove('user'); // if you store a user blob
    if (Get.currentRoute != '/login') {
      Get.offAllNamed('/login');
    }
  };

  // Decide initial route: go to /home only if we have a token
  final token = GetStorage().read('access_token')?.toString();
  final initialRoute =
      (token != null && token.isNotEmpty) ? '/home' : '/login';

  runApp(WeightCalculator());
}

void _setupGlobalErrorHooks() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // You can also forward details to Crashlytics/Sentry here.
    ErrorHandler.I.handle(details.exception, stack: details.stack);
  };

  // Handle async & platform errors
  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    ErrorHandler.I.handle(error, stack: stack);
    return true; // mark as handled
  };
}

// lib/main.dart (only the WeightCalculator part)
class WeightCalculator extends StatelessWidget {
 WeightCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    final token = GetStorage().read('access_token')?.toString();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weight Calculator',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Start screen decided here (no initialRoute needed)
      home: (token != null && token.isNotEmpty)
          ? HomeScreen()
          : LoginScreen(),
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
      ],
    );
  }
}

