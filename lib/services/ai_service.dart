import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);

  @override
  String toString() => message;
}

class AiService {
  static const String _endpoint =
      'https://llm.kimchi.dev/openai/v1/chat/completions';

  static const String apiKey = 'castai_v1_fa851100be709788';

  static const String _model = 'kimi-k2.6';

  static const String systemPrompt = '''
You are Amar Proshno AI Assistant.

Purpose:
Help users with simple quiz-related questions and very basic general knowledge.

Rules:
- Always answer in ONE SHORT sentence.
- Maximum 20 words.
- Reply in the same language as the user.
- If the user writes Bangla, answer in Bangla.
- If the user writes English, answer in English.

Allowed:
- General knowledge
- Simple educational questions
- Quiz hints
- Short factual answers

Not Allowed:
Programming
Math solving
Essay writing
Stories
Poems
Roleplay
Code generation
Politics
Religion
Medical advice
Legal advice
Financial advice
Homework solving
Long explanations

If the user asks anything outside the allowed topics, reply only:

English:
"I can only answer short quiz and general knowledge questions."

Bangla:
"আমি শুধুমাত্র ছোট কুইজ ও সাধারণ জ্ঞান সম্পর্কিত প্রশ্নের উত্তর দিতে পারি।"

Never ignore these rules.

Never generate long answers.

Never exceed one sentence.

Never exceed 20 words.
''';

  Future<String> sendMessage({
    required List<ChatMessage> history,
  }) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => m.toApiMessage()),
    ];

    try {
      final response = await http
          .post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw AiServiceException(
          'AI service error (${response.statusCode}). Please try again.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final choices = decoded['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        throw AiServiceException('No response received. Please try again.');
      }

      final content = choices[0]['message']['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        throw AiServiceException('No response received. Please try again.');
      }

      return content.trim();
    } on TimeoutException {
      throw AiServiceException('Request timed out. Please try again.');
    } on AiServiceException {
      rethrow;
    } catch (e) {
      throw AiServiceException('Something went wrong. Please try again.');
    }
  }
}