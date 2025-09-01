import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weight_calculator/services/google_pay_service.dart';
import 'package:weight_calculator/services/payment_service.dart';
import '../../mvc/models/package_model.dart';

Future<void> payWithGooglePay(BuildContext context, PackageModel pkg) async {
  final GooglePayService _googlePlayService = GooglePayService();
  final PaymentService _paymentService = PaymentService();

  final token = await _googlePlayService.purchasePackage("basic_package");
  if (token == null) {
    Get.snackbar("Purchase Failed", "Google Play purchase not completed");
    return;
  }

  final result = await _paymentService.verifyGooglePay(pkg.id, token);
  if (result['success']) {
    Get.snackbar(
      "Google Play Verified",
      "Credits updated successfully.\nTransaction ID: ${result['data']['transaction_id']}",
    );
  } else {
    Get.snackbar(
      "Verification Failed",
      result['message'],
      backgroundColor: Colors.red[100],
    );
  }
}
