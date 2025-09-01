import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weight_calculator/widgets/primary_button.dart';
import '../../controllers/user_controller.dart';
import 'package:weight_calculator/widgets/custom_card.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.put(UserController());

    Future<void> _handleRefresh() async {
      if (userController.isLoading.value) return;
      await userController.fetchUserDetails();
      // Optional toast:
      // Get.snackbar('Updated', 'Profile refreshed', snackPosition: SnackPosition.BOTTOM);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (userController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = userController.user.value;

        // Wrap everything in RefreshIndicator so pull-to-refresh works in all states
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: user == null
              ? ListView(
                  // A trivial scrollable so pull-to-refresh works even with little content
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('No user data available')),
                    SizedBox(height: 400), // give some space to allow pull
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color.fromARGB(255, 1, 152, 21),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 9),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[200],
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color.fromARGB(255, 1, 104, 51),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    user.username,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  PrimaryButton(
                                    text: "Change Password",
                                    route: "/change_pass",
                                  ),
                                  const SizedBox(height: 40),
                                  CustomCard(
                                    credits_used: user.creditsUsed,
                                    credits_remaining: user.creditsRemaining,
                                  ),
                                  const SizedBox(height: 60),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      }),
    );
  }
}
