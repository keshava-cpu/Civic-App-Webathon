import 'package:flutter/material.dart';
import '../config/constants.dart';

class StatusChip extends StatelessWidget {
  final IssueStatus status;
  final bool small;

  const StatusChip({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _colorAndIcon(context);
    final size = small ? 10.0 : 12.0;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size + 2, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _colorAndIcon(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (status) {
      case IssueStatus.pending:
        return (Colors.orange, Icons.schedule_outlined);
      case IssueStatus.assigned:
        return (Colors.blue, Icons.assignment_ind_outlined);
      case IssueStatus.inProgress:
        return (Colors.purple, Icons.construction_outlined);
      case IssueStatus.resolved:
        return (cs.primary, Icons.check_circle_outline);
      case IssueStatus.verified:
        return (Colors.green, Icons.verified_outlined);
    }
  }
}
