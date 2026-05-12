import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_radius.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.fontSize,
  });

  factory StatusBadge.pending() {
    return const StatusBadge(
      label: 'En attente',
      color: Color(0xFFFFF3E0),
      textColor: Color(0xFFFF9800),
    );
  }

  factory StatusBadge.confirmed() {
    return const StatusBadge(
      label: 'Confirmé',
      color: Color(0xFFE8F5E9),
      textColor: Color(0xFF4CAF50),
    );
  }

  factory StatusBadge.cancelled() {
    return const StatusBadge(
      label: 'Annulé',
      color: Color(0xFFFFEBEE),
      textColor: Color(0xFFF44336),
    );
  }

  factory StatusBadge.completed() {
    return const StatusBadge(
      label: 'Terminé',
      color: Color(0xFFE3F2FD),
      textColor: Color(0xFF2196F3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.chipRadius,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.primary,
        ),
      ),
    );
  }
}