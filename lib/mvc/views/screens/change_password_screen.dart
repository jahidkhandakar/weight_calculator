import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weight_calculator/services/auth_service.dart';
import 'package:weight_calculator/widgets/primary_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = AuthService();

  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _submitting = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final res = await _auth.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text, // <-- add this
      );

      if (res['success'] == true) {
        Get.snackbar(
          'Success',
          'Password changed successfully.',
          snackPosition: SnackPosition.BOTTOM, // or TOP
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green[600],
          colorText: Colors.white,
        );
        await Future.delayed(const Duration(seconds: 2)); // let user see it
        if (!mounted) return;
        Get.offAllNamed('/home');
      } else {
        Get.snackbar(
          'Failed',
          res['message']?.toString() ?? 'Could not change password',
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeGreen,
                  ),
                ),
                const SizedBox(height: 32),

                //* Old password
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: !_showOld,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_clock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showOld ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _showOld = !_showOld),
                    ),
                  ),
                  validator:
                      (value) =>
                          (value == null || value.isEmpty)
                              ? 'Enter your current password'
                              : null,
                ),
                const SizedBox(height: 16),

                //* New password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_showNew,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _showNew = !_showNew),
                    ),
                  ),
                  validator: (value) {
                    final x = value ?? '';
                    if (x.isEmpty) return 'Enter a new password';
                    if (x.length < 6) return 'At least 6 characters';
                    if (x == _oldPasswordController.text) {
                      return 'New password must be different from current';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                //* Confirm new password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirm,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirm ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed:
                          () => setState(() => _showConfirm = !_showConfirm),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Confirm your password';
                    if (value != _newPasswordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _changePassword,
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
                              'Change Password',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
                SizedBox(height: 26),
                //*_____________GET BACK TO PROFILE_____________*
                PrimaryButton(
                  text: 'Back to Profile',
                  route: '/home',
                  tabIndex: 2,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
