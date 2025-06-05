import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/cow_controller.dart';
import 'camera_view.dart';

class HomeView extends StatelessWidget {
  final CowController controller = Get.put(CowController());

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
        title: Text(
          "Cattle Weight Calculator",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'about') {
                Get.toNamed('/about');
              } else if (value == 'howto') {
                Get.toNamed('/howto');
              } else if (value == 'aruco') {
                Get.toNamed('/aruco');
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(value: 'about', child: Text('About')),
                  PopupMenuItem(value: 'howto', child: Text('How To Guide')),
                  PopupMenuItem(value: 'aruco', child: Text('ArUco Marker')),
                ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.cowInfo.value == null) {
          return Center(
            child: Text(
              "Provide a cattle image with the ArUco Marker",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                color: const Color.fromARGB(255, 1, 104, 51),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // <-- Add this line
                    children: [
                      SizedBox(height: 32),
                      Text(
                        "Weight: ${controller.cowInfo.value!.weight.toStringAsFixed(3)} kg",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Breed: ${controller.cowInfo.value!.breed}",
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      child: Icon(
                        Icons.camera_alt,
                        size: 30,
                        color: Colors.white,
                      ),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed(
                          '/howto',
                        ); // Use Get.toNamed instead of Get.offAllNamed
                      },
                      icon: Icon(
                        Icons.menu_book,
                        size: 28,
                        color: Colors.white,
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          "How To Guide",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.toNamed('/aruco');
                      },
                      icon: Icon(Icons.qr_code, size: 28, color: Colors.white),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          "ArUco Marker",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
