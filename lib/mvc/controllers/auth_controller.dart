import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:weight_calculator/utils/phone_number_helper.dart';
import 'package:weight_calculator/utils/signup_error_message.dart';
import '../../services/auth_service.dart';
import '../models/user_model.dart';
import 'cow_controller.dart';
import 'package:weight_calculator/utils/errors/error_handler.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';


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
  try {
    final normalized = normalizeBdPhone(phone);
    final result = await _authService.register(
      phone: normalized,
      name: name,
      password: password,
      confirmPassword: confirmPassword,
    );
    // Success path only (errors would have thrown)
    Get.snackbar(
      'Success',
      'Signup successful. Please login to continue.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
    Get.offAllNamed('/login');
  } catch (e, st) {
    ErrorHandler.I.handle(e, stack: st);
  } finally {
    isLoading.value = false;
  }
}


  // ========================== LOGIN ================================
  Future<void> login({required String phone, required String password}) async {
  isLoading.value = true;
  try {
    final result = await _authService.login(
      phone: phone,
      password: password,
    );
    // success only (errors would have thrown)
    final data = result['data'];
    _authService.saveTokens(data['access'], data['refresh']);

    // Load profile for other screens
    await getUserDetails();

    // Seed credits on Home
    if (Get.isRegistered<CowController>()) {
      final cc = Get.find<CowController>();
      final remRaw = data['credits_remaining'] ??
          data['remaining_credits'] ??
          data['credits'] ??
          data['credit'];
      if (remRaw != null) {
        cc.creditsLeft.value =
            remRaw is int ? remRaw : int.tryParse('$remRaw') ?? cc.creditsLeft.value;
      }

      final totRaw = data['credits_total'] ??
          data['total_credits'] ??
          data['free_credits_total'] ??
          data['initial_credits'] ??
          data['credit_limit'] ??
          data['quota'] ??
          data['free_credits_limit'];
      if (totRaw != null) {
        final parsed = totRaw is int ? totRaw : int.tryParse('$totRaw');
        if (parsed != null && parsed > 0) cc.totalCredits.value = parsed;
      }
    }

    Get.offAllNamed('/home');
  } catch (e, st) {
    ErrorHandler.I.handle(e, stack: st);
  } finally {
    isLoading.value = false;
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
