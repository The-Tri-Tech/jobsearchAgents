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
  static String resumeFileEndpoint(String filename) => "$baseUrl/resume/file/$filename";
  static String resumeDeleteEndpoint(String filename) => "$baseUrl/resume/file/$filename";
}

