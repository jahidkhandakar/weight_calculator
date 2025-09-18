import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/cow_model.dart';
import '../../services/prediction_service.dart';
import '../../services/auth_service.dart';
import 'package:weight_calculator/utils/errors/error_handler.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';


class CowController extends GetxController {
  // Services
  final PredictionService _predictionService = PredictionService();
  final AuthService _authService = AuthService();
  final GetStorage storage = GetStorage();

  // State
  final isLoading = false.obs;
  final cowInfo = Rxn<CowModel>();

  // Credits (server-driven)
  static const int kDefaultFreeCredits =
      20; // fallback if backend doesn't send total
  final creditsLeft = 0.obs; // remaining
  final totalCredits =
      kDefaultFreeCredits.obs; // total (try to get from backend)

  // Convenience getter for UI
  int get totalOrDefault =>
      totalCredits.value > 0 ? totalCredits.value : kDefaultFreeCredits;

  @override
  void onInit() {
    super.onInit();
    refreshCredits(); // fetch credits (remaining + total) from backend
  }

  /// Public: fetch credits from backend and update [creditsLeft] & [totalCredits]
  Future<void> refreshCredits() async {
    try {
      final res = await _authService.getUserDetails(); // GET /userDetails
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;

        // ---- Remaining credits ----
        final rawRemaining =
            data['credits_remaining'] ??
            data['remaining_credits'] ??
            data['remaining'] ??
            data['credits'] ??
            data['credit'];
        if (rawRemaining != null) {
          creditsLeft.value =
              (rawRemaining is int)
                  ? rawRemaining
                  : int.tryParse('$rawRemaining') ?? creditsLeft.value;
        }

        // ---- Total credits (try multiple common keys) ----
        final rawTotal =
            data['credits_total'] ??
            data['total_credits'] ??
            data['free_credits_total'] ??
            data['initial_credits'] ??
            data['initial_free_credits'] ??
            data['credit_limit'] ??
            data['quota'] ??
            data['free_credits_limit'];
        final parsedTotal =
            rawTotal == null
                ? null
                : (rawTotal is int ? rawTotal : int.tryParse('$rawTotal'));

        if (parsedTotal != null && parsedTotal > 0) {
          totalCredits.value = parsedTotal;
        } else if (totalCredits.value <= 0) {
          // ensure sane fallback if backend didn't provide a total
          totalCredits.value = kDefaultFreeCredits;
        }
      }
    } catch (_) {
      // ignore; keep last known values
    }
  }

  void _showBuyDialog() {
    Get.defaultDialog(
      title: 'No credits left',
      middleText: 'You have 0 credits. Please buy a package to continue.',
      textConfirm: 'Buy credits',
      textCancel: 'Later',
      onConfirm: () {
        Get.back();
        Get.offAllNamed('/home', arguments: {'tabIndex': 1}); // Credit tab
      },
    );
  }

  /// Call this from UI
  Future<void> uploadImage(File image) async {
  if (creditsLeft.value <= 0) {
    _showBuyDialog();
    return;
  }

  isLoading.value = true;
  cowInfo.value = null;
  try {
    final token = await _authService.getValidAccessToken();
    if (token == null) throw AppException.authExpired();

    final result = await _predictionService.predict(image, token);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;

      // Parse prediction to your model
      cowInfo.value = CowModel.fromMap(data);

      // Update credits if present
      final fromRemaining = data['credits_remaining'] ??
          data['remaining_credits'] ??
          data['credits'] ??
          data['credit'];
      if (fromRemaining != null) {
        final pr = (fromRemaining is int) ? fromRemaining : int.tryParse('$fromRemaining');
        if (pr != null) creditsLeft.value = pr;
      }

      final fromTotal = data['credits_total'] ??
          data['total_credits'] ??
          data['free_credits_total'] ??
          data['initial_credits'] ??
          data['initial_free_credits'] ??
          data['credit_limit'] ??
          data['quota'] ??
          data['free_credits_limit'];
      if (fromTotal != null) {
        final pt = (fromTotal is int) ? fromTotal : int.tryParse('$fromTotal');
        if (pt != null && pt > 0) totalCredits.value = pt;
      }

      if (fromRemaining == null && fromTotal == null) {
        await refreshCredits();
      }
    }
  } catch (e, st) {
    ErrorHandler.I.handle(e, stack: st);
  } finally {
    isLoading.value = false;
  }
}

}
