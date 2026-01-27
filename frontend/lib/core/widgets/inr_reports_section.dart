import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget for displaying INR history/reports.
class InrReportsSection extends StatelessWidget {
  final List<dynamic> reports;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;

  const InrReportsSection({
    super.key,
    required this.reports,
    this.isLoading = false,
    this.error,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return _ErrorState(message: error!, onRetry: onRefresh);
    }

    if (reports.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: reports.map((report) {
        return _InrReportCard(report: report);
      }).toList(),
    );
  }
}

class _InrReportCard extends StatelessWidget {
  final dynamic report;

  const _InrReportCard({required this.report});

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dt = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inrValue = report['inr_value'];
    final testDate = report['test_date'];
    final isCritical = report['is_critical'] == true;
    final notes = report['notes'];

    // Determine INR status
    final double? inr = inrValue is num ? inrValue.toDouble() : double.tryParse(inrValue?.toString() ?? '');
    final bool isInRange = inr != null && inr >= 2.0 && inr <= 3.0;
    final bool isLow = inr != null && inr < 2.0;
    final bool isHigh = inr != null && inr > 3.0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isCritical) {
      statusColor = const Color(0xFFDC2626);
      statusText = 'Critical';
      statusIcon = Icons.warning_rounded;
    } else if (isInRange) {
      statusColor = const Color(0xFF16A34A);
      statusText = 'In Range';
      statusIcon = Icons.check_circle_rounded;
    } else if (isLow) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Low';
      statusIcon = Icons.arrow_downward_rounded;
    } else if (isHigh) {
      statusColor = const Color(0xFFEA580C);
      statusText = 'High';
      statusIcon = Icons.arrow_upward_rounded;
    } else {
      statusColor = const Color(0xFF6B7280);
      statusText = 'Unknown';
      statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? const Color(0xFFFECACA) : const Color(0xFFE5E7EB),
          width: isCritical ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // INR Value Circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 2),
            ),
            child: Center(
              child: Text(
                inr?.toStringAsFixed(1) ?? '-',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(testDate),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                if (notes != null && notes.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notes.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.science_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          SizedBox(height: 12),
          Text(
            'No INR Reports',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No INR test results have been recorded yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 40,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFDC2626),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
