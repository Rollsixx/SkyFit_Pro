import 'package:flutter/material.dart';
import '../utils/constants.dart';

class StatsBar extends StatelessWidget {
  final int total;
  final int completed;
  final int pending;
  final int overdue;

  const StatsBar({
    super.key,
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          _Stat(label: 'Total',   value: total,     color: Constants.dsTeal),
          _divider(),
          _Stat(label: 'Pending', value: pending,   color: Colors.blueGrey),
          _divider(),
          _Stat(label: 'Done',    value: completed, color: Constants.prioLow),
          _divider(),
          _Stat(label: 'Overdue', value: overdue,   color: Constants.prioHigh),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width:  1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color:  Colors.white12,
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize:   20,
                fontWeight: FontWeight.w800,
                color:      color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
}