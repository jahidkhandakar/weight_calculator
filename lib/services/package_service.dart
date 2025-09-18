import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weight_calculator/services/auth_service.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';
import '../utils/api.dart';
import 'package:weight_calculator/utils/errors/error_mapper.dart';

class PackageService {
  final AuthService _auth = AuthService();

  Future<Map<String, dynamic>> getPackages() async {
    try {
      final token = await _auth.getValidAccessToken();
      if (token == null) throw AppException.authExpired();

      final r = await http.get(
        Uri.parse(Api.packages),
        headers: ApiHeaders.authHeaders(token),
      );

      if (r.statusCode >= 200 && r.statusCode < 300) {
        final data = jsonDecode(r.body);
        return {"success": true, "data": data};
      }
      throw ErrorMapper.toAppException(r, statusCode: r.statusCode);
    } catch (e) {
      throw ErrorMapper.toAppException(e);
    }
  }
}
