import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:weight_calculator/services/auth_service.dart';
import 'package:weight_calculator/utils/phone_number_helper.dart';

class RequestOtpScreen extends StatefulWidget {
  const RequestOtpScreen({super.key});

  @override
  State<RequestOtpScreen> createState() => _RequestOtpScreenState();
}

class _RequestOtpScreenState extends State<RequestOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _auth = AuthService();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  //*__________________________SUBMIT METHOD____________________________
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final normalizedPhone = normalizeBdPhone(phone);

    setState(() => _submitting = true);

    try {
      // Posts to /auth/request-otp/ with {"phone_number": ...}
      final res = await _auth.requestOtp(normalizedPhone);

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final maybeOtp = data['otp']; // test env only
        Get.snackbar(
          'OTP Sent',
          'Please check your SMS${maybeOtp != null ? " (Test OTP: $maybeOtp)" : ""}',
        );

        // Pass normalized phone to verify screen
        Get.toNamed('/verify_otp', arguments: {'phone': normalizedPhone});
      } else {
        Get.snackbar(
          'Failed',
          res['message']?.toString() ?? 'Could not send OTP',
          backgroundColor: Colors.red[100],
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red[100]);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeGreen = Color.fromARGB(255, 1, 104, 51);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adarsha Pranisheba',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: themeGreen,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Request OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeGreen,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    // Allow digits, +, spaces, dashes if you want to accept +880 formats
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 01XXXXXXXXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) => validateBdPhone(value ?? ''),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _submitting
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
