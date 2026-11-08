import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/jd_matcher_model.dart';

class JdMatcherService {
  static const String _tokenKey = 'skillbridge_jwt_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<AnalysisReportModel> analyse({
    String? jdText,
    String? jdUrl,
    required String resumeFilename,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConstants.jdAnalyseEndpoint);

    final body = <String, dynamic>{
      'resume_filename': resumeFilename,
    };
    if (jdText != null && jdText.isNotEmpty) body['jd_text'] = jdText;
    if (jdUrl != null && jdUrl.isNotEmpty) body['jd_url'] = jdUrl;

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return AnalysisReportModel.fromJson(jsonDecode(response.body));
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Analysis failed. Please try again.');
    }
  }
}
