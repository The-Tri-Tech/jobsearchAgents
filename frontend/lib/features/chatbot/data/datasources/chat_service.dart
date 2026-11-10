import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

class ChatResponseData {
  final String reply;
  final String? toolCalled;

  ChatResponseData({required this.reply, this.toolCalled});
}

class ChatService {
  static const String _tokenKey = 'skillbridge_jwt_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<ChatResponseData> sendMessage({
    required String message,
    List<Map<String, String>> history = const [],
    String? resumeFilename,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConstants.chatEndpoint);

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'message': message,
            'history': history,
            if (resumeFilename != null) 'resume_filename': resumeFilename,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ChatResponseData(
        reply: data['reply'] as String,
        toolCalled: data['tool_called'] as String?,
      );
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to get AI response');
    }
  }
}

