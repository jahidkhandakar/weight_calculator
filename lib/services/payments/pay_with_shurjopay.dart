import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ShurjoPay SDK
import 'package:shurjopay/shurjopay.dart';
import 'package:shurjopay/models/config.dart';
import 'package:shurjopay/models/shurjopay_request_model.dart';

import 'package:weight_calculator/mvc/controllers/user_controller.dart';
import 'package:weight_calculator/services/payment_service.dart';
import 'package:weight_calculator/utils/ui/snackbar_service.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';
import '../../mvc/models/package_model.dart';

/// End-to-end ShurjoPay (SDK) payment flow
/// 1) Initiate on backend with package_id -> returns transaction_id, amount, credit
/// 2) Open SDK checkout (orderID must include your prefix)
/// 3) Verify with SDK (spCode "1000" == success)
/// 4) Call backend /api/payment/verify/ with:
///    { order_id: <transaction_id>, status: "success", sp_transaction_id: <from SDK> }
Future<void> payWithShurjoPaySDK(BuildContext context, PackageModel pkg) async {
  // TODO: 🔐 Move to secure storage/env for production
  const String spUsername = 'sp_sandbox'; // live: your real username
  const String spPassword = 'pyyk97hu&6u6'; // live: your real password
  const String spPrefix = 'NOK'; // <= 5 chars

  final paymentService = PaymentService();

  try {
    //* 1) INITIATE on backend
    final initRes = await paymentService.initiateShurjoPay(pkg.id);
    if (initRes['success'] != true) {
      SnackbarService.I.show(
        AppException(
          title: "Initialization Failed",
          code: "init_failed",
          userMessage: initRes['message']?.toString() ?? 'Try again.',
          severity: ErrorSeverity.critical,
        ),
      );
      return;
    }
    final initData = initRes['data'] as Map<String, dynamic>;
    final String transactionId = initData['transaction_id'].toString();
    final double amountFromServer =
        (() {
          final a = initData['amount'];
          if (a is num) return a.toDouble();
          return double.tryParse(a?.toString() ?? '') ??
              double.tryParse(pkg.price) ??
              0.0;
        })();

    //* 2) Build SDK configs
    final configs = await _buildShurjoPayConfigs(
      prefix: spPrefix,
      userName: spUsername,
      password: spPassword,
    );

    // ShurjoPay requires orderID to start with your prefix.
    final String orderIdForGateway = '$spPrefix-$transactionId';

    final req = ShurjopayRequestModel(
      configs: configs,
      currency: 'BDT',
      amount: amountFromServer, // always trust server amount
      orderID: orderIdForGateway,
      discountAmount: 0,
      discountPercentage: 0,
      // TODO: Fill from user profile if available
      customerName: 'WeightCalc User',
      customerPhoneNumber: '01XXXXXXXXX',
      customerAddress: 'Dhaka',
      customerCity: 'Dhaka',
      customerPostcode: '1212',
      returnURL: 'https://www.sandbox.shurjopayment.com/response',
      cancelURL: 'https://www.sandbox.shurjopayment.com/response',
      // Pass-throughs (optional)
      value1: transactionId,
      value2: pkg.name,
      value3: pkg.id.toString(),
      value4: 'wc-app',
    );

    final sp = ShurjoPay();

    // 3) Open SDK checkout
    final payRes = await sp.makePayment(
      context: context,
      shurjopayRequestModel: req,
    );

    if (payRes.status != true || payRes.shurjopayOrderID == null) {
      SnackbarService.I.show(
        AppException(
          title: "Payment Cancelled",
          code: "payment_cancelled",
          userMessage: 'No charge was made.',
          severity: ErrorSeverity.warning,
        ),
      );
      // Optionally: await paymentService.cancelPayment(transactionId);
      return;
    }

    // 4) Verify with SDK
    final verify = await sp.verifyPayment(orderID: payRes.shurjopayOrderID!);

    final bool sdkSuccess = verify.spCode?.toString() == '1000';
    if (!sdkSuccess) {
      SnackbarService.I.show(
        AppException(
          title: "Payment Failed",
          code: "payment_failed",
          userMessage: verify.spMessage ?? 'Payment not completed.',
          severity: ErrorSeverity.critical,
        ),
      );
      // Optionally: await paymentService.markPaymentFailed(transactionId);
      return;
    }

    // ShurjoPay transaction id to send to your backend:
    // - from verification: verify.orderId
    // - fallback to makePayment response: payRes.shurjopayOrderID
    final String spTransactionId =
        (verify.orderId?.trim().isNotEmpty == true)
            ? verify.orderId!.trim()
            : payRes.shurjopayOrderID!.trim();

    // 5) Final verify with YOUR backend (credits get added here)
    final serverVerify = await paymentService.verifyShurjoPay(
      orderId: transactionId, // your UUID from /initiate
      spTransactionId: spTransactionId, // from SDK verify
      status: 'success',
    );

    if (serverVerify['success'] == true) {
      final data = serverVerify['data'] as Map<String, dynamic>;
      final newCredits = data['new_credits_remaining'];
      SnackbarService.I.show(
        AppException(
          title: "Payment Successful",
          code: "payment_successful",
          userMessage: 'Credits added. Balance: $newCredits',
          severity: ErrorSeverity.info,
        ),
      );
      // Refresh profile/credits in UI
      try {
        Get.find<UserController>().fetchUserDetails();
      } catch (_) {}
    } else {
      SnackbarService.I.show(
        AppException(
          title: "Verification Failed",
          code: "verified_not_credited",
          userMessage:
              serverVerify['message']?.toString() ??
              'Please refresh and try again.',
          severity: ErrorSeverity.warning,
        ),
      );
    }
  } catch (e) {
    SnackbarService.I.show(
      AppException(
        title: "Unexpected Error",
        code: "unexpected_error",
        userMessage: e.toString(),
        severity: ErrorSeverity.critical,
      ),
    );
  }
}

/// Build ShurjoPay configs; SDK requires client IP
Future<ShurjopayConfigs> _buildShurjoPayConfigs({
  required String prefix,
  required String userName,
  required String password,
}) async {
  return ShurjopayConfigs(
    prefix: prefix,
    userName: userName,
    password: password,
    clientIP: await _getClientIp(),
  );
}

Future<String> _getClientIp() async {
  try {
    final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final i in ifaces) {
      for (final a in i.addresses) {
        if (!a.isLoopback) return a.address;
      }
    }
  } catch (_) {}
  return '0.0.0.0';
}
