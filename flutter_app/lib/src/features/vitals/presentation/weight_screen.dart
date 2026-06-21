import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/database_provider.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_icons.dart';
import '../../../shared_ui/gp_screen.dart';
import '../data/vitals_repository.dart';
import '../domain/vitals.dart';
import 'blood_pressure_screen.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(appDatabaseProvider);
    return GpScreen(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF4F46E5),
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
          return FutureBuilder<List<WeightLog>>(
            key: ValueKey(_reload),
            future: repo.listWeight(),
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              final latest = logs.isEmpty ? null : logs.first;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                children: [
                  VitalsHeader(
                    title: 'Gewicht & BMI',
                    value: latest == null
                        ? '-'
                        : '${latest.weightKg.toStringAsFixed(1)} kg',
                    icon: GpIcons.weight,
                    colors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  const SizedBox(height: 16),
                  if (latest == null)
                    const _WeightEmptyCard()
                  else
                    _WeightDashboard(latest: latest),
                  const SizedBox(height: 16),
                  _WeightTrendPanel(logs: logs),
                  const SizedBox(height: 16),
                  const Text(
                    'Historie',
                    style: TextStyle(
                      color: GpColors.textSecondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (logs.isEmpty)
                    const _WeightEmptyCard()
                  else
                    ...logs.map(
                      (log) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(
                            GpIcons.weight,
                            color: Color(0xFF4F46E5),
                          ),
                          title: Text('${log.weightKg.toStringAsFixed(1)} kg'),
                          subtitle: Text(
                            '${_formatDateTime(log.measuredAt)}${log.bmi == null ? '' : ' • BMI ${log.bmi!.toStringAsFixed(1)}'}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Messung löschen',
                            onPressed: () => _delete(repo, log.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const _WeightInfoCard(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(VitalsRepository repo) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WeightEditor(repo: repo),
    );
    if (saved == true) setState(() => _reload++);
  }

  Future<void> _delete(VitalsRepository repo, String id) async {
    await repo.deleteWeight(id);
    if (mounted) setState(() => _reload++);
  }
}

class _WeightEditor extends StatefulWidget {
  const _WeightEditor({required this.repo});

  final VitalsRepository repo;

  @override
  State<_WeightEditor> createState() => _WeightEditorState();
}

class _WeightEditorState extends State<_WeightEditor> {
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _measuredAt = TextEditingController(text: _formatInput(DateTime.now()));

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
            Text(
              'Gewicht eintragen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Gewicht (kg) *',
                hintText: 'z.B. 75.5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _height,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Groesse cm',
                hintText: 'z.B. 175',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _measuredAt,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Datum',
                hintText: 'TT.MM.JJJJ HH:MM',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Speichern')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (weight == null) return;
    await widget.repo.addWeight(
      weightKg: weight,
      heightCm: double.tryParse(_height.text.replaceAll(',', '.')),
      measuredAt: _parseDateTime(_measuredAt.text),
    );
    if (mounted) Navigator.pop(context, true);
  }
}

class _WeightDashboard extends StatelessWidget {
  const _WeightDashboard({required this.latest});

  final WeightLog latest;

  @override
  Widget build(BuildContext context) {
    final bmi = latest.bmi;
    final bmiInfo = _bmiInfo(bmi);
    return Row(
      children: [
        Expanded(
          child: _DashboardCard(
            label: 'Aktuelles Gewicht',
            value: latest.weightKg.toStringAsFixed(1),
            unit: 'kg',
            color: GpColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DashboardCard(
            label: 'Ihr BMI',
            value: bmi?.toStringAsFixed(1) ?? '-',
            unit: bmiInfo.label,
            color: bmiInfo.color,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: GpColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 31,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              unit,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendPanel extends StatelessWidget {
  const _WeightTrendPanel({required this.logs});

  final List<WeightLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(GpIcons.weight, color: GpColors.textSecondary, size: 42),
              SizedBox(height: 8),
              Text(
                'Nicht genügend Daten für Verlauf',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Bitte mindestens 2 Gewichtswerte erfassen.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GpColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verlauf',
              style: TextStyle(
                color: GpColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _WeightChartPainter(logs.reversed.toList()),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter(this.logs);

  final List<WeightLog> logs;

  @override
  void paint(Canvas canvas, Size size) {
    final values = logs.map((log) => log.weightKg).toList();
    final min = values.reduce((a, b) => a < b ? a : b) - 2;
    final max = values.reduce((a, b) => a > b ? a : b) + 2;
    final chart = Offset.zero & size;
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    final path = Path();
    final linePaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = const Color(0xFF4F46E5);
    for (var i = 0; i < logs.length; i++) {
      final x = logs.length == 1
          ? chart.center.dx
          : chart.left + chart.width * i / (logs.length - 1);
      final y =
          chart.bottom -
          ((logs[i].weightKg - min) / (max - min) * chart.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.logs != logs;
}

class _WeightEmptyCard extends StatelessWidget {
  const _WeightEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(GpIcons.weight, color: GpColors.textSecondary, size: 42),
            SizedBox(height: 8),
            Text(
              'Noch keine Gewichtswerte',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 4),
            Text(
              'Erfassen Sie Gewicht und optional Groesse fuer die lokale BMI-Berechnung.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GpColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightInfoCard extends StatelessWidget {
  const _WeightInfoCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color(0xFFEFF6FF),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Der BMI wird lokal aus Gewicht und Groesse berechnet. Werte ersetzen keine aerztliche Beurteilung.',
                style: TextStyle(color: Color(0xFF1E40AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({String label, Color color}) _bmiInfo(double? bmi) {
  if (bmi == null) {
    return (label: '-', color: GpColors.textSecondary);
  }
  if (bmi < 18.5) {
    return (label: 'Untergewicht', color: const Color(0xFF2563EB));
  }
  if (bmi < 25) {
    return (label: 'Normalgewicht', color: const Color(0xFF16A34A));
  }
  if (bmi < 30) {
    return (label: 'Uebergewicht', color: const Color(0xFFF97316));
  }
  return (label: 'Adipositas', color: GpColors.emergencyRed);
}

String _formatDateTime(DateTime value) =>
    '${value.day}.${value.month}.${value.year}, ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

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
