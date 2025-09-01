import 'package:get/get.dart';
import '../../services/package_service.dart';
import '../models/package_model.dart';

class PackageController extends GetxController {
  final PackageService _packageService = PackageService();

  RxList<PackageModel> packages = <PackageModel>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    try {
      isLoading.value = true;
      final result = await _packageService.getPackages();
      
      if (result['success'] && result['data'] is List) {
        final list = (result['data'] as List)
            .map((e) => PackageModel.fromJson(e))
            .toList();
        packages.assignAll(list);
      } else {
        Get.snackbar("Error", result['message'] ?? "Failed to load packages");
      }
    } catch (e) {
      Get.snackbar("Exception", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void refreshPackages() => fetchPackages();
}
