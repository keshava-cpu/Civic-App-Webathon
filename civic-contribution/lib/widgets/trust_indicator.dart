import 'package:flutter/material.dart';

class TrustIndicator extends StatelessWidget {
  final double trustScore;
  final bool showLabel;

  const TrustIndicator({
    super.key,
    required this.trustScore,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = trustScore >= 0.8
        ? Colors.green
        : trustScore >= 0.5
            ? Colors.orange
            : Colors.red;

    final label = trustScore >= 0.8
        ? 'High Trust'
        : trustScore >= 0.5
            ? 'Medium Trust'
            : 'Low Trust';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield_outlined, size: 14, color: color),
        const SizedBox(width: 2),
        if (showLabel)
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            '${(trustScore * 100).toInt()}%',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
