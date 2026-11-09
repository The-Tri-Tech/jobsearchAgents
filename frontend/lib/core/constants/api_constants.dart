class ApiConstants {
  // Use localhost for web and desktop, 10.0.2.2 for Android emulator
  static const String baseUrl = "http://127.0.0.1:8000/api/v1";
  static const String signupEndpoint = "$baseUrl/auth/signup";
  static const String loginEndpoint = "$baseUrl/auth/login";
  static const String meEndpoint = "$baseUrl/auth/me";
  static const String dashboardOverviewEndpoint = "$baseUrl/dashboard/overview";

  // Resume
  static const String resumeUploadEndpoint = "$baseUrl/resume/upload";
  static const String resumeListEndpoint = "$baseUrl/resume/list";
  static String resumeFileEndpoint(String filename) =>
      "$baseUrl/resume/file/$filename";
  static String resumeDeleteEndpoint(String filename) =>
      "$baseUrl/resume/file/$filename";

  // JD Matcher
  static const String jdAnalyseEndpoint = "$baseUrl/jd-matcher/analyse";
  static const String followUpsEndpoint = "$baseUrl/follow-ups";
  static String followUpToggleEndpoint(int id) => "$baseUrl/follow-ups/$id/toggle";
  static String followUpDeleteEndpoint(int id) => "$baseUrl/follow-ups/$id";

  // Roadmap
  static const String roadmapCurrentEndpoint = "$baseUrl/roadmap/current";
  static const String roadmapGenerateEndpoint = "$baseUrl/roadmap/generate";

  // Jobs
  static const String jobsEndpoint = "$baseUrl/jobs";
  static String jobStatusEndpoint(int id) => "$baseUrl/jobs/$id/status";
  static String jobUpdateEndpoint(int id) => "$baseUrl/jobs/$id";
  static String jobDeleteEndpoint(int id) => "$baseUrl/jobs/$id";

  // Reminders
  static const String dashboardRemindersEndpoint = "$baseUrl/dashboard/reminders";
  static String reminderToggleEndpoint(int id) => "$baseUrl/dashboard/reminders/$id/toggle";
  static String reminderDeleteEndpoint(int id) => "$baseUrl/dashboard/reminders/$id";
}
