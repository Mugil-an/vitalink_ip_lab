import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback onLogout;

  const LogoutDialog({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Close Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Logout')
                  .fontSize(22)
                  .fontWeight(FontWeight.bold)
                  .textColor(const Color(0xFF1F2937)),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Icon
          <Widget>[
            const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 48,
            )
          ]
              .toColumn()
              .padding(all: 20)
              .decorated(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              )
              .padding(bottom: 24),

          const Text('Are you sure you want to logout?')
              .fontSize(16)
              .textColor(const Color(0xFF4B5563))
              .textAlignment(TextAlign.center)
              .padding(bottom: 32),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', 
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.red.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
