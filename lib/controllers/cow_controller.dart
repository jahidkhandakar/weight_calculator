import 'dart:io';
import 'package:get/get.dart';
import '../models/cow_info.dart';
import '../services/api_service.dart';

class CowController extends GetxController {
  var isLoading = false.obs;
  var cowInfo = Rxn<CowInfo>();

  Future<void> uploadImage(File image) async {
    try {
      isLoading.value = true;
      cowInfo.value = await ApiService.uploadCowImage(image);
    } catch (e, stack) {
      cowInfo.value = null;
      Get.snackbar('Error', 'Failed to get result from API: $e');
      print('Error uploading image: $e');
      print('Stack trace: $stack');
    } finally {
      isLoading.value = false;
    }
  }
}
