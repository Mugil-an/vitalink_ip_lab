import 'package:flutter/material.dart';

/// A reusable section header widget with optional action button.
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? action;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.action,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF6366F1)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
