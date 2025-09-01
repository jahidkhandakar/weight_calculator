import 'package:get/get.dart';
import '../../services/payment_service.dart';
import '../models/payment_model.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = PaymentService();

  RxList<PaymentModel> payments = <PaymentModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayments(); // auto fetch when controller is created
  }

  Future<void> fetchPayments() async {
    try {
      isLoading.value = true;
      final result = await _paymentService.getPaymentHistory();

      if (result['success'] && result['data'] is List) {
        final list = (result['data'] as List)
            .map((e) => PaymentModel.fromJson(e))
            .toList();
        payments.assignAll(list);
      } else {
        Get.snackbar("Error", result['message'] ?? "Failed to fetch history");
      }
    } catch (e) {
      Get.snackbar("Exception", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void refreshPayments() => fetchPayments();
}
