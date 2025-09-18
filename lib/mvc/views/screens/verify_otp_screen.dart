import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:weight_calculator/services/auth_service.dart';
import 'package:weight_calculator/utils/phone_number_helper.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  final _auth = AuthService();

  late final String _phone; // passed from RequestOtpScreen
  bool _submitting = false;

  // Resend logic
  static const int _cooldownSeconds = 180; // 3 minutes
  static const int _maxResend = 5;
  int _secondsLeft = _cooldownSeconds;
  int _resendCount = 0;
  Timer? _timer;

  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _phone = (Get.arguments?['phone'] as String?)?.trim() ?? '';
    if (_phone.isEmpty) {
      Get.snackbar('Missing phone', 'Please request OTP again.');
      Future.microtask(() => Get.back());
      return;
    }
    _startCooldown();
  }

  //*__________________________START COOLDOWN____________________________
  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  //*__________________________VALIDATORS____________________________
  String? _otpValidator(String? v) {
    final x = (v ?? '').trim();
    if (x.isEmpty) return 'Enter OTP';
    if (!RegExp(r'^\d{6}$').hasMatch(x)) return 'Enter the 6-digit OTP';
    return null;
  }

  //*__________________________VERIFY OTP____________________________
  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final res = await _auth.verifyOtpAndSetPassword(
        phone: normalizeBdPhone(_phone),
        otp: _otpController.text.trim(),
        newPassword: _passController.text,
        confirmNewPassword: _confirmController.text,
      );

      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;

        // Save tokens if present (your API returns access + refresh)
        final access = data['access'] as String?;
        final refresh = data['refresh'] as String?;
        if (access != null && refresh != null) {
          _auth.saveTokens(access, refresh);
        }

        Get.snackbar('Success', 'OTP verified and password set.');
        // Go straight into the app
        Get.offAllNamed('/home'); // or '/dashboard'
      } else {
        Get.snackbar(
          'Failed',
          res['message']?.toString() ?? 'Verification failed',
          backgroundColor: Colors.red[100],
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red[100]);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  //*__________________________RESEND OTP____________________________
  Future<void> _resendOtp() async {
    if (_secondsLeft > 0 || _resendCount >= _maxResend) return;

    setState(() => _resendCount++);
    try {
      final res = await _auth.requestOtp(normalizeBdPhone(_phone));
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        final maybeOtp = data['otp'];
        Get.snackbar(
          'OTP Sent',
          'A new OTP was sent to $_phone${maybeOtp != null ? " (Test OTP: $maybeOtp)" : ""}',
        );
        _startCooldown();
      } else {
        setState(() => _resendCount--); // rollback attempt on failure
        Get.snackbar(
          'Failed',
          res['message']?.toString() ?? 'Could not resend OTP',
          backgroundColor: Colors.red[100],
        );
      }
    } catch (e) {
      setState(() => _resendCount--);
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red[100]);
    }
  }

  //* -------------------- UI --------------------
  String _cooldownText() {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    const themeGreen = Color.fromARGB(255, 1, 104, 51);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adarsha Pranisheba', style: TextStyle(color: Colors.white)),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Verify OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent to: $_phone',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                //*------------ OTP------------------
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    hintText: '6-digit code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.verified),
                    counterText: '',
                  ),
                  validator: _otpValidator,
                ),
                const SizedBox(height: 16),

                //*------------ New password------------------
                TextFormField(
                  controller: _passController,
                  obscureText: !_showPass,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  validator: (v) {
                    final x = v ?? '';
                    if (x.isEmpty) return 'Enter a new password';
                    if (x.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                //*------------ Confirm password------------------
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_showConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                //*------------ Verify button------------------
                ElevatedButton(
                  onPressed: _submitting ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 12),

                //*------------ Resend area------------------
                if (_resendCount >= _maxResend)
                  const Text(
                    'Maximum resend attempts reached. Please contact support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: (_secondsLeft == 0) ? _resendOtp : null,
                        child: const Text('Resend OTP'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _secondsLeft == 0 ? 'You can resend now' : _cooldownText(),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Text('(${_resendCount}/$_maxResend)',
                          style: const TextStyle(color: Colors.black45)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
