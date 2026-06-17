class HealthDocument {
  const HealthDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.localPath,
    this.mimeType,
    this.fileKey,
    this.fileNonce,
    this.fileMac,
    this.encrypted = false,
    required this.capturedAt,
    this.notes,
  });

  final String id;
  final String title;
  final String category;
  final String localPath;
  final String? mimeType;
  final String? fileKey;
  final String? fileNonce;
  final String? fileMac;
  final bool encrypted;
  final DateTime capturedAt;
  final String? notes;
}
