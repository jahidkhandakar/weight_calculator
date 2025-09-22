import 'package:get/get.dart';
import 'package:weight_calculator/mvc/models/payment_history_model.dart';
import 'package:weight_calculator/services/auth_service.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';
import 'package:weight_calculator/utils/errors/error_handler.dart';

class PaymentHistoryController extends GetxController {
  final AuthService _auth = AuthService();

  final payments = <PaymentHistoryModel>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPaymentHistory();
  }

  Future<void> fetchPaymentHistory() async {
    try {
      isLoading.value = true;
      error.value = '';

      final res = await _auth.getPaymentHistory();

      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((e) => PaymentHistoryModel.fromJson(e))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first
        payments.assignAll(list);
      } else {
        error.value = res['message'] ?? 'Unexpected response format';
      }
    } catch (e) {
      // Redirect to login on expired auth (401)
      if (e is AppException &&
          (e.code == 'AUTH_EXPIRED' || e.httpStatus == 401)) {
        ErrorHandler.I.onAuthExpired?.call(silent: true);
        return;
      }
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
