import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/cow_controller.dart';
import '../../controllers/user_controller.dart'; // for refreshing Profile tab
import '../pages/credit_page.dart';
import '../pages/user_profile.dart';
import 'package:weight_calculator/widgets/bottom_nav_bar.dart';
import 'package:weight_calculator/widgets/drawer.dart';
import 'package:weight_calculator/widgets/upload_option_button.dart';
import '../../../../widgets/camera.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CowController controller = Get.put(CowController());
  int _currentIndex = 0;

  File? _selectedImage;
  //*___________________Init State____________________
  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['tabIndex'] != null) {
      final v = args['tabIndex'];
      _currentIndex = v is int ? v : int.tryParse(v.toString()) ?? 0;
    }
  }

  //*___________________Image Picker____________________
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        controller.cowInfo.value = null; // clear old result
      });
    }
  }

  //*___________________Camera View____________________
  Future<void> _openCameraView() async {
    final capturedImage = await Get.to(() => Camera());
    if (capturedImage != null && capturedImage is File) {
      setState(() {
        _selectedImage = capturedImage;
        controller.cowInfo.value = null; // clear old result
      });
    }
  }

  //*___________________Upload Image____________________
  Future<void> _uploadImage() async {
    if (_selectedImage != null) {
      await controller.uploadImage(_selectedImage!);
      setState(() {
        _selectedImage = null; // Hide preview after upload
      });
    } else {
      Get.snackbar(
        "Error",
        "Please select or capture an image first",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  //*________________ Pull-to-refresh Handler ___________________
  Future<void> _handleRefresh() async {
    if (controller.isLoading.value) return; // don't refresh while measuring
    // optional: clear preview & last result on refresh
    setState(() {
      _selectedImage = null;
      controller.cowInfo.value = null;
    });
    await controller.refreshCredits(); // fetch latest credits from backend
  }

  Widget _buildHomeContent() {
    return Obx(() {
      final cow = controller.cowInfo.value;
      final isLoading = controller.isLoading.value;
      final left = controller.creditsLeft.value; // remaining from server
      final total =
          controller.totalOrDefault; // total from server (fallback 20)

      final low = left <= 3 && left > 0;

      return Stack(
        children: [
          Column(
            children: [
              // Wrap the scrollable with RefreshIndicator
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/apsLogo.ico',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "ArUco মার্কার যুক্ত গবাদি পশুর ছবি আপলোড করুন",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        //* Image Preview or API Image
                        if (_selectedImage != null && cow == null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _selectedImage!,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        else if (cow?.processedImage.isNotEmpty == true)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              base64Decode(cow!.processedImage),
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ),

                        const SizedBox(height: 10),

                        //* Prediction Results
                        if (cow != null) ...[
                          Text(
                            "পরিমাপ করা ওজন: ${cow.weight.toStringAsFixed(2)} kg",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Breed(জাত): ${cow.breed}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // If you want, you can show credits here too using:
                          // if (cow.creditsRemaining != null)
                          //   Text("Credits Remaining: ${cow.creditsRemaining}/$total"),
                        ],

                        const SizedBox(height: 20),

                        if (low)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Only $left credits left (of $total).",
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        //* Buttons: SHOW ONLY when a new image is selected AND no result yet
                        if (_selectedImage != null && cow == null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  if (isLoading) return;
                                  if (_selectedImage == null) {
                                    Get.snackbar(
                                      "Error",
                                      "Please select or capture an image first",
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red[100],
                                    );
                                    return;
                                  }
                                  if (left <= 0) {
                                    // Out of credits → go to Credit tab
                                    Get.offAllNamed(
                                      '/home',
                                      arguments: {'tabIndex': 1},
                                    );
                                    return;
                                  }
                                  await _uploadImage();
                                },
                                icon: const Icon(
                                  Icons.analytics,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Measure Weight",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      left > 0
                                          ? Colors.green[900]
                                          : Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),

              //*_______________ Camera & Gallery row__________________
              Container(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    UploadOptionButton(
                      onPressed: _openCameraView,
                      icon: Icons.camera_alt,
                      label: "Camera",
                      backgroundColor: Colors.green,
                      borderColor: const Color.fromARGB(255, 1, 77, 4),
                      iconColor: Colors.white,
                      captionColor: Colors.green[900]!,
                    ),
                    const SizedBox(width: 56),
                    UploadOptionButton(
                      onPressed: _pickImage,
                      icon: Icons.photo_library,
                      label: "Gallery",
                      backgroundColor: Colors.green,
                      borderColor: const Color.fromARGB(255, 1, 77, 4),
                      iconColor: Colors.white,
                      captionColor: Colors.green[900]!,
                    ),
                  ],
                ),
              ),
            ],
          ),

          //* ___________________ Overlay Loader ___________________
          if (controller.isLoading.value)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Measuring...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_currentIndex) {
      case 0:
        body = _buildHomeContent();
        break;
      case 1:
        body = const CreditPage();
        break;
      case 2:
        body = const UserProfile();
        break;
      default:
        body = _buildHomeContent();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
        title: const Text(
          "আদর্শ প্রাণিসেবা",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          //*------------ Server credits chip (reactive)----------------
          Obx(() {
            final left = controller.creditsLeft.value;
            final total = controller.totalOrDefault;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('Credits: $left/$total'),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
        ],
      ),
      drawer: const AppDrawer(),
      body: body,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabTapped: (index) async {
          setState(() {
            _currentIndex = index;
          });
          // 🔄 Auto-refresh Profile tab on switch
          if (index == 2 && Get.isRegistered<UserController>()) {
            await Get.find<UserController>().fetchUserDetails();
          }
        },
      ),
    );
  }
}
