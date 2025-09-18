import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../main.dart'; // for the global `cameras`

class Camera extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<Camera> {
  CameraController? controller;
  bool isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      controller = CameraController(cameras[0], ResolutionPreset.high);
      await controller!.initialize();
      setState(() {
        isCameraReady = true;
      });
    } catch (e) {
      print("Camera initialization failed: $e");
    }
  }

  Future<void> _captureAndReturnImage() async {
    if (!controller!.value.isInitialized) return;

    try {
      final file = await controller!.takePicture();

      // Optionally move the file to app directory
      final directory = await getApplicationDocumentsDirectory();
      final name = path.basename(file.path);
      final savedPath = path.join(directory.path, name);
      final savedImage = await File(file.path).copy(savedPath);

      Get.back(result: savedImage); // Return the image file to HomeView
    } catch (e) {
      print("Image capture failed: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Capture Cow Photo",
          style: TextStyle(
            color: const Color.fromARGB(255, 1, 119, 5),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isCameraReady
          ? Stack(
              children: [
                CameraPreview(controller!),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _captureAndReturnImage,
                      child: Icon(Icons.camera),
                    ),
                  ),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
