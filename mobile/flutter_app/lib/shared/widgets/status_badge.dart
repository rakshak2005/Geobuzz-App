import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.active() {
    return const StatusBadge(
      label: 'ACTIVE',
      color: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  factory StatusBadge.inactive() {
    return const StatusBadge(
      label: 'PAUSED',
      color: AppColors.textMutedDark,
      icon: Icons.pause_circle_rounded,
    );
  }

  factory StatusBadge.trigger(String trigger) {
    return StatusBadge(
      label: trigger,
      color: AppColors.primary,
      icon: Icons.track_changes_rounded,
    );
  }

  factory StatusBadge.action(String action) {
    return StatusBadge(
      label: action,
      color: AppColors.secondary,
      icon: Icons.bolt_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppDimensions.roundedFull,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
