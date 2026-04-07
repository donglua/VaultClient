import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main.dart';

/// A common gradient button used across the application.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final double borderRadius;
  final double iconSize;
  final double fontSize;
  final bool iconAfterLabel;
  final EdgeInsets? padding;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.isLoading = false,
    this.width,
    this.borderRadius = 6,
    this.iconSize = 14,
    this.fontSize = 13,
    this.iconAfterLabel = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.brandPrimary, AppColors.brandPrimaryAlt],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null && !iconAfterLabel) ...[
                          Icon(icon, size: iconSize, color: Colors.white),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (icon != null && iconAfterLabel) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: iconSize, color: Colors.white),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
