import 'package:in_app_purchase/in_app_purchase.dart';

class GooglePayService {
  final InAppPurchase _iap = InAppPurchase.instance;

  Future<String?> purchasePackage(String productId) async {
    final bool available = await _iap.isAvailable();
    if (!available) return null;

    const Set<String> ids = {'basic_package'}; // Add product ids from Play Console
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids);

    if (response.notFoundIDs.isNotEmpty) return null;
    final product = response.productDetails.first;

    final purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyConsumable(purchaseParam: purchaseParam);

    final purchase = await _iap.purchaseStream.firstWhere((purchases) => purchases.isNotEmpty);
    final purchaseDetails = purchase.first;

    if (purchaseDetails.status == PurchaseStatus.purchased) {
      return purchaseDetails.verificationData.serverVerificationData;
    }
    return null;
  }
}
