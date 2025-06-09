import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../controllers/cow_controller.dart';
import 'camera_view.dart';

class CustomButtons extends StatelessWidget {
  final CowController controller = Get.find<CowController>();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      await controller.uploadImage(File(picked.path));
    }
  }

  Future<void> _openCameraView(BuildContext context) async {
    final capturedImage = await Get.to(() => CameraView());
    if (capturedImage != null && capturedImage is File) {
      await controller.uploadImage(capturedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ Keeps it at bottom
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "camera",
                    onPressed: () => _openCameraView(context),
                    backgroundColor: Colors.deepOrange,
                    elevation: 6,
                    child: Icon(Icons.camera_alt, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text("Camera", style: TextStyle(fontSize: 14)),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "gallery",
                    onPressed: () => _pickImage(ImageSource.gallery),
                    backgroundColor: Colors.teal,
                    elevation: 6,
                    child: Icon(Icons.photo, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text("Gallery", style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/howto'),
                    icon: Icon(Icons.menu_book, size: 28, color: Colors.white),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "How To Guide",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 104, 51),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/aruco'),
                    icon: Icon(Icons.qr_code, size: 28, color: Colors.white),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "ArUco Marker",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 1, 104, 51),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
