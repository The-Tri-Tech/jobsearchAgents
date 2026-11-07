import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _tokenKey = "skillbridge_jwt_token";

  // Save JWT
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get JWT
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Clear JWT (Logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Sign Up
  Future<UserModel> signup({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final url = Uri.parse(ApiConstants.signupEndpoint);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "full_name": fullName ?? "Student",
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      if (token != null) {
        await saveToken(token);
      }
      return UserModel.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Signup failed');
    }
  }

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(ApiConstants.loginEndpoint);
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      if (token != null) {
        await saveToken(token);
      }
      return UserModel.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed. Please check credentials.');
    }
  }

  // Fetch Dashboard Overview
  Future<DashboardOverviewModel> fetchDashboardOverview() async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.dashboardOverviewEndpoint);
    
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DashboardOverviewModel.fromJson(data);
    } else {
      // Return default placeholder overview if token expired or network error
      return DashboardOverviewModel(
        greeting: "Good morning, Student ✦",
        subtitle: "This view updates from your real resume, JD, roadmap, quiz, interview, and jobs activity.",
        user: UserModel(id: 1, email: "student@skillbridge.ai", fullName: "Student", plan: "Pro plan", avatarLetter: "A"),
        metrics: [
          StatCardModel(title: "ATS Score", value: "--", actionLabel: "Upload resume to start", iconType: "person"),
          StatCardModel(title: "JD Match", value: "--", actionLabel: "Analyze a JD", iconType: "target"),
          StatCardModel(title: "Quiz Score", value: "--", actionLabel: "Complete a quiz", iconType: "lightning"),
          StatCardModel(title: "Jobs Saved", value: "0", actionLabel: "Search jobs to populate", iconType: "briefcase"),
        ],
        weeklyProgress: [
          ProgressItemModel(label: "Resume strength", status: "No data"),
          ProgressItemModel(label: "JD match rate", status: "No data"),
          ProgressItemModel(label: "Roadmap completion", status: "No roadmap yet"),
          ProgressItemModel(label: "Interview score", status: "Not completed"),
        ],
        todayTasks: [
          TaskItemModel(id: 1, title: "Upload and parse resume"),
          TaskItemModel(id: 2, title: "Run ATS analysis"),
          TaskItemModel(id: 3, title: "Analyze JD match"),
          TaskItemModel(id: 4, title: "Generate roadmap"),
          TaskItemModel(id: 5, title: "Complete adaptive quiz"),
          TaskItemModel(id: 6, title: "Complete mock interview"),
          TaskItemModel(id: 7, title: "Save at least one job"),
        ],
      );
    }
  }
}

