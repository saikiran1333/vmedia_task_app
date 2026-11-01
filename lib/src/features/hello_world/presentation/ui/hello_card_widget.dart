import 'package:flutter/material.dart';
import '../../domain/entities/hello_entity.dart';

class HelloCardWidget extends StatelessWidget {
  final HelloEntity entity;

  const HelloCardWidget({
    super.key,
    required this.entity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text('ID: ${entity.id}'),
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                const SizedBox(width: 8),
                Text(
                  'User #${entity.userId}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entity.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entity.body,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
