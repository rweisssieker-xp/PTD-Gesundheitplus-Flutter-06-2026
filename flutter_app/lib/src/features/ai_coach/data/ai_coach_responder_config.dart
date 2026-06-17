import 'package:dio/dio.dart';

import '../../../core/ai/ai_client.dart';
import 'ai_coach_repository.dart';

class AiCoachResponderConfig {
  const AiCoachResponderConfig({
    this.endpoint = const String.fromEnvironment('GESUNDHEIT_PLUS_AI_ENDPOINT'),
  });

  final String endpoint;

  bool get isConfigured => endpoint.trim().isNotEmpty;

  AiCoachResponder? buildResponder({Dio? dio}) {
    final trimmedEndpoint = endpoint.trim();
    if (trimmedEndpoint.isEmpty) return null;
    final client = AiClient(dio: dio ?? Dio(), endpoint: trimmedEndpoint);
    return client.ask;
  }
}
