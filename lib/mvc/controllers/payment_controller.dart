import 'package:get/get.dart';
import '../../services/payment_service.dart';
import '../models/payment_model.dart';
import 'package:weight_calculator/utils/errors/error_handler.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';


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
  isLoading.value = true;
  try {
    final result = await _paymentService.getPaymentHistory();
    final list = PaymentModel.listFrom(result['data']);
    payments.assignAll(list);
  } catch (e, st) {
    ErrorHandler.I.handle(e, stack: st);
  } finally {
    isLoading.value = false;
  }
}


  void refreshPayments() => fetchPayments();
}
