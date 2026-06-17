import 'package:flutter/material.dart';

import '../../../shared_ui/gp_colors.dart';
import '../domain/medical_document_insights.dart';

class MedicalInsightsCard extends StatelessWidget {
  const MedicalInsightsCard({super.key, required this.insights});

  final MedicalDocumentInsights insights;

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _urgencyColor(insights.urgency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: const Color(0xFFFAF5FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE9D5FF), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      color: Color(0xFF9333EA),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lokale Dokumentanalyse',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(insights.summary),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: urgencyColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(
                          _urgencyIcon(insights.urgency),
                          color: urgencyColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dringlichkeit: ${insights.urgency.label}'
                            '${insights.requiresAttention ? ' - Aufmerksamkeit empfohlen' : ''}',
                            style: TextStyle(
                              color: urgencyColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (insights.findings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Wichtigste Erkenntnisse',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  ...insights.findings.map(
                    (finding) => _InsightLine(
                      icon: Icons.check_circle_outline,
                      text: finding,
                      color: const Color(0xFF9333EA),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (insights.entities.isNotEmpty) ...[
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Erkannte medizinische Bereiche',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entity in insights.entities)
                        Chip(
                          avatar: Icon(_entityIcon(entity.type), size: 18),
                          label: Text('${entity.type.label}: ${entity.label}'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (insights.actions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Card(
            color: const Color(0xFFF0FDF4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFBBF7D0), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Empfohlene Aktionen',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  for (final action in insights.actions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _urgencyIcon(action.priority),
                        color: _urgencyColor(action.priority),
                      ),
                      title: Text(action.label),
                      subtitle: Text(action.description),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        const Text(
          'Diese Analyse erfolgt regelbasiert lokal auf dem Gerät und ersetzt keine ärztliche Bewertung.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GpColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Color _urgencyColor(InsightUrgency urgency) {
    return switch (urgency) {
      InsightUrgency.low => const Color(0xFF2563EB),
      InsightUrgency.medium => const Color(0xFFCA8A04),
      InsightUrgency.high => const Color(0xFFEA580C),
      InsightUrgency.urgent => GpColors.emergencyRed,
    };
  }

  IconData _urgencyIcon(InsightUrgency urgency) {
    return switch (urgency) {
      InsightUrgency.low => Icons.info_outline,
      InsightUrgency.medium => Icons.schedule_outlined,
      InsightUrgency.high => Icons.warning_amber_outlined,
      InsightUrgency.urgent => Icons.error_outline,
    };
  }

  IconData _entityIcon(MedicalEntityType type) {
    return switch (type) {
      MedicalEntityType.diagnosis => Icons.monitor_heart_outlined,
      MedicalEntityType.medication => Icons.medication_outlined,
      MedicalEntityType.labResult => Icons.science_outlined,
      MedicalEntityType.allergy => Icons.warning_amber_outlined,
      MedicalEntityType.vaccination => Icons.vaccines_outlined,
      MedicalEntityType.appointment => Icons.calendar_month_outlined,
      MedicalEntityType.procedure => Icons.medical_services_outlined,
    };
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
