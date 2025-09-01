import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../../widgets/primary_button.dart';

class SignupScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthController authController = Get.put(AuthController());

  SignupScreen({super.key});

  void _signup() {
    if (_formKey.currentState!.validate()) {
      authController.register(
        phone: _phoneController.text,
        name: _nameController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adarsha Pranisheba',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
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
                const Text('Create Account',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 1, 104, 51))),
                const SizedBox(height: 32),
                // --- Phone ---
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Enter phone' : null,
                ),
                const SizedBox(height: 16),
                // --- Name ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                // --- Password ---
                Obx(() => TextFormField(
                      controller: _passwordController,
                      obscureText: authController.isLoading.value,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'Min 6 characters'
                          : null,
                    )),
                const SizedBox(height: 16),
                // --- Confirm Password ---
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => (value != _passwordController.text)
                      ? 'Passwords don\'t match'
                      : null,
                ),
                const SizedBox(height: 32),
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authController.isLoading.value ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 1, 104, 51),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: authController.isLoading.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Sign Up',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                      ),
                    )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    PrimaryButton(text: "Login", route: '/login')
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
