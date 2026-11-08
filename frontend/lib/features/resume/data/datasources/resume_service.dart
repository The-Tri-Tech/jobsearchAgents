import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/resume_model.dart';

class ResumeService {
  static const String _tokenKey = 'skillbridge_jwt_token';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Map<String, String> _authHeaders(String? token) => {
        'Authorization': 'Bearer ${token ?? ''}',
      };

  // ── Upload ──────────────────────────────────────────────────────────────────
  /// [bytes]     raw file bytes
  /// [filename]  original filename (must end in .pdf / .doc / .docx)
  Future<ResumeModel> uploadResume({
    required Uint8List bytes,
    required String filename,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConstants.resumeUploadEndpoint);

    // Determine MIME type from extension
    final lower = filename.toLowerCase();
    MediaType mediaType;
    if (lower.endsWith('.pdf')) {
      mediaType = MediaType('application', 'pdf');
    } else if (lower.endsWith('.docx')) {
      mediaType = MediaType('application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document');
    } else {
      mediaType = MediaType('application', 'msword');
    }

    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders(token))
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: mediaType,
        ),
      );

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return ResumeModel.fromJson(jsonDecode(body));
    } else {
      final err = jsonDecode(body);
      throw Exception(err['detail'] ?? 'Upload failed');
    }
  }

  // ── List ────────────────────────────────────────────────────────────────────
  Future<List<ResumeModel>> listResumes() async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConstants.resumeListEndpoint);

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      ..._authHeaders(token),
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data['resumes'] as List? ?? []);
      return list.map((r) => ResumeModel.fromJson(r)).toList();
    } else {
      throw Exception('Failed to load resumes');
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────
  Future<void> deleteResume(String filename) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConstants.resumeDeleteEndpoint(filename));

    final response = await http.delete(uri, headers: {
      'Content-Type': 'application/json',
      ..._authHeaders(token),
    });

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Delete failed');
    }
  }

  // ── Build open URL (authenticated via query param token) ───────────────────
  Future<String> getFileUrl(String filename) async {
    final token = await _getToken();
    // We pass the JWT as a query param so the browser tab can open it directly.
    // The backend verifies it via the Bearer scheme; for file serving we
    // append ?token= and handle it in a small wrapper, OR we simply use
    // the direct URL with the auth header embedded (not possible in browser).
    // Best approach for web: use a temporary object URL created from fetched bytes.
    return '${ApiConstants.resumeFileEndpoint(filename)}?token=${token ?? ''}';
  }

  // ── Fetch file bytes (for creating object URLs in browser) ─────────────────
  Future<Uint8List> fetchFileBytes(String filename) async {
    final token = await _getToken();
    final uri = Uri.parse(ApiConstants.resumeFileEndpoint(filename));

    final response = await http.get(uri, headers: _authHeaders(token));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Could not load file');
    }
  }
}
