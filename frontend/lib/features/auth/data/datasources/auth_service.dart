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
      subtitle: "This view updates from your real resume, JD matcher, and jobs activity.",
      user: UserModel(id: 1, email: "user@skillbridge.ai", fullName: "Candidate", plan: "Pro plan", avatarLetter: "C"),
      metrics: [
        StatCardModel(title: "Resumes", value: "--", actionLabel: "Upload resume", iconType: "document"),
        StatCardModel(title: "JD Match", value: "--", actionLabel: "Analyze a JD", iconType: "target"),
        StatCardModel(title: "Jobs Tracked", value: "0", actionLabel: "Explore jobs", iconType: "briefcase"),
        StatCardModel(title: "Follow-ups", value: "0", actionLabel: "View follow-ups", iconType: "calendar"),
      ],
      weeklyProgress: [
        ProgressItemModel(label: "Resume parsed", status: "Ready"),
        ProgressItemModel(label: "JD match analysis", status: "Ready"),
        ProgressItemModel(label: "Roadmap progress", status: "Phase 1 In Progress"),
        ProgressItemModel(label: "Analyzed jobs", status: "Active tracking"),
      ],
      todayTasks: [
        TaskItemModel(id: 1, title: "Upload and review resume"),
        TaskItemModel(id: 2, title: "Paste a target JD to run AI matching"),
        TaskItemModel(id: 3, title: "Review personalized career roadmap"),
        TaskItemModel(id: 4, title: "Track analyzed jobs and status"),
      ],
    );
  }

  // Fetch Career Roadmap
  Future<RoadmapModel> fetchRoadmap() async {
    final url = Uri.parse(ApiConstants.roadmapCurrentEndpoint);

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RoadmapModel.fromJson(data);
      }
    } catch (_) {}

    // Fallback default roadmap
    return RoadmapModel(
      targetRole: "Full-Stack Developer",
      experienceLevel: "Entry-to-Mid Level",
      overallProgress: 15,
      estimatedWeeks: 8,
      phases: [
        RoadmapPhaseModel(
          id: 1,
          phaseNumber: 1,
          title: "Core Foundations & Modern Tooling",
          duration: "Weeks 1–2",
          status: "in_progress",
          description: "Master modern web architectures, API design principles, and version control workflows.",
          tasks: [
            RoadmapTaskModel(id: 101, title: "Audit frontend & backend core competencies", completed: true),
            RoadmapTaskModel(id: 102, title: "Build robust REST APIs using FastAPI / Python", completed: false),
            RoadmapTaskModel(id: 103, title: "Configure containerization and automated CI/CD workflows", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 2,
          phaseNumber: 2,
          title: "Production Capstone Project",
          duration: "Weeks 3–4",
          status: "upcoming",
          description: "Build an end-to-end full stack application showcasing cloud deployment and test suites.",
          tasks: [
            RoadmapTaskModel(id: 201, title: "Implement system design and database models", completed: false),
            RoadmapTaskModel(id: 202, title: "Deploy live demo with comprehensive documentation", completed: false),
          ],
        ),
      ],
    );
  }

  // Generate Custom Roadmap
  Future<RoadmapModel> generateCustomRoadmap({
    required String targetRole,
    required String experienceLevel,
    int weeklyHours = 10,
  }) async {
    final url = Uri.parse(ApiConstants.roadmapGenerateEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "target_role": targetRole,
          "experience_level": experienceLevel,
          "weekly_hours": weeklyHours,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RoadmapModel.fromJson(data);
      }
    } catch (_) {}

    return fetchRoadmap();
  }

  Future<void> deleteFollowUp(int id) async {
    try {
      await http.delete(
        Uri.parse(ApiConstants.followUpDeleteEndpoint(id)),
        headers: {"Content-Type": "application/json"},
      );
    } catch (_) {}
  }

  Future<ReminderModel> createReminder({
    required String title,
    String category = "General",
    DateTime? dueDate,
  }) async {
    final url = Uri.parse(ApiConstants.dashboardRemindersEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "category": category,
          "due_date": dueDate != null ? dueDate.toIso8601String().split('T').first : null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReminderModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}

    return ReminderModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      category: category,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 2)),
      completed: false,
    );
  }

  Future<ReminderModel?> toggleReminder(int id) async {
    final url = Uri.parse(ApiConstants.reminderToggleEndpoint(id));

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return ReminderModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteReminder(int id) async {
    final url = Uri.parse(ApiConstants.reminderDeleteEndpoint(id));

    try {
      final response = await http.delete(
        url,
        headers: {"Content-Type": "application/json"},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
