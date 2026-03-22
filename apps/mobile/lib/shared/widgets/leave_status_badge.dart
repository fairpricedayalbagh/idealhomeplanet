import 'package:flutter/material.dart';

class LeaveStatusBadge extends StatelessWidget {
  final String status;

  const LeaveStatusBadge({super.key, required this.status});

  Color _color() {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _icon() {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle_outline;
      case 'PENDING':
        return Icons.access_time;
      case 'REJECTED':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), color: _color(), size: 14),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _color(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
