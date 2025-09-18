import 'package:get/get.dart';
import '../../services/package_service.dart';
import '../models/package_model.dart';
import 'package:weight_calculator/utils/errors/error_handler.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';


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
  isLoading.value = true;
  try {
    final result = await _packageService.getPackages();
    final list = PackageModel.listFrom(result['data']);

    packages.assignAll(list);
  } catch (e, st) {
    ErrorHandler.I.handle(e, stack: st);
  } finally {
    isLoading.value = false;
  }
}


  void refreshPackages() => fetchPackages();
}
