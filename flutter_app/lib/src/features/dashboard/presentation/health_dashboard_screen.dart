import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_database_error.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';

class HealthDashboardScreen extends ConsumerWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => GpDatabaseError(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        data: (db) {
          final data = _HealthDashboardData.fromDatabase(db);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              const Text(
                'Gesundheits-Dashboard',
                style: TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ihr persönlicher Überblick über Ihre Gesundheitsdaten',
                style: TextStyle(color: GpColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 16),
              _HealthScoreCard(data: data),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _DashboardCard(
                    title: 'Medikamente',
                    value: data.activeMedications,
                    trend: data.activeMedications > 0 ? 'aktiv' : 'keine',
                    icon: GpIcons.medication,
                    colors: GpColors.orange,
                    onTap: () => context.go('/medication'),
                  ),
                  _DashboardCard(
                    title: 'Termine',
                    value: data.openAppointments,
                    trend: data.openAppointments > 0 ? 'anstehend' : 'keine',
                    icon: GpIcons.appointments,
                    colors: GpColors.redGradient,
                    onTap: () => context.go('/appointments'),
                  ),
                  _DashboardCard(
                    title: 'Allergien',
                    value: data.allergies,
                    trend: data.criticalAllergies > 0
                        ? '${data.criticalAllergies} kritisch'
                        : 'dokumentiert',
                    icon: GpIcons.allergies,
                    colors: GpColors.yellow,
                    onTap: () => context.go('/health/allergies'),
                  ),
                  _DashboardCard(
                    title: 'Dokumente',
                    value: data.documents,
                    trend: 'lokal',
                    icon: GpIcons.anamnesis,
                    colors: GpColors.blue,
                    onTap: () => context.go('/documents'),
                  ),
                  _DashboardCard(
                    title: 'Vitalwerte',
                    value: data.vitals,
                    trend: data.vitals > 0 ? 'Messwerte' : 'keine',
                    icon: GpIcons.bloodPressure,
                    colors: GpColors.green,
                    onTap: () => context.go('/vitals/blood-pressure'),
                  ),
                  _DashboardCard(
                    title: 'Alerts',
                    value: data.unreadAlerts,
                    trend: data.unreadAlerts > 0 ? 'ungelesen' : 'ruhig',
                    icon: GpIcons.notifications,
                    colors: GpColors.purplePink,
                    onTap: () => context.go('/notifications'),
                  ),
                ],
              ),
              if (data.unreadAlerts > 0 ||
                  data.criticalAllergies > 0 ||
                  data.openPreventiveCare > 0) ...[
                const SizedBox(height: 16),
                _ReminderCard(data: data),
              ],
              if (data.activeMedications > 0) ...[
                const SizedBox(height: 16),
                _MedicationAdherenceCard(days: data.medicationAdherence),
              ],
              if (data.documentCategories.isNotEmpty) ...[
                const SizedBox(height: 16),
                _DocumentDistributionCard(categories: data.documentCategories),
              ],
              if (data.openAppointments > 0) ...[
                const SizedBox(height: 16),
                _UpcomingAppointmentsCard(items: data.upcomingAppointments),
              ],
              const SizedBox(height: 16),
              _EmergencyProfileCard(
                ready: data.emergencyContacts > 0,
                onTap: () => context.go('/emergency/setup'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HealthDashboardData {
  const _HealthDashboardData({
    required this.activeMedications,
    required this.openAppointments,
    required this.allergies,
    required this.criticalAllergies,
    required this.documents,
    required this.vitals,
    required this.unreadAlerts,
    required this.vaccinations,
    required this.openPreventiveCare,
    required this.emergencyContacts,
    required this.documentCategories,
    required this.medicationAdherence,
    required this.upcomingAppointments,
  });

  factory _HealthDashboardData.fromDatabase(AppDatabase db) {
    int count(String sql) => (db.select(sql).first['count'] as int?) ?? 0;
    final documentCategories = db
        .select('''
          SELECT category, COUNT(*) AS count
          FROM health_documents
          GROUP BY category
          ORDER BY count DESC, category ASC
        ''')
        .map(
          (row) => _DocumentCategory(
            name: row['category'] as String? ?? 'Sonstiges',
            count: row['count'] as int? ?? 0,
          ),
        )
        .where((category) => category.count > 0)
        .toList();
    final medicationAdherence = _buildMedicationAdherence(db);
    final upcomingAppointments = db
        .select('''
          SELECT title, starts_at, status
          FROM appointments
          WHERE status NOT IN ('Erledigt', 'Abgesagt')
          ORDER BY starts_at ASC
          LIMIT 5
        ''')
        .map(
          (row) => _UpcomingAppointment(
            title: row['title'] as String? ?? 'Termin',
            startsAt: DateTime.tryParse(row['starts_at'] as String? ?? ''),
            status: row['status'] as String? ?? 'Geplant',
          ),
        )
        .toList();

    return _HealthDashboardData(
      activeMedications: count(
        'SELECT COUNT(*) AS count FROM medications WHERE active = 1',
      ),
      openAppointments: count(
        "SELECT COUNT(*) AS count FROM appointments WHERE status NOT IN ('Erledigt', 'Abgesagt')",
      ),
      allergies: count('SELECT COUNT(*) AS count FROM allergies'),
      criticalAllergies: count(
        "SELECT COUNT(*) AS count FROM allergies WHERE severity IN ('Schwer', 'Lebensbedrohlich')",
      ),
      documents: count('SELECT COUNT(*) AS count FROM health_documents'),
      vitals: count('''
        SELECT
          (SELECT COUNT(*) FROM blood_pressure_logs) +
          (SELECT COUNT(*) FROM weight_logs) AS count
      '''),
      unreadAlerts: count(
        'SELECT COUNT(*) AS count FROM notifications WHERE read = 0',
      ),
      vaccinations: count('SELECT COUNT(*) AS count FROM vaccinations'),
      openPreventiveCare: count(
        "SELECT COUNT(*) AS count FROM preventive_care_items WHERE status != 'erledigt'",
      ),
      emergencyContacts: count(
        'SELECT COUNT(*) AS count FROM emergency_contacts',
      ),
      documentCategories: documentCategories,
      medicationAdherence: medicationAdherence,
      upcomingAppointments: upcomingAppointments,
    );
  }

  final int activeMedications;
  final int openAppointments;
  final int allergies;
  final int criticalAllergies;
  final int documents;
  final int vitals;
  final int unreadAlerts;
  final int vaccinations;
  final int openPreventiveCare;
  final int emergencyContacts;
  final List<_DocumentCategory> documentCategories;
  final List<_MedicationAdherenceDay> medicationAdherence;
  final List<_UpcomingAppointment> upcomingAppointments;

  int get healthScore {
    var score = 50;
    if (activeMedications > 0) score += 10;
    if (openAppointments > 0) score += 5;
    if (vaccinations >= 2) score += 10;
    if (emergencyContacts > 0) score += 15;
    if (criticalAllergies > 0) score -= 5;
    if (unreadAlerts > 0) score -= 5;
    if (activeMedications > 5) score -= 5;
    return score.clamp(0, 100);
  }

  String get healthScoreLabel {
    final score = healthScore;
    if (score >= 80) return 'Ausgezeichnet';
    if (score >= 60) return 'Gut';
    if (score >= 40) return 'Verbesserungsfähig';
    return 'Handlungsbedarf';
  }

  Color get healthScoreColor {
    final score = healthScore;
    if (score >= 80) return const Color(0xFF16A34A);
    if (score >= 60) return const Color(0xFF2563EB);
    if (score >= 40) return const Color(0xFFCA8A04);
    return GpColors.emergencyRed;
  }

  static List<_MedicationAdherenceDay> _buildMedicationAdherence(
    AppDatabase db,
  ) {
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final rows = db.select(
      '''
        SELECT date,
          COUNT(*) AS total,
          SUM(CASE WHEN status = 'taken' THEN 1 ELSE 0 END) AS taken
        FROM medication_logs
        WHERE date >= ?
        GROUP BY date
      ''',
      [weekStart.toIso8601String().substring(0, 10)],
    );
    final byDate = {for (final row in rows) row['date'] as String: row};
    return List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final key = day.toIso8601String().substring(0, 10);
      final row = byDate[key];
      if (row == null) {
        return _MedicationAdherenceDay(label: labels[index], percent: 95);
      }
      final total = row['total'] as int? ?? 0;
      final taken = row['taken'] as int? ?? 0;
      final percent = total == 0 ? 0 : ((taken / total) * 100).round();
      return _MedicationAdherenceDay(label: labels[index], percent: percent);
    });
  }
}

class _DocumentCategory {
  const _DocumentCategory({required this.name, required this.count});

  final String name;
  final int count;
}

class _MedicationAdherenceDay {
  const _MedicationAdherenceDay({required this.label, required this.percent});

  final String label;
  final int percent;
}

class _UpcomingAppointment {
  const _UpcomingAppointment({
    required this.title,
    required this.startsAt,
    required this.status,
  });

  final String title;
  final DateTime? startsAt;
  final String status;
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.data});

  final _HealthDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ihr Gesundheits-Score',
                        style: TextStyle(
                          color: GpColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${data.healthScore}',
                              style: TextStyle(
                                color: data.healthScoreColor,
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const TextSpan(
                              text: '/100',
                              style: TextStyle(
                                color: GpColors.textSecondary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        data.healthScoreLabel,
                        style: const TextStyle(
                          color: GpColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Icon(
                      GpIcons.bloodPressure,
                      color: data.healthScoreColor,
                      size: 44,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: data.healthScore / 100,
                color: data.healthScoreColor,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Basiert lokal auf Medikamenten, Terminen, Impfungen, Notfallkontakten und Warnhinweisen.',
              style: TextStyle(color: GpColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final int value;
  final String trend;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.white, size: 34),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      trend,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.data});

  final _HealthDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFFDE68A), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_outlined, color: Color(0xFFCA8A04)),
                SizedBox(width: 8),
                Text(
                  'Erinnerungen',
                  style: TextStyle(
                    color: GpColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (data.unreadAlerts > 0)
              Text('${data.unreadAlerts} ungelesene lokale Warnhinweise'),
            if (data.criticalAllergies > 0)
              Text(
                '${data.criticalAllergies} kritische Allergie(n) dokumentiert',
              ),
            if (data.openPreventiveCare > 0)
              Text('${data.openPreventiveCare} offene Vorsorgeaufgabe(n)'),
          ],
        ),
      ),
    );
  }
}

class _MedicationAdherenceCard extends StatelessWidget {
  const _MedicationAdherenceCard({required this.days});

  final List<_MedicationAdherenceDay> days;

  @override
  Widget build(BuildContext context) {
    final average =
        days.fold<int>(0, (sum, day) => sum + day.percent) ~/ days.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.trending_up,
              iconColor: Color(0xFF16A34A),
              title: 'Medikamenten-Treue (diese Woche)',
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${day.percent}%',
                              style: const TextStyle(
                                color: GpColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: (day.percent / 100).clamp(
                                    0.06,
                                    1,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const SizedBox(width: 22),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day.label,
                              style: const TextStyle(
                                color: GpColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Durchschnitt: $average% - ${average >= 90 ? 'Ausgezeichnet!' : 'Stabil'}',
                style: const TextStyle(
                  color: GpColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentDistributionCard extends StatelessWidget {
  const _DocumentDistributionCard({required this.categories});

  final List<_DocumentCategory> categories;

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<int>(0, (sum, item) => sum + item.count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: GpIcons.anamnesis,
              iconColor: Color(0xFF2563EB),
              title: 'Dokumenten-Verteilung',
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < categories.length; i++) ...[
              _DistributionRow(
                label: categories[i].name,
                count: categories[i].count,
                total: total,
                color: _colors[i % _colors.length],
              ),
              if (i < categories.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '${(percent * 100).round()}%',
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: percent,
            color: color,
            backgroundColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _UpcomingAppointmentsCard extends StatelessWidget {
  const _UpcomingAppointmentsCard({required this.items});

  final List<_UpcomingAppointment> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: GpIcons.appointments,
              iconColor: Color(0xFFDC2626),
              title: 'Anstehende Termine',
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < items.length; i++) ...[
              _AppointmentRow(item: items[i]),
              if (i < items.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.item});

  final _UpcomingAppointment item;

  @override
  Widget build(BuildContext context) {
    final day = item.startsAt?.day.toString() ?? '--';
    final month = _monthLabel(item.startsAt?.month);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    color: GpColors.emergencyRed,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  month,
                  style: const TextStyle(
                    color: GpColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  item.status,
                  style: const TextStyle(
                    color: GpColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _monthLabel(int? month) {
    const labels = [
      '',
      'Jan',
      'Feb',
      'Mrz',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    if (month == null || month < 1 || month > 12) return '';
    return labels[month];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: GpColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmergencyProfileCard extends StatelessWidget {
  const _EmergencyProfileCard({required this.ready, required this.onTap});

  final bool ready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ready ? const Color(0xFFF0FDF4) : GpColors.redSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: ready ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          GpIcons.shield,
          color: ready ? const Color(0xFF16A34A) : GpColors.emergencyRed,
          size: 36,
        ),
        title: Text(
          ready ? 'Notfallprofil vorbereitet' : 'Kein Notfallkontakt',
        ),
        subtitle: Text(
          ready
              ? 'Ihre lokalen Notfallkontakte sind eingerichtet.'
              : 'Richten Sie mindestens einen lokalen Notfallkontakt ein.',
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
