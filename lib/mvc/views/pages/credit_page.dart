import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weight_calculator/services/payments/pay_with_shurjopay.dart'; // <= SDK version
import 'package:weight_calculator/services/payments/pay_with_googlepay.dart';
import '../../controllers/package_controller.dart';
import '../../models/package_model.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({Key? key}) : super(key: key);

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  final _payWithShurjoPay = payWithShurjoPaySDK; // <- use SDK function
  final _payWithGooglePay = payWithGooglePay;

  late final PackageController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PackageController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.packages.isEmpty) {
          return const Center(child: Text("No packages available at the moment"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.packages.length,
          itemBuilder: (context, index) {
            final pkg = controller.packages[index];
            return _buildPackageCard(pkg);
          },
        );
      }),
    );
  }

  Widget _buildPackageCard(PackageModel pkg) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pkg.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 1, 104, 51),
              ),
            ),
            const SizedBox(height: 8),
            Text("${pkg.credit} Credits", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              "৳${pkg.price}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPaymentOptions(pkg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 104, 51),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentOptions(PackageModel pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.42,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Wrap(
              runSpacing: 12,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                //* ---------------- ShurjoPay (SDK) ----------------
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    leading: SizedBox(
                      width: 42,
                      height: 42,
                      child: Image.asset('assets/icons/shurjopay.png', fit: BoxFit.contain),
                    ),
                    title: const Text(
                      "ShurjoPay",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _payWithShurjoPay(context, pkg);
                    },
                  ),
                ),
                //* ---------------- Google Pay ----------------
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    leading: SizedBox(
                      width: 42,
                      height: 42,
                      child: Image.asset('assets/icons/google.png', fit: BoxFit.contain),
                    ),
                    title: const Text(
                      "Google Pay",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _payWithGooglePay(context, pkg);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
