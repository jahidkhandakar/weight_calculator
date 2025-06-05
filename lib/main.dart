import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:weight_calculator/pages/aruco_marker.dart';
import 'pages/about.dart';
import 'pages/howto_guide.dart';
import 'views/home_view.dart';

late List<CameraDescription> cameras; // Declare globally

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before async init
  cameras = await availableCameras(); // Initialize cameras
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => HomeView()),
        GetPage(name: '/howto', page: () => HowToGuide()),
        GetPage(name: '/about', page: () => About()),
        GetPage(name: '/aruco', page: () => ArucoMarker()),
      ],
      home: HomeView(),
    );
  }
}
