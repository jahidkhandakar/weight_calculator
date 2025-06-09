import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/cow_controller.dart';
import 'camera_view.dart';
import 'custom_buttons.dart';

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
            child: Column(
              children: [
                Image.asset(
                  'assets/home.jpeg',
                  height: 300,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 20),
                Text(
                  "Provide a cattle image with the ArUco Marker",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    color: const Color.fromARGB(255, 1, 104, 51),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "ArUco মার্কারযুক্ত একটি গরুর ছবি দিন",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: const Color.fromARGB(255, 1, 104, 51),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
                      SizedBox(height: 2),
                      Text(
                        "Weight: ${controller.cowInfo.value!.weight.toStringAsFixed(3)} kg",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Breed: ${controller.cowInfo.value!.breed}",
                        style: TextStyle(fontSize: 30),
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
      //* FloatingActionButton
      floatingActionButton: CustomButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
