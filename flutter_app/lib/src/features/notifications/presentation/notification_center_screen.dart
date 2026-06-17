import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/platform/permission_service.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/notification_center_repository.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({
    super.key,
    this.permissionStatus,
    this.openSettings,
  });

  final Future<PermissionStatus> Function()? permissionStatus;
  final Future<bool> Function()? openSettings;

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  int _reload = 0;
  final _permissions = PermissionService();

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
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
                  _NotificationPermissionCard(
                    permissionStatus:
                        widget.permissionStatus?.call() ??
                        _permissions.notificationStatus(),
                    onOpenSettings:
                        widget.openSettings ?? _permissions.openSystemSettings,
                  ),
                  const SizedBox(height: 12),
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
                          subtitle: _NotificationItemSubtitle(item: item),
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

class _NotificationItemSubtitle extends StatelessWidget {
  const _NotificationItemSubtitle({required this.item});

  final LocalNotificationItem item;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item.category} • ${item.displayBody}'),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            _NotificationStatusChip(status: status),
            if (item.statusDetail != null && item.statusDetail!.isNotEmpty)
              Text(
                item.statusDetail!,
                style: const TextStyle(
                  color: GpColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _NotificationStatusChip extends StatelessWidget {
  const _NotificationStatusChip({required this.status});

  final LocalNotificationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      LocalNotificationStatus.active => const Color(0xFF16A34A),
      LocalNotificationStatus.permissionMissing => const Color(0xFFCA8A04),
      LocalNotificationStatus.systemBlocked => GpColors.emergencyRed,
      LocalNotificationStatus.needsReschedule => const Color(0xFF2563EB),
      LocalNotificationStatus.inactive => GpColors.textSecondary,
    };
    final background = switch (status) {
      LocalNotificationStatus.active => const Color(0xFFF0FDF4),
      LocalNotificationStatus.permissionMissing => const Color(0xFFFFFBEB),
      LocalNotificationStatus.systemBlocked => GpColors.redSurface,
      LocalNotificationStatus.needsReschedule => const Color(0xFFEFF6FF),
      LocalNotificationStatus.inactive => const Color(0xFFF9FAFB),
    };
    final icon = switch (status) {
      LocalNotificationStatus.active => Icons.check_circle_outline,
      LocalNotificationStatus.permissionMissing =>
        Icons.notifications_off_outlined,
      LocalNotificationStatus.systemBlocked => Icons.block_outlined,
      LocalNotificationStatus.needsReschedule => Icons.update_outlined,
      LocalNotificationStatus.inactive => Icons.pause_circle_outline,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPermissionCard extends StatelessWidget {
  const _NotificationPermissionCard({
    required this.permissionStatus,
    required this.onOpenSettings,
  });

  final Future<PermissionStatus> permissionStatus;
  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: permissionStatus,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final granted = status?.isGranted ?? false;
        final limited = status?.isLimited ?? false;
        final blocked =
            status?.isPermanentlyDenied == true || status?.isRestricted == true;
        final color = granted || limited
            ? GpColors.green.first
            : blocked
            ? GpColors.emergencyRed
            : GpColors.textSecondary;
        final title = granted || limited
            ? 'System-Benachrichtigungen aktiv'
            : blocked
            ? 'Benachrichtigungen blockiert'
            : 'Benachrichtigungen nicht aktiviert';
        final body = granted || limited
            ? 'Lokale Erinnerungen koennen auf diesem Geraet angezeigt werden.'
            : blocked
            ? 'Oeffnen Sie die Systemeinstellungen, um lokale Erinnerungen wieder zu erlauben.'
            : 'Beim Planen einer Erinnerung fragt die App nach der Berechtigung.';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active_outlined, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(body),
                      if (blocked) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: onOpenSettings,
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Einstellungen oeffnen'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
