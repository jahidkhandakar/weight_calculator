import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final String route;
  final int? tabIndex;

  const PrimaryButton({
    super.key, required this.text, required this.route, this.tabIndex
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        if (tabIndex != null) {
          Get.offAllNamed(route, arguments: {'tabIndex': tabIndex});
        } else {
          Get.offAllNamed(route);
        }
      },
        child: Text(
          text,
          style: TextStyle(
            color: const Color.fromARGB(255, 1, 112, 5),
            fontSize: 18,
            fontWeight: FontWeight.bold,  
          ),
       ),
    );
  }
}
