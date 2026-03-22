import 'package:flutter/material.dart';
import '../../shared/utils/date_helpers.dart';

class AttendanceTile extends StatelessWidget {
  final String employeeName;
  final String? designation;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status; // present | absent | late

  const AttendanceTile({
    super.key,
    required this.employeeName,
    this.designation,
    this.checkIn,
    this.checkOut,
    required this.status,
  });

  Color _statusColor() {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.amber.shade700;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'absent':
        return 'Absent';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                if (designation != null)
                  Text(
                    designation!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    color: _statusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (checkIn != null)
                Text(
                  'In: ${DateHelpers.formatTime(checkIn!)}${checkOut != null ? '  Out: ${DateHelpers.formatTime(checkOut!)}' : ''}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
