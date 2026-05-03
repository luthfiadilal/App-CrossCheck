import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = AppColors.white;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        backgroundColor = AppColors.primaryGreen;
        break;
      case 'RE-CHECK':
      case 'RECHECK':
        backgroundColor = Colors.red;
        break;
      case 'PENDING':
      default:
        backgroundColor = AppColors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
