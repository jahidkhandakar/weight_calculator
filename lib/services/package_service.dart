import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:weight_calculator/services/auth_service.dart';
import '../utils/api.dart';

class PackageService {
  final GetStorage storage = GetStorage();
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> getPackages() async {
    try {
      //final token = storage.read('access_token');
      final token = await _auth.getValidAccessToken();
      if (token == null) {
        return {"success": false, "message": "No access token found"};
      }

      final response = await http.get(
        Uri.parse(Api.packages),
        headers: ApiHeaders.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "data": data};
      } else {
        return {
          "success": false,
          "message": "Error: ${response.statusCode} ${response.reasonPhrase}",
          "body": response.body,
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
