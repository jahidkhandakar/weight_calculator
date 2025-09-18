import 'package:flutter/material.dart';
import 'package:weight_calculator/services/google_pay_service.dart';
import 'package:weight_calculator/services/payment_service.dart';
import '../../mvc/models/package_model.dart';
import 'package:weight_calculator/utils/ui/snackbar_service.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';

Future<void> payWithGooglePay(BuildContext context, PackageModel pkg) async {
  final GooglePayService _googlePlayService = GooglePayService();
  final PaymentService _paymentService = PaymentService();

  final token = await _googlePlayService.purchasePackage("basic_package");
  if (token == null) {
    SnackbarService.I.show(
      AppException(
        title: "Service not available",
        code: "purchase_failed",
        userMessage: "Google Pay purchase not completed",
        severity: ErrorSeverity.warning,
      ),
    );
    return;
  }

  final result = await _paymentService.verifyGooglePay(pkg.id, token);
  if (result['success']) {
    SnackbarService.I.show(
      AppException(
        title: "Verifcation Successful",
        code: "googlepay_verified",
        userMessage:
            "Credits updated successfully.\nTransaction ID: ${result['data']['transaction_id']}",
        severity: ErrorSeverity.info,
      ),
    );
  } else {
    SnackbarService.I.show(
      AppException(
        title: "Verification Failed",
        code: "verification_failed",
        userMessage: result['message'] ?? "Verification failed",
        severity: ErrorSeverity.critical,
      ),
    );
  }
}
