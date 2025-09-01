import 'package:flutter/material.dart';

class UploadOptionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color captionColor;

  const UploadOptionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.captionColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            side: BorderSide(
              color: borderColor,
              width: 1.2,
            ),
          ),
          child: Icon(icon, size: 32, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: captionColor,
          ),
        ),
      ],
    );
  }
}
