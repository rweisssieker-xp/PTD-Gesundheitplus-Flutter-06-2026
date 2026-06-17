class HealthDocument {
  const HealthDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.localPath,
    this.mimeType,
    required this.capturedAt,
    this.notes,
  });

  final String id;
  final String title;
  final String category;
  final String localPath;
  final String? mimeType;
  final DateTime capturedAt;
  final String? notes;
}
