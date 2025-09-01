// lib/utils/api.dart

class Api {
  static const String apiKey  = "96a5de47825d0cedc1005c1cee2cc14f0a08c1c6016392447fbd204336f7562b";
  static const String baseUrl = "https://weightappv2.pranisheba.com.bd/api";

  // Auth
  static const String register      = "$baseUrl/auth/register/";
  static const String login         = "$baseUrl/auth/login/";
  static const String refreshToken  = "$baseUrl/auth/refresh/";
  static const String userDetails   = "$baseUrl/auth/user/";
  static const String changePassword= "$baseUrl/auth/change-password/";
  static const String requestOtp    = "$baseUrl/auth/request-otp/";
  static const String verifyOtp     = "$baseUrl/auth/verify-otp/";

  // Packages
  static const String packages      = "$baseUrl/packages/";

  // Payment
  static const String initiatePayment = "$baseUrl/payment/initiate/";
  static const String paymentVerify   = "$baseUrl/payment/verify/";
  static const String paymentFailed   = "$baseUrl/payment/failed/";
  static const String paymentCancel   = "$baseUrl/payment/cancel/";
  static const String paymentHistory  = "$baseUrl/payment/history/";

  // Prediction
  static const String predict      = "$baseUrl/predict/";
}

//*______________________API Headers________________________
class ApiHeaders {
  // Public (no Authorization)
  static Map<String, String> publicHeaders = {
    "Content-Type": "application/json",
    "X-API-Key": Api.apiKey,
  };

  // Auth: only add Authorization when token is non-empty
  static Map<String, String> authHeaders(String? token) {
    final h = <String, String>{
      "Content-Type": "application/json",
      "X-API-Key": Api.apiKey,
    };
    if (token != null && token.trim().isNotEmpty) {
      h["Authorization"] = "Bearer $token";
    }
    return h;
  }
}
