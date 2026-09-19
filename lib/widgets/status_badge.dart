import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  Color get _bg {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'OPEN':
      case 'COMPLETED':
      case 'SUCCESS':
      case 'GENERATED':
      case 'APPROVED':
        return const Color(0xFFDCFCE7);
      case 'PENDING':
      case 'FOLLOWUP':
      case 'IN_PROGRESS':
      case 'ONGOING':
        return const Color(0xFFFEF9C3);
      case 'INACTIVE':
      case 'CLOSED':
      case 'FAILED':
      case 'NOT_INTERESTED':
      case 'REJECTED':
      case 'CANCELLED':
        return const Color(0xFFFEE2E2);
      case 'INTERESTED':
      case 'NEW':
        return const Color(0xFFDBEAFE);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _fg {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'OPEN':
      case 'COMPLETED':
      case 'SUCCESS':
      case 'GENERATED':
      case 'APPROVED':
        return const Color(0xFF15803D);
      case 'PENDING':
      case 'FOLLOWUP':
      case 'IN_PROGRESS':
      case 'ONGOING':
        return const Color(0xFFB45309);
      case 'INACTIVE':
      case 'CLOSED':
      case 'FAILED':
      case 'NOT_INTERESTED':
      case 'REJECTED':
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      case 'INTERESTED':
      case 'NEW':
        return const Color(0xFF1D4ED8);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: _fg,
        ),
      ),
    );
  }
}
