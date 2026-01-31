import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class PatientProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry? padding;

  const PatientProfileSection({
    super.key,
    required this.title,
    required this.children,
    this.titleStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ).card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class PatientProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const PatientProfileDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return <Widget>[
      Text(
        label,
        style: labelStyle ??
            TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
      ),
      Text(
        value,
        textAlign: TextAlign.end,
        style: valueStyle ??
            const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
      ).expanded(),
    ].toRow(mainAxisAlignment: MainAxisAlignment.spaceBetween).padding(bottom: 12);
  }
}
