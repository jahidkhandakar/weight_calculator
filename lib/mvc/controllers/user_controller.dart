// controllers/user_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../models/user_model.dart';
import 'cow_controller.dart'; // ⬅️ to sync credits to Home

class UserController extends GetxController {
  final AuthService _authService = AuthService();

  RxBool isLoading = false.obs;
  Rx<UserModel?> user = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchUserDetails(); // Automatically load data when controller is created
  }

  Future<void> fetchUserDetails() async {
    try {
      isLoading.value = true;
      final result = await _authService.getUserDetails();
      if (result['success'] == true) {
        user.value = UserModel.fromJson(result['data']);
        _syncCreditsToHome(); // keep Home chip in sync
      } else {
        Get.snackbar(
          "Error",
          result['message'] ?? 'Failed to load user details',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        'Failed to load user details: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Push profile credits into CowController so Home shows left/total correctly.
  void _syncCreditsToHome() {
    if (!Get.isRegistered<CowController>()) return;
    final cc = Get.find<CowController>();
    final u = user.value;
    if (u == null) return;

    // Assuming your UserModel exposes these as ints:
    //   int creditsRemaining;
    //   int creditsUsed;
    final int remaining = u.creditsRemaining;
    final int used = u.creditsUsed;
    final int total = used + remaining; // total free credits

    cc.creditsLeft.value = remaining;
    if (total > 0) {
      cc.totalCredits.value = total; // Home will show "remaining/total"
    }
  }
}
