import 'package:dio/dio.dart';

class AiClient {
  AiClient({required Dio dio, required String endpoint})
    : _dio = dio,
      _endpoint = endpoint;

  final Dio _dio;
  final String _endpoint;

  Future<String> ask({required String prompt, required String context}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _endpoint,
      data: {'prompt': prompt, 'context': context},
    );
    final answer = response.data?['answer'];
    if (answer is! String || answer.isEmpty) {
      throw StateError('AI response did not contain an answer');
    }
    return answer;
  }
}
