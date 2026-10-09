import 'package:dio/dio.dart';

class AiException implements Exception {
  const AiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Text in, text out (section 9.1's `TextGenerationClient`).
abstract class TextGenerationClient {
  Future<String> complete({
    required String system,
    required String user,
    int maxTokens = 600,
  });
}

/// The OpenAI Chat Completions wire format, which OpenRouter, OpenAI, Ollama
/// and most self-hosted servers all speak.
class OpenAiCompatibleClient implements TextGenerationClient {
  OpenAiCompatibleClient({
    required String baseUrl,
    required this.model,
    this.apiKey,
    Dio? dio,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 10),
               // Free and local models can be slow; a long answer from a small
               // box on the LAN is normal, not a failure.
               receiveTimeout: const Duration(seconds: 90),
             ),
           );

  final String model;
  final String? apiKey;
  final Dio _dio;

  @override
  Future<String> complete({
    required String system,
    required String user,
    int maxTokens = 600,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/chat/completions',
        data: {
          'model': model,
          'messages': [
            {'role': 'system', 'content': system},
            {'role': 'user', 'content': user},
          ],
          // Low: this picks from a list and a repeatable answer is the point.
          'temperature': 0.2,
          'max_tokens': maxTokens,
        },
        options: Options(
          headers: {
            if (apiKey != null && apiKey!.isNotEmpty)
              'Authorization': 'Bearer $apiKey',
            // Names the app to OpenRouter, which asks for it. No user data.
            'X-Title': 'Subnext Player',
          },
        ),
      );
      final choices = response.data?['choices'];
      final content = choices is List && choices.isNotEmpty
          ? (choices.first as Map?)?['message']?['content']
          : null;
      if (content is! String || content.trim().isEmpty) {
        throw const AiException('The model sent back an empty answer.');
      }
      return content;
    } on DioException catch (e) {
      throw AiException(_explain(e));
    }
  }

  static String _explain(DioException e) {
    final status = e.response?.statusCode;
    final detail = _detail(e.response?.data);
    final suffix = detail == null ? '' : ' ($detail)';
    return switch (status) {
      401 || 403 => 'The provider rejected that key$suffix.',
      402 => 'The provider says this account is out of credit$suffix.',
      404 => 'The provider does not know that model or address$suffix.',
      429 =>
        'The provider is rate limiting this key. Try again shortly$suffix.',
      final s? when s >= 500 => 'The provider had a problem (HTTP $s)$suffix.',
      _ => switch (e.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
          'The provider took too long to answer.',
        DioExceptionType.connectionError =>
          'Could not reach the provider. Check the address.',
        _ =>
          'The request failed${status == null ? '' : ' (HTTP $status)'}'
              '$suffix.',
      },
    };
  }

  /// The provider's own one-line reason, when it gave one. Short, because it is
  /// shown on screen.
  static String? _detail(Object? data) {
    if (data is! Map) return null;
    final error = data['error'];
    final message = error is Map ? error['message'] : error;
    if (message is! String || message.isEmpty) return null;
    return message.length > 120 ? '${message.substring(0, 120)}...' : message;
  }
}
