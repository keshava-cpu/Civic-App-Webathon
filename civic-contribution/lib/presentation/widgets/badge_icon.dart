import 'package:flutter/material.dart' hide Badge;
import 'package:civic_contribution/domain/models/user_profile.dart';

class BadgeIcon extends StatelessWidget {
  final Badge badge;
  final double size;

  const BadgeIcon({super.key, required this.badge, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.label,
      child: Text(badge.emoji, style: TextStyle(fontSize: size)),
    );
  }
}

