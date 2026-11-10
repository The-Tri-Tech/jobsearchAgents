import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  // Fetch Dashboard Overview (Directly without auth)
  Future<DashboardOverviewModel> fetchDashboardOverview() async {
    final url = Uri.parse(ApiConstants.dashboardOverviewEndpoint);
    
    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardOverviewModel.fromJson(data);
      }
    } catch (_) {
      // Fallback below
    }

    // Default overview
    return DashboardOverviewModel(
      greeting: "Welcome ✦",
      subtitle: "Track your uploaded resumes and JD match evaluations.",
      user: UserModel(id: 1, email: "user@skillbridge.ai", fullName: "Candidate", plan: "Pro plan", avatarLetter: "C"),
      metrics: [
        StatCardModel(title: "Resumes Uploaded", value: "--", actionLabel: "Upload resume to start", iconType: "document"),
        StatCardModel(title: "JD Match Rate", value: "--", actionLabel: "Analyze a JD", iconType: "target"),
      ],
      weeklyProgress: [
        ProgressItemModel(label: "Resume parsed", status: "Ready"),
        ProgressItemModel(label: "JD match analysis", status: "Ready"),
      ],
      todayTasks: [
        TaskItemModel(id: 1, title: "Upload and review resume"),
        TaskItemModel(id: 2, title: "Paste a target JD to run AI matching"),
      ],
    );
  }
}
