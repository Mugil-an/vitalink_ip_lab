import 'package:flutter/material.dart';

/// A reusable card widget for displaying information sections.
class InfoCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final List<Widget>? actions;

  const InfoCard({
    super.key,
    this.title,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || actions != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  if (actions != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                ],
              ),
            ),
          Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A row widget for displaying label-value pairs in an InfoCard.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: labelStyle ??
                  const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  TextStyle(
                    fontSize: 14,
                    color: valueColor ?? const Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
