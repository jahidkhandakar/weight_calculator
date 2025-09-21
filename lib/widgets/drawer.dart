import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weight_calculator/services/auth_service.dart';
import 'package:weight_calculator/utils/ui/snackbar_service.dart';
import 'package:weight_calculator/utils/errors/app_exception.dart';
import '../mvc/controllers/user_controller.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late final UserController userController;

  @override
  void initState() {
    super.initState();
    // Reuse existing controller if registered; otherwise create it.
    userController =
        Get.isRegistered<UserController>()
            ? Get.find<UserController>()
            : Get.put(UserController());
  }

    final List<String> drawerItems = [
    "About",
    "How to use this App",
    "About ArUco Marker ",
    "How to download ArUco Marker",
    "FAQ",
    "Pricing Policy",
    "OFFER",
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header is reactive and null-safe
          Obx(() {
            final u = userController.user.value;
            final isLoading = userController.isLoading.value;

            return Container(
              height: 180,
              width: double.infinity,
              color: const Color.fromARGB(255, 1, 104, 51),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Color.fromARGB(255, 1, 104, 51),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isLoading ? 'Loading...' : (u?.name ?? 'Guest'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isLoading ? '—' : (u?.username ?? '—'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(
                    drawerItems[0],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 2,
                  ),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/about');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: Text(
                    drawerItems[1],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 2,
                  ),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/howto');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: Text(
                    drawerItems[2],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 2,
                  ),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/aruco');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(
                    drawerItems[3],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 2,
                  ),
                  onTap: () {
                    Get.back(); // close the drawer
                    Get.toNamed('/aruco_pdf');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(
                    drawerItems[4],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 2,
                  ),
                  onTap: () {
                    Get.back(); // close the drawer
                    Get.toNamed('/faq');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text(
                    drawerItems[5],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.black87,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 2,
                  ),
                  onTap: () {
                    Get.back(); // close the drawer
                    Get.toNamed('/pricing');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_offer, color: Colors.green),
                  title: Text(
                    drawerItems[6],
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.green,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 2,
                  ),
                  onTap: () {
                    Get.back();
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Special Offer'),
                            content: const Text(
                              'No offers available at the moment.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'OK',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 1, 119, 5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          //*_______________________LOGOUT_________________________//
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              Get.back();
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Are you sure to log out?'),
                      content: const Text('You will be logged out of the app.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color.fromARGB(255, 1, 119, 5),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              color: Color.fromARGB(255, 1, 119, 5),
                            ),
                          ),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                final authService = AuthService();
                await authService.logout();
                Get.offAllNamed('/login');
                SnackbarService.I.show(
                  AppException(
                    title: "You are logged out from the app!",
                    code: "logout_success",
                    userMessage: "See you again!",
                    severity: ErrorSeverity.info,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
