import 'dart:async';
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

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw Exception(
          'Analysis timed out after 90 seconds. Try pasting the JD text directly instead of using a URL.');
    } on http.ClientException {
      throw Exception(
          'Could not connect to the backend server. Please verify the backend is running at http://127.0.0.1:8000.');
    } catch (e) {
      if (e.toString().contains('Failed to fetch') ||
          e.toString().contains('ClientException')) {
        throw Exception(
            'Could not connect to the backend server. Please verify the backend is running at http://127.0.0.1:8000.');
      }
      rethrow;
    }

    if (response.statusCode == 200) {
      return AnalysisReportModel.fromJson(jsonDecode(response.body));
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['detail'] ?? 'Analysis failed. Please try again.');
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) {
          rethrow;
        }
        throw Exception(
            'Server returned error ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown'}');
      }
    }
  }

  Future<void> createFollowUp({
    required String reportTitle,
    required String resumeFilename,
    required DateTime applicationDate,
    required int followUpAfterDays,
  }) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConstants.followUpsEndpoint),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'report_title': reportTitle,
        'resume_filename': resumeFilename,
        'application_date': _dateOnly(applicationDate),
        'follow_up_after_days': followUpAfterDays,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Could not enable follow-up.');
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
