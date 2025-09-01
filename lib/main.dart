import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:camera/camera.dart';
import 'package:shurjopay/utilities/functions.dart';
import 'package:weight_calculator/mvc/controllers/auth_controller.dart';
import 'package:weight_calculator/mvc/views/pages/user_profile.dart';
import 'package:weight_calculator/mvc/views/screens/change_password_screen.dart';
import 'package:weight_calculator/mvc/views/screens/login_screen.dart';
import 'package:weight_calculator/mvc/views/screens/request_otp_screen.dart';
import 'package:weight_calculator/mvc/views/screens/signup_screen.dart';
import 'package:weight_calculator/mvc/views/screens/home_screen.dart';
import 'package:weight_calculator/mvc/views/screens/verify_otp_screen.dart';
import 'package:weight_calculator/services/auth_service.dart';
import 'mvc/views/pages/aruco_marker.dart';
import 'mvc/views/pages/about_page.dart';
import 'mvc/views/pages/howto_guide.dart';
import 'mvc/views/pages/credit_page.dart';

late List<CameraDescription> cameras; // Global camera list

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeShurjopay(environment: "sandbox");
  await GetStorage.init(); // Initialize GetStorage for session handling
  Get.put(AuthController(), permanent: true);
  cameras = await availableCameras(); // Initialize cameras

  Get.put(AuthService());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final token = box.read('access_token');

    // Auto-login if token exists
    final initialRoute =
        (token != null && token.isNotEmpty) ? '/login' : '/login';

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weight Calculator',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/', page: () => LoginScreen()),
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
      ],
    );
  }
}
