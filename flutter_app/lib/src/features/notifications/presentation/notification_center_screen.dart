import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/platform/permission_service.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
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
  var _tab = _NotificationTab.all;
  final _permissions = PermissionService();

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final repo = NotificationCenterRepository(db);
          return FutureBuilder<List<LocalNotificationItem>>(
            key: ValueKey(_reload),
            future: repo.listNotifications(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              final unread = items.where((item) => !item.read).toList();
              final high = items.where(_isHighPriority).toList();
              final visible = switch (_tab) {
                _NotificationTab.all => items,
                _NotificationTab.unread => unread,
                _NotificationTab.high => high,
              };
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  const _PageHeader(),
                  const SizedBox(height: 16),
                  _UnreadSummaryCard(
                    unreadCount: unread.length,
                    urgentCount: high.where((item) => !item.read).length,
                  ),
                  const SizedBox(height: 12),
                  _NotificationPermissionCard(
                    permissionStatus:
                        widget.permissionStatus?.call() ??
                        _permissions.notificationStatus(),
                    onOpenSettings:
                        widget.openSettings ?? _permissions.openSystemSettings,
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _BulkActions(
                      onMarkAllRead: unread.isEmpty
                          ? null
                          : () async {
                              await repo.markAllRead();
                              if (mounted) setState(() => _reload++);
                            },
                      onDeleteAll: () async {
                        await repo.deleteAll();
                        if (mounted) setState(() => _reload++);
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _NotificationTabs(
                    selected: _tab,
                    allCount: items.length,
                    unreadCount: unread.length,
                    highCount: high.length,
                    onSelected: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    const _EmptyNotificationsCard()
                  else
                    ...visible.map(
                      (item) => _NotificationCard(
                        item: item,
                        onMarkRead: item.read
                            ? null
                            : () async {
                                await repo.markRead(item.id);
                                if (mounted) setState(() => _reload++);
                              },
                        onDelete: () async {
                          await repo.deleteNotification(item.id);
                          if (mounted) setState(() => _reload++);
                        },
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

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benachrichtigungen',
          style: TextStyle(
            color: GpColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Alle lokalen Mitteilungen und Erinnerungszustände',
          style: TextStyle(color: GpColors.textSecondary),
        ),
      ],
    );
  }
}

class _UnreadSummaryCard extends StatelessWidget {
  const _UnreadSummaryCard({
    required this.unreadCount,
    required this.urgentCount,
  });

  final int unreadCount;
  final int urgentCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: GpColors.redGradient),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ungelesene Benachrichtigungen',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (urgentCount > 0)
                    Text(
                      '$urgentCount dringende',
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
            const Icon(Icons.notifications, color: Colors.white70, size: 64),
          ],
        ),
      ),
    );
  }
}

class _BulkActions extends StatelessWidget {
  const _BulkActions({required this.onMarkAllRead, required this.onDeleteAll});

  final VoidCallback? onMarkAllRead;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onMarkAllRead,
            icon: const Icon(Icons.done_all),
            label: const Text('Alle als gelesen'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDeleteAll,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Alle löschen'),
          ),
        ),
      ],
    );
  }
}

class _NotificationTabs extends StatelessWidget {
  const _NotificationTabs({
    required this.selected,
    required this.allCount,
    required this.unreadCount,
    required this.highCount,
    required this.onSelected,
  });

  final _NotificationTab selected;
  final int allCount;
  final int unreadCount;
  final int highCount;
  final ValueChanged<_NotificationTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_NotificationTab>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: _NotificationTab.all,
          label: Text('Alle ($allCount)'),
        ),
        ButtonSegment(
          value: _NotificationTab.unread,
          label: Text('Ungelesen ($unreadCount)'),
        ),
        ButtonSegment(
          value: _NotificationTab.high,
          label: Text('Wichtig ($highCount)'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => onSelected(value.single),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onMarkRead,
    required this.onDelete,
  });

  final LocalNotificationItem item;
  final VoidCallback? onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(item);
    return Card(
      color: item.read ? Colors.white : const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _isHighPriority(item)
              ? GpColors.emergencyRed
              : item.read
              ? GpColors.border
              : const Color(0xFF93C5FD),
          width: _isHighPriority(item) ? 2 : 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.8), color],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_categoryIcon(item.category), color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (!item.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.displayBody),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _PriorityChip(high: _isHighPriority(item)),
                      _NotificationStatusChip(status: item.status),
                      Text(
                        _relativeTime(item.createdAt),
                        style: const TextStyle(
                          color: GpColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (item.statusDetail != null &&
                          item.statusDetail!.isNotEmpty)
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
              ),
            ),
            const SizedBox(width: 4),
            Column(
              children: [
                if (onMarkRead != null)
                  IconButton(
                    tooltip: 'Als gelesen markieren',
                    onPressed: onMarkRead,
                    icon: const Icon(Icons.check, color: Color(0xFF16A34A)),
                  ),
                IconButton(
                  tooltip: 'Löschen',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: GpColors.emergencyRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.high});

  final bool high;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: high ? GpColors.redSurface : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        high ? 'Wichtig' : 'Info',
        style: TextStyle(
          color: high ? GpColors.emergencyRed : GpColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
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

class _EmptyNotificationsCard extends StatelessWidget {
  const _EmptyNotificationsCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: Text('Keine Benachrichtigungen')),
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

enum _NotificationTab { all, unread, high }

bool _isHighPriority(LocalNotificationItem item) {
  return item.category == 'warning' ||
      item.category == 'medication_shortage' ||
      item.status == LocalNotificationStatus.systemBlocked;
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'appointment_confirmation' => Icons.calendar_month_outlined,
    'appointment_reminder' => Icons.schedule,
    'appointment_change' => Icons.warning_amber_outlined,
    'appointment_cancellation' => Icons.close,
    'medication_refill' => Icons.medication_outlined,
    'medication_shortage' => Icons.warning_amber_outlined,
    'vaccination_reminder' => Icons.vaccines_outlined,
    'warning' => Icons.warning_amber_outlined,
    _ => Icons.info_outline,
  };
}

Color _categoryColor(LocalNotificationItem item) {
  return switch (item.category) {
    'appointment_confirmation' => const Color(0xFF16A34A),
    'appointment_reminder' => const Color(0xFF2563EB),
    'appointment_change' => const Color(0xFFF97316),
    'appointment_cancellation' => GpColors.emergencyRed,
    'medication_refill' => const Color(0xFFF97316),
    'medication_shortage' => GpColors.emergencyRed,
    'vaccination_reminder' => const Color(0xFF7C3AED),
    'warning' => const Color(0xFFEAB308),
    _ => const Color(0xFF4F46E5),
  };
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'gerade eben';
  if (diff.inHours < 1) return 'vor ${diff.inMinutes} Min.';
  if (diff.inDays < 1) return 'vor ${diff.inHours} Std.';
  return 'vor ${diff.inDays} Tag${diff.inDays == 1 ? '' : 'en'}';
}
