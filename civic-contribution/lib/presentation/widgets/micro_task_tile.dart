import 'package:flutter/material.dart';
import 'package:civic_contribution/domain/models/micro_task.dart';
import 'package:civic_contribution/data/services/credits_service.dart';
import 'package:civic_contribution/data/services/database_service.dart';

class MicroTaskTile extends StatelessWidget {
  final MicroTask task;
  final String currentUserId;
  final DatabaseService firestoreService;
  final CreditsService creditsService;

  const MicroTaskTile({
    super.key,
    required this.task,
    required this.currentUserId,
    required this.firestoreService,
    required this.creditsService,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAssignedToMe = task.assigneeId == currentUserId;

    return ListTile(
      dense: true,
      leading: Checkbox(
        value: task.completed,
        onChanged: task.completed || !isAssignedToMe
            ? null
            : (_) async {
                await firestoreService.completeMicroTask(
                    task.issueId, task.id);
                await creditsService.awardTask(currentUserId);
              },
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.completed ? TextDecoration.lineThrough : null,
          color: task.completed ? cs.outline : null,
        ),
      ),
      subtitle: task.assigneeId != null
          ? Text(
              task.completed
                  ? 'Completed'
                  : isAssignedToMe
                      ? 'Assigned to you'
                      : 'Assigned',
              style: TextStyle(fontSize: 11, color: cs.outline),
            )
          : null,
      trailing: task.assigneeId == null
          ? TextButton(
              onPressed: () async {
                await firestoreService.assignMicroTask(
                    task.issueId, task.id, currentUserId);
              },
              child: const Text('Claim'),
            )
          : null,
    );
  }
}

