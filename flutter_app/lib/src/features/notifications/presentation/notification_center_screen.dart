import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../data/notification_center_repository.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Benachrichtigungen')),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = NotificationCenterRepository(db);
          return FutureBuilder<List<LocalNotificationItem>>(
            key: ValueKey(_reload),
            future: repo.listNotifications(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text('Keine lokalen Benachrichtigungen'),
                        ),
                      ),
                    )
                  else
                    ...items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Icon(
                            item.read
                                ? Icons.notifications_none
                                : Icons.notifications_active_outlined,
                            color: item.read
                                ? GpColors.textSecondary
                                : GpColors.emergencyRed,
                          ),
                          title: Text(item.title),
                          subtitle: Text('${item.category} • ${item.body}'),
                          trailing: item.read
                              ? null
                              : IconButton(
                                  tooltip: 'Als gelesen markieren',
                                  icon: const Icon(Icons.done),
                                  onPressed: () async {
                                    await repo.markRead(item.id);
                                    if (mounted) setState(() => _reload++);
                                  },
                                ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
