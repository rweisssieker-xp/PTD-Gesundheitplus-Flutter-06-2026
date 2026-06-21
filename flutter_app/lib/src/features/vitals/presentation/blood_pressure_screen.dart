import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/vitals_repository.dart';
import '../domain/vitals.dart';

class BloodPressureScreen extends ConsumerStatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  ConsumerState<BloodPressureScreen> createState() =>
      _BloodPressureScreenState();
}

class _BloodPressureScreenState extends ConsumerState<BloodPressureScreen> {
  int _reload = 0;
  int? _rangeDays = 14;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GpColors.emergencyRed,
        onPressed: dbAsync.hasValue
            ? () => _openEditor(VitalsRepository(dbAsync.requireValue))
            : null,
        icon: const Icon(Icons.add),
        label: const Text('Messung'),
      ),
      body: dbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Datenbankfehler: $error')),
        data: (db) {
          final repo = VitalsRepository(db);
          return FutureBuilder<List<BloodPressureLog>>(
            key: ValueKey(_reload),
            future: repo.listBloodPressure(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              final latest = logs.isEmpty ? null : logs.first;
              final filteredLogs = _filteredLogs(logs);
              final stats = filteredLogs.isEmpty
                  ? null
                  : _BloodPressureStats.from(filteredLogs);
              return DefaultTabController(
                length: 2,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                  children: [
                    VitalsHeader(
                      title: 'Blutdruck',
                      value: latest == null
                          ? '-'
                          : '${latest.systolic}/${latest.diastolic}',
                      icon: GpIcons.bloodPressure,
                      colors: const [Color(0xFFEF4444), GpColors.emergencyRed],
                    ),
                    const SizedBox(height: 16),
                    if (latest == null)
                      const _EmptyVitalsCard(
                        icon: GpIcons.bloodPressure,
                        title: 'Noch keine Blutdruckwerte',
                        text:
                            'Erfassen Sie mindestens zwei Messungen, um Verlauf und Trend lokal auszuwerten.',
                      )
                    else
                      _LatestBloodPressureCard(log: latest),
                    const SizedBox(height: 12),
                    _RangeSelector(
                      selectedDays: _rangeDays,
                      color: GpColors.emergencyRed,
                      onChanged: (value) => setState(() => _rangeDays = value),
                    ),
                    const SizedBox(height: 12),
                    if (stats != null) _BloodPressureStatsGrid(stats: stats),
                    if (stats?.trendLabel != null) ...[
                      const SizedBox(height: 10),
                      _TrendCard(label: stats!.trendLabel!, trend: stats.trend),
                    ],
                    const SizedBox(height: 16),
                    const TabBar(
                      tabs: [
                        Tab(text: 'Verlauf'),
                        Tab(text: 'Historie'),
                      ],
                    ),
                    SizedBox(
                      height: logs.isEmpty ? 220 : 390,
                      child: TabBarView(
                        children: [
                          _BloodPressureTrendPanel(logs: filteredLogs),
                          _BloodPressureHistory(
                            logs: logs,
                            onDelete: (id) =>
                                _delete(repo.deleteBloodPressure, id),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _InfoCard(
                      icon: Icons.info_outline,
                      title: 'Empfehlung bei Bluthochdruck',
                      text:
                          'Messen Sie idealerweise morgens und abends in Ruhe. Auffaellige Werte sollten aerztlich abgeklärt werden.',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<BloodPressureLog> _filteredLogs(List<BloodPressureLog> logs) {
    final range = _rangeDays;
    if (range == null) return logs;
    final cutoff = DateTime.now().subtract(Duration(days: range));
    return logs.where((log) => log.measuredAt.isAfter(cutoff)).toList();
  }

  Future<void> _openEditor(VitalsRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BloodPressureEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }

  Future<void> _delete(
    Future<void> Function(String id) delete,
    String id,
  ) async {
    await delete(id);
    if (mounted) setState(() => _reload++);
  }
}

class _BloodPressureEditor extends StatefulWidget {
  const _BloodPressureEditor({required this.repo});

  final VitalsRepository repo;

  @override
  State<_BloodPressureEditor> createState() => _BloodPressureEditorState();
}

class _BloodPressureEditorState extends State<_BloodPressureEditor> {
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();
  final _measuredAt = TextEditingController(text: _formatInput(DateTime.now()));
  var _context = 'Ruhe';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Neue Messung', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _systolic,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Systole (mmHg) *',
                      hintText: '120',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _diastolic,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diastole (mmHg) *',
                      hintText: '80',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pulse,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puls (bpm)',
                      hintText: '70',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _measuredAt,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Zeitpunkt',
                      hintText: 'TT.MM.JJJJ HH:MM',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _context,
              decoration: const InputDecoration(
                labelText: 'Kontext',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Ruhe', child: Text('Ruhe')),
                DropdownMenuItem(value: 'Morgens', child: Text('Morgens')),
                DropdownMenuItem(value: 'Abends', child: Text('Abends')),
                DropdownMenuItem(
                  value: 'Nach Belastung',
                  child: Text('Nach Belastung'),
                ),
                DropdownMenuItem(
                  value: 'Bei Unwohlsein',
                  child: Text('Bei Unwohlsein'),
                ),
              ],
              onChanged: (value) => setState(() => _context = value ?? 'Ruhe'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final systolic = int.tryParse(_systolic.text);
    final diastolic = int.tryParse(_diastolic.text);
    if (systolic == null || diastolic == null) return;
    await widget.repo.addBloodPressure(
      systolic: systolic,
      diastolic: diastolic,
      pulse: int.tryParse(_pulse.text),
      context: _context,
      measuredAt: _parseDateTime(_measuredAt.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

class VitalsHeader extends StatelessWidget {
  const VitalsHeader({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 46),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70)),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestBloodPressureCard extends StatelessWidget {
  const _LatestBloodPressureCard({required this.log});

  final BloodPressureLog log;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Letzte Messung',
                    style: TextStyle(color: GpColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${log.systolic}/${log.diastolic}',
                    style: TextStyle(
                      color: _bloodPressureColor(log.systolic, log.diastolic),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${_formatDateTime(log.measuredAt)} • ${log.context}',
                    style: const TextStyle(color: GpColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (log.pulse != null)
              Column(
                children: [
                  const Icon(Icons.favorite, color: GpColors.emergencyRed),
                  const SizedBox(height: 4),
                  Text(
                    '${log.pulse}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text('bpm'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BloodPressureStatsGrid extends StatelessWidget {
  const _BloodPressureStatsGrid({required this.stats});

  final _BloodPressureStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Ø Systole',
            value: '${stats.avgSystolic}',
            color: GpColors.emergencyRed,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Ø Diastole',
            value: '${stats.avgDiastolic}',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Max',
            value: '${stats.maxSystolic}',
            color: const Color(0xFFF97316),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            label: 'Min',
            value: '${stats.minSystolic}',
            color: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}

class _BloodPressureTrendPanel extends StatelessWidget {
  const _BloodPressureTrendPanel({required this.logs});

  final List<BloodPressureLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.length < 2) {
      return const _EmptyVitalsCard(
        icon: GpIcons.bloodPressure,
        title: 'Nicht genügend Daten für Grafik',
        text: 'Bitte mindestens 2 Messungen erfassen.',
      );
    }
    final chronological = logs.reversed.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lokaler Verlauf',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: CustomPaint(
                painter: _BloodPressureChartPainter(chronological),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LegendDot(color: GpColors.emergencyRed, label: 'Systole'),
                _LegendDot(color: Color(0xFF2563EB), label: 'Diastole'),
                _LegendDot(color: Color(0xFF9333EA), label: 'Puls'),
                _ZoneBadge(color: Color(0xFFFEE2E2), label: 'Hoch >130'),
                _ZoneBadge(color: Color(0xFFFEF9C3), label: 'Grenzwertig'),
                _ZoneBadge(color: Color(0xFFDCFCE7), label: 'Normal'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodPressureHistory extends StatelessWidget {
  const _BloodPressureHistory({required this.logs, required this.onDelete});

  final List<BloodPressureLog> logs;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyVitalsCard(
        icon: GpIcons.bloodPressure,
        title: 'Keine Historie',
        text: 'Neue Messungen erscheinen hier lokal auf diesem Gerät.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          child: ListTile(
            leading: Icon(
              GpIcons.bloodPressure,
              color: _bloodPressureColor(log.systolic, log.diastolic),
            ),
            title: Text('${log.systolic}/${log.diastolic} mmHg'),
            subtitle: Text(
              '${_formatDateTime(log.measuredAt)} • ${log.context}${log.pulse == null ? '' : ' • Puls ${log.pulse}'}',
            ),
            trailing: IconButton(
              tooltip: 'Messung löschen',
              onPressed: () => onDelete(log.id),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        );
      },
    );
  }
}

class _BloodPressureChartPainter extends CustomPainter {
  const _BloodPressureChartPainter(this.logs);

  final List<BloodPressureLog> logs;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Offset.zero & size;
    final zonePaint = Paint()..style = PaintingStyle.fill;
    void drawZone(double from, double to, Color color) {
      final top = _y(to, chart);
      final bottom = _y(from, chart);
      canvas.drawRect(
        Rect.fromLTRB(chart.left, top, chart.right, bottom),
        zonePaint..color = color,
      );
    }

    drawZone(130, 180, const Color(0x33EF4444));
    drawZone(100, 130, const Color(0x33EAB308));
    drawZone(60, 100, const Color(0x3316A34A));

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (final value in [60, 90, 120, 140, 180]) {
      final y = _y(value.toDouble(), chart);
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    _drawLine(
      canvas,
      chart,
      logs.map((log) => log.systolic.toDouble()).toList(),
      GpColors.emergencyRed,
    );
    _drawLine(
      canvas,
      chart,
      logs.map((log) => log.diastolic.toDouble()).toList(),
      const Color(0xFF2563EB),
    );
    _drawLine(
      canvas,
      chart,
      logs.map((log) => (log.pulse ?? 0).toDouble()).toList(),
      const Color(0xFF9333EA),
      skipZero: true,
    );
  }

  void _drawLine(
    Canvas canvas,
    Rect chart,
    List<double> values,
    Color color, {
    bool skipZero = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = color;
    final path = Path();
    var hasPoint = false;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (skipZero && value == 0) continue;
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + (chart.width * i / (values.length - 1));
      final y = _y(value, chart);
      if (!hasPoint) {
        path.moveTo(x, y);
        hasPoint = true;
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    if (hasPoint) canvas.drawPath(path, paint);
  }

  double _y(double value, Rect chart) {
    const min = 50.0;
    const max = 180.0;
    final clamped = value.clamp(min, max);
    return chart.bottom - ((clamped - min) / (max - min) * chart.height);
  }

  @override
  bool shouldRepaint(covariant _BloodPressureChartPainter oldDelegate) =>
      oldDelegate.logs != logs;
}

class _BloodPressureStats {
  const _BloodPressureStats({
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.maxSystolic,
    required this.minSystolic,
    required this.trend,
  });

  final int avgSystolic;
  final int avgDiastolic;
  final int maxSystolic;
  final int minSystolic;
  final String? trend;

  String? get trendLabel {
    if (trend == null) return null;
    return switch (trend) {
      'up' => 'Trend: Steigend',
      'down' => 'Trend: Sinkend',
      _ => 'Trend: Stabil',
    };
  }

  factory _BloodPressureStats.from(List<BloodPressureLog> logs) {
    final avgSys =
        logs.fold<int>(0, (sum, log) => sum + log.systolic) / logs.length;
    final avgDia =
        logs.fold<int>(0, (sum, log) => sum + log.diastolic) / logs.length;
    final systolic = logs.map((log) => log.systolic).toList();
    return _BloodPressureStats(
      avgSystolic: avgSys.round(),
      avgDiastolic: avgDia.round(),
      maxSystolic: systolic.reduce((a, b) => a > b ? a : b),
      minSystolic: systolic.reduce((a, b) => a < b ? a : b),
      trend: _trend(logs),
    );
  }

  static String? _trend(List<BloodPressureLog> logs) {
    if (logs.length < 3) return null;
    final chronological = logs.reversed.toList();
    final half = chronological.length ~/ 2;
    final first = chronological.take(half).toList();
    final second = chronological.skip(chronological.length - half).toList();
    final firstAvg =
        first.fold<int>(0, (sum, log) => sum + log.systolic) / first.length;
    final secondAvg =
        second.fold<int>(0, (sum, log) => sum + log.systolic) / second.length;
    final diff = secondAvg - firstAvg;
    if (diff > 3) return 'up';
    if (diff < -3) return 'down';
    return 'stable';
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedDays,
    required this.color,
    required this.onChanged,
  });

  final int? selectedDays;
  final Color color;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (label: '7 Tage', days: 7),
      (label: '14 Tage', days: 14),
      (label: '30 Tage', days: 30),
      (label: 'Alle', days: null),
    ];
    return Row(
      children: [
        for (final option in options) ...[
          Expanded(
            child: ChoiceChip(
              label: Text(option.label),
              selected: selectedDays == option.days,
              selectedColor: color,
              labelStyle: TextStyle(
                color: selectedDays == option.days ? Colors.white : color,
                fontWeight: FontWeight.w800,
              ),
              onSelected: (_) => onChanged(option.days),
            ),
          ),
          if (option != options.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.09),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GpColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.label, required this.trend});

  final String label;
  final String? trend;

  @override
  Widget build(BuildContext context) {
    final color = switch (trend) {
      'up' => GpColors.emergencyRed,
      'down' => const Color(0xFF16A34A),
      _ => GpColors.textSecondary,
    };
    final icon = switch (trend) {
      'up' => Icons.trending_up,
      'down' => Icons.trending_down,
      _ => Icons.trending_flat,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _EmptyVitalsCard extends StatelessWidget {
  const _EmptyVitalsCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: GpColors.textSecondary, size: 42),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: GpColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(color: Color(0xFF1E40AF))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _ZoneBadge extends StatelessWidget {
  const _ZoneBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

Color _bloodPressureColor(int systolic, int diastolic) {
  if (systolic > 140 || diastolic > 90) return GpColors.emergencyRed;
  if (systolic > 130 || diastolic > 85) return const Color(0xFFEAB308);
  if (systolic < 100 || diastolic < 60) return const Color(0xFF2563EB);
  return const Color(0xFF16A34A);
}

String _formatDateTime(DateTime value) =>
    '${value.day}.${value.month}.${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _formatInput(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

DateTime? _parseDateTime(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final iso = DateTime.tryParse(trimmed);
  if (iso != null) return iso;
  final match = RegExp(
    r'^(\d{1,2})\.(\d{1,2})\.(\d{4})(?:\s+(\d{1,2}):(\d{2}))?$',
  ).firstMatch(trimmed);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.tryParse(match.group(4) ?? '0') ?? 0,
    int.tryParse(match.group(5) ?? '0') ?? 0,
  );
}
