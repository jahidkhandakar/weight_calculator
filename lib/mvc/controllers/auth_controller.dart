import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../services/auth_service.dart';
import '../models/user_model.dart';
import 'cow_controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final GetStorage storage = GetStorage();

  RxBool isLoading = false.obs;
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // ========================== REGISTER ================================
  Future<void> register({
    required String phone,
    required String name,
    required String password,
    required String confirmPassword,
  }) async {
    isLoading.value = true;
    final result = await _authService.register(
      phone: phone,
      name: name,
      password: password,
      confirmPassword: confirmPassword,
    );
    isLoading.value = false;

    if (result['success'] == true) {
      final data = result['data'];

      // Save identity locally (optional)
      storage.write('user_phone', phone);
      storage.write('user_name', name);
      if (data['id'] != null) storage.write('user_id', data['id']);

      // If backend returns tokens on register, save them
      if (data['access'] != null && data['refresh'] != null) {
        _authService.saveTokens(data['access'], data['refresh']);
      }

      // Seed Home credits if present in response
      if (Get.isRegistered<CowController>()) {
        final cc = Get.find<CowController>();

        final remRaw =
            data['credits_remaining'] ?? data['remaining_credits'] ?? data['credits'] ?? data['credit'];
        if (remRaw != null) {
          cc.creditsLeft.value =
              remRaw is int ? remRaw : int.tryParse('$remRaw') ?? cc.creditsLeft.value;
        }

        final totRaw =
            data['credits_total'] ??
            data['total_credits'] ??
            data['free_credits_total'] ??
            data['initial_credits'] ??
            data['credit_limit'] ??
            data['quota'] ??
            data['free_credits_limit'];
        if (totRaw != null) {
          final parsed = totRaw is int ? totRaw : int.tryParse('$totRaw');
          if (parsed != null && parsed > 0) cc.totalCredits.value = parsed;
        } else {
          await cc.refreshCredits();
        }
      }

      Get.snackbar('Success', 'Signup complete. Welcome, $name!');
      Get.offAllNamed('/home');
    } else {
      Get.snackbar('Error', result['message'] ?? 'Signup failed');
    }
  }

  // ========================== LOGIN ================================
  Future<void> login({required String phone, required String password}) async {
    isLoading.value = true;
    final result = await _authService.login(phone: phone, password: password);
    isLoading.value = false;

    if (result['success']) {
      final data = result['data'];
      _authService.saveTokens(data['access'], data['refresh']);

      // Load profile for other screens
      await getUserDetails();

      // Seed/refresh credits on Home
      if (Get.isRegistered<CowController>()) {
        final cc = Get.find<CowController>();

        final remRaw =
            data['credits_remaining'] ?? data['remaining_credits'] ?? data['credits'] ?? data['credit'];
        if (remRaw != null) {
          cc.creditsLeft.value =
              remRaw is int ? remRaw : int.tryParse('$remRaw') ?? cc.creditsLeft.value;
        }

        final totRaw =
            data['credits_total'] ??
            data['total_credits'] ??
            data['free_credits_total'] ??
            data['initial_credits'] ??
            data['credit_limit'] ??
            data['quota'] ??
            data['free_credits_limit'];
        if (totRaw != null) {
          final parsed = totRaw is int ? totRaw : int.tryParse('$totRaw');
          if (parsed != null && parsed > 0) {
            cc.totalCredits.value = parsed;
          } else {
            await cc.refreshCredits();
          }
        } else {
          await cc.refreshCredits();
        }
      }

      Get.offAllNamed('/home');
    } else {
      Get.snackbar(
        "Login Failed",
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  // ========================== USER DETAILS ================================
  Future<void> getUserDetails() async {
    final result = await _authService.getUserDetails();
    if (result['success']) {
      currentUser.value = UserModel.fromJson(result['data']);
    } else {
      Get.snackbar(
        "Error",
        result['message'],
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  // ============================= LOGOUT ===================================
  void logout() {
    _authService.logout();
    currentUser.value = null;
    Get.offAllNamed('/login');
  }
}
