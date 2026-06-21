import 'package:dio/dio.dart';

import '../../../core/ai/ai_client.dart';
import 'ai_coach_repository.dart';

class AiCoachResponderConfig {
  const AiCoachResponderConfig({
    this.endpoint = const String.fromEnvironment('GESUNDHEIT_PLUS_AI_ENDPOINT'),
  });

  final String endpoint;

  bool get isConfigured => _httpsEndpoint != null;

  AiCoachResponder? buildResponder({Dio? dio}) {
    final configuredEndpoint = _httpsEndpoint;
    if (configuredEndpoint == null) return null;
    final client = AiClient(dio: dio ?? Dio(), endpoint: configuredEndpoint);
    return client.ask;
  }

  String? get _httpsEndpoint {
    final trimmedEndpoint = endpoint.trim();
    if (trimmedEndpoint.isEmpty) return null;
    final uri = Uri.tryParse(trimmedEndpoint);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') return null;
    return trimmedEndpoint;
  }
}
