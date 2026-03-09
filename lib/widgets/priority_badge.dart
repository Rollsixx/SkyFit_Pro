import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  Color get _color => switch (priority) {
        'High'   => Constants.prioHigh,
        'Medium' => Constants.prioMedium,
        _        => Constants.prioLow,
      };

  IconData get _icon => switch (priority) {
        'High'   => Icons.keyboard_double_arrow_up_rounded,
        'Medium' => Icons.remove_rounded,
        _        => Icons.keyboard_double_arrow_down_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 3),
          Text(
            priority,
            style: TextStyle(
              color:      _color,
              fontSize:   11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}