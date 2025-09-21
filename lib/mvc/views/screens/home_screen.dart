import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

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
  int _quarterTurns = 0; // 0,1,2,3 -> 0°,90°,180°,270°

  //* ------------------- compression config -----------------------
  static const int _kTargetBytes = 500 * 1024; // 500 KB
  static const int _kMaxDimension = 1400; // cap width/height on first pass
  static const int _kMinDimension = 640;  // don't go smaller than this unless necessary
  static const List<int> _kQualities = [90, 80, 70, 60, 50, 40, 30];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args['tabIndex'] != null) {
      final v = args['tabIndex'];
      _currentIndex = v is int ? v : int.tryParse(v.toString()) ?? 0;
    }
  }

  //* ---------- Image pick / capture ----------
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _quarterTurns = 0; // reset rotation
        controller.cowInfo.value = null;
      });
    }
  }

  Future<void> _openCameraView() async {
    final capturedImage = await Get.to(() => Camera());
    if (capturedImage != null && capturedImage is File) {
      setState(() {
        _selectedImage = capturedImage;
        _quarterTurns = 0; // reset rotation
        controller.cowInfo.value = null;
      });
    }
  }

  //* ---------- Rotate preview (90° each tap) ----------
  void _rotateOnce() {
    if (_selectedImage == null) return;
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  //* ---------- Prepare rotated + compressed file ----------
  // 1) decode
  // 2) rotate (if _quarterTurns>0)
  // 3) downscale to <= _kMaxDimension
  // 4) encode JPG with decreasing quality until <= _kTargetBytes
  // 5) if still too big, reduce dimensions iteratively (not below _kMinDimension)
  Future<File> _prepareImageForUpload(File original) async {
  try {
    final bytes = await original.readAsBytes();

    // Decode (supports most formats)
    final decoded0 = img.decodeImage(bytes);
    if (decoded0 == null) {
      // If we can't decode, just return the original
      return original;
    }

    // From here use a non-null image variable
    var image = decoded0;

    // Apply rotation
    final turns = _quarterTurns % 4;
    if (turns != 0) {
      image = img.copyRotate(image, angle: (turns * 90).toDouble());
    }

    // Start from a capped size if very large
    image = _resizeIfNeeded(image, _kMaxDimension);

    // Try encoding under target with current dimensions
    Uint8List? out = _encodeUnderSize(
      image,
      targetBytes: _kTargetBytes,
      qualities: _kQualities,
    );

    if (out == null) {
      // If still too big, iteratively scale down and retry
      var currentW = image.width;
      var currentH = image.height;

      while (out == null && (currentW > _kMinDimension || currentH > _kMinDimension)) {
        final nextW = (currentW * 0.85).round();
        final nextH = (currentH * 0.85).round();
        image = img.copyResize(image, width: nextW, height: nextH);
        currentW = image.width;
        currentH = image.height;

        out = _encodeUnderSize(
          image,
          targetBytes: _kTargetBytes,
          qualities: _kQualities,
        );
      }

      // If STILL null, just encode at the lowest quality tried
      out ??= Uint8List.fromList(img.encodeJpg(image, quality: _kQualities.last));
    }

    final tempDir = await getTemporaryDirectory();
    final outPath = p.join(
      tempDir.path,
      'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final outFile = File(outPath);
    await outFile.writeAsBytes(out, flush: true);
    return outFile;
  } catch (_) {
    // If anything fails, just upload original to avoid blocking user
    return original;
  }
}


  img.Image _resizeIfNeeded(img.Image src, int maxDim) {
    final w = src.width;
    final h = src.height;
    if (w <= maxDim && h <= maxDim) return src;
    // keep aspect ratio
    if (w >= h) {
      return img.copyResize(src, width: maxDim);
    } else {
      return img.copyResize(src, height: maxDim);
    }
  }

  Uint8List? _encodeUnderSize(
    img.Image src, {
    required int targetBytes,
    required List<int> qualities,
  }) {
    for (final q in qualities) {
      final data = Uint8List.fromList(img.encodeJpg(src, quality: q));
      if (data.lengthInBytes <= targetBytes) {
        return data;
      }
    }
    return null; // none met the target
  }

  // *---------- Upload flow ----------
  Future<void> _uploadImage() async {
    if (_selectedImage != null) {
      // Rotate + compress before upload
      final prepared = await _prepareImageForUpload(_selectedImage!);
      await controller.uploadImage(prepared);
      setState(() {
        _selectedImage = null; // Hide preview after upload
        _quarterTurns = 0;
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

  //* ---------- Pull-to-refresh ----------
  Future<void> _handleRefresh() async {
    if (controller.isLoading.value) return;
    setState(() {
      _selectedImage = null;
      _quarterTurns = 0;
      controller.cowInfo.value = null;
    });
    await controller.refreshCredits();
  }

  Widget _buildHomeContent() {
    return Obx(() {
      final cow = controller.cowInfo.value;
      final isLoading = controller.isLoading.value;
      final left = controller.creditsLeft.value;
      final total = controller.totalOrDefault;
      final low = left <= 3 && left > 0;

      return Stack(
        children: [
          Column(
            children: [
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

                        // ----- Preview selected image or processed image from API
                        if (_selectedImage != null && cow == null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: RotatedBox(
                              quarterTurns: _quarterTurns,
                              child: Image.file(
                                _selectedImage!,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          //*------- Rotate button row -------*//
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _rotateOnce,
                                icon: const Icon(Icons.rotate_right, size: 20),
                                label: const Text('Rotate'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green[900],
                                ),
                              ),
                            ],
                          ),
                        ] else if (cow?.processedImage.isNotEmpty == true) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              base64Decode(cow!.processedImage),
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],

                        const SizedBox(height: 2),

                        // *----------- Prediction result------------
                        if (cow != null) ...[
                          Text(
                            "পরিমাপ করা ওজন: ${cow.weight.toStringAsFixed(2)} kg",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // const SizedBox(height: 8),
                          // Text(
                          //   "Breed(জাত): ${cow.breed}",
                          //   style: const TextStyle(
                          //     fontSize: 18,
                          //     fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                        ],

                        const SizedBox(height: 8),

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

                        // ----- Actions when a new image is selected and no result yet
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
                                    Get.offAllNamed(
                                      '/home',
                                      arguments: {'tabIndex': 1},
                                    );
                                    return;
                                  }
                                  await _uploadImage();
                                },
                                icon: const Icon(Icons.analytics, color: Colors.white),
                                label: const Text(
                                  "Measure Weight",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: left > 0 ? Colors.green[900] : Colors.grey,
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

              // ----- Camera & Gallery row
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

          // --------- Overlay Loader -----------
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
          if (index == 2 && Get.isRegistered<UserController>()) {
            await Get.find<UserController>().fetchUserDetails();
          }
        },
      ),
    );
  }
}
