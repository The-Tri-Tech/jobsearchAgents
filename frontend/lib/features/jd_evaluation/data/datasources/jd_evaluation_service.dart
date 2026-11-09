import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/quiz_model.dart';

class JdEvaluationService {
  static const String _tokenKey = 'skillbridge_jwt_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<GenerateQuizResponseModel> generateQuiz({
    required String resumeFilename,
    required String jdText,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConstants.jdEvaluationQuizEndpoint);

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'resume_filename': resumeFilename,
            'jd_text': jdText,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GenerateQuizResponseModel.fromJson(data);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to generate screening quiz');
    }
  }
}

