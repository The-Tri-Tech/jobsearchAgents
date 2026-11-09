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
      throw Exception(
          error['detail'] ?? 'Login failed. Please check credentials.');
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
      final today = DateTime.now();
      return DashboardOverviewModel(
        greeting: "Good morning, Student ✦",
        subtitle:
            "Your AI-powered career dashboard — track your resume, JD match evaluations, roadmap progress, and job applications.",
        user: UserModel(
            id: 1,
            email: "student@skillbridge.ai",
            fullName: "Student",
            plan: "Pro plan",
            avatarLetter: "A"),
        metrics: [
          StatCardModel(
              title: "Resumes",
              value: "1",
              actionLabel: "Upload resume",
              iconType: "document"),
          StatCardModel(
              title: "JD Match",
              value: "72%",
              actionLabel: "Analyze a JD",
              iconType: "target"),
          StatCardModel(
              title: "Jobs Tracked",
              value: "4",
              actionLabel: "Explore jobs",
              iconType: "briefcase"),
          StatCardModel(
              title: "Follow-ups",
              value: "1",
              actionLabel: "View follow-ups",
              iconType: "bell"),
        ],
        weeklyProgress: [],
        reminders: [
          ReminderModel(
            id: 1,
            title: "Follow up on apna (Associate Product Manager application)",
            category: "Application",
            dueDate: today.add(const Duration(days: 2)),
          ),
          ReminderModel(
            id: 2,
            title: "Review matched skills & keywords for Franklin Templeton",
            category: "JD Prep",
            dueDate: today.add(const Duration(days: 1)),
          ),
          ReminderModel(
            id: 3,
            title: "Update resume profile with Cloud & Docker achievements",
            category: "Resume",
            dueDate: today.add(const Duration(days: 4)),
          ),
          ReminderModel(
            id: 4,
            title: "Explore Career Roadmap Phase 1 milestone deliverables",
            category: "Roadmap",
            dueDate: today.add(const Duration(days: 6)),
          ),
        ],
        todayTasks: [
          TaskItemModel(id: 1, title: "Follow up on apna application"),
          TaskItemModel(id: 2, title: "Review matched skills for Franklin Templeton"),
          TaskItemModel(id: 3, title: "Update resume profile"),
          TaskItemModel(id: 4, title: "Explore roadmap deliverables"),
        ],
        followUps: [],
      );
    }
  }

  // Toggle Follow-up Completed
  Future<bool> toggleFollowUp(int id) async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.followUpToggleEndpoint(id));

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Delete Follow-up
  Future<bool> deleteFollowUp(int id) async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.followUpDeleteEndpoint(id));

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // Create Reminder
  Future<ReminderModel> createReminder({
    required String title,
    String category = "General",
    DateTime? dueDate,
  }) async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.dashboardRemindersEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
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

  // Toggle Reminder Completed
  Future<ReminderModel?> toggleReminder(int id) async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.reminderToggleEndpoint(id));

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return ReminderModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  // Delete Reminder
  Future<bool> deleteReminder(int id) async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.reminderDeleteEndpoint(id));

    try {
      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // Update Profile
  Future<UserModel> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? location,
    String? targetRole,
    String? bio,
  }) async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.meEndpoint);

    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (email != null) body['email'] = email;
    if (location != null) body['location'] = location;
    if (targetRole != null) body['target_role'] = targetRole;
    if (bio != null) body['bio'] = bio;

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}

    return UserModel(
      id: 1,
      email: email ?? "student@skillbridge.ai",
      fullName: fullName ?? "Student",
      plan: "Pro plan",
      avatarLetter: (fullName != null && fullName.isNotEmpty) ? fullName[0].toUpperCase() : "S",
      phoneNumber: phoneNumber ?? "+91 98765 43210",
      location: location ?? "Bengaluru, Karnataka, India",
      targetRole: targetRole ?? "Associate Product Manager",
      bio: bio ?? "Aspiring Product & Tech Professional",
    );
  }

  // Fetch Roadmap
  Future<RoadmapModel> fetchRoadmap() async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.roadmapCurrentEndpoint);

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RoadmapModel.fromJson(data);
      }
    } catch (_) {}

    // Fallback default roadmap
    return _generateLocalRoleRoadmap(
      targetRole: "Full-Stack Developer",
      experienceLevel: "Entry-to-Mid Level",
      weeklyHours: 10,
    );
  }

  // Generate Custom Roadmap
  Future<RoadmapModel> generateCustomRoadmap({
    required String targetRole,
    required String experienceLevel,
    int weeklyHours = 10,
  }) async {
    final token = await getToken();
    final url = Uri.parse(ApiConstants.roadmapGenerateEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
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

    return _generateLocalRoleRoadmap(
      targetRole: targetRole,
      experienceLevel: experienceLevel,
      weeklyHours: weeklyHours,
    );
  }

  RoadmapModel _generateLocalRoleRoadmap({
    required String targetRole,
    required String experienceLevel,
    int weeklyHours = 10,
  }) {
    final roleLower = targetRole.toLowerCase();
    final roleTitle = targetRole.trim().isEmpty ? "Full-Stack Developer" : targetRole.trim();
    final isSenior = experienceLevel.toLowerCase().contains("senior");
    final isIntern = experienceLevel.toLowerCase().contains("intern") || (experienceLevel.toLowerCase().contains("entry") && !experienceLevel.toLowerCase().contains("mid"));

    // Scale durations based on study hours
    int totalWeeks;
    String w1Weeks, w2Weeks, w3Weeks, w4Weeks;
    if (weeklyHours <= 7) {
      totalWeeks = 14;
      w1Weeks = "Weeks 1–4";
      w2Weeks = "Weeks 5–8";
      w3Weeks = "Weeks 9–11";
      w4Weeks = "Weeks 12–14";
    } else if (weeklyHours <= 14) {
      totalWeeks = 10;
      w1Weeks = "Weeks 1–3";
      w2Weeks = "Weeks 4–6";
      w3Weeks = "Weeks 7–8";
      w4Weeks = "Weeks 9–10";
    } else if (weeklyHours <= 24) {
      totalWeeks = 6;
      w1Weeks = "Weeks 1–2";
      w2Weeks = "Weeks 3–4";
      w3Weeks = "Week 5";
      w4Weeks = "Week 6";
    } else {
      totalWeeks = 4;
      w1Weeks = "Week 1";
      w2Weeks = "Week 2";
      w3Weeks = "Week 3";
      w4Weeks = "Week 4";
    }

    List<RoadmapPhaseModel> phases = [];

    // 1. Full-Stack Developer Focused (Default Role)
    if (roleLower.contains("full-stack") || roleLower.contains("full stack") || roleLower.contains("fullstack") || roleLower.contains("software engineer") || roleLower.contains("mern") || roleLower.contains("mean")) {
      if (isIntern) {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "HTML/CSS, JavaScript ES6+ & Node.js Basics",
            duration: w1Weeks,
            status: "in_progress",
            description: "Master fundamental web technologies, DOM manipulation, and basic server creation for $roleTitle.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Master JavaScript ES6+ (Async/await, array methods, closures, modules)", completed: true),
              RoadmapTaskModel(id: 102, title: "Build responsive UI components using React 19 and Tailwind CSS", completed: false),
              RoadmapTaskModel(id: 103, title: "Create RESTful API endpoints with Express / Node.js and SQLite database", completed: false),
              RoadmapTaskModel(id: 104, title: "Set up Git branching, GitHub repository workflows, and Postman testing", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Full-Stack CRUD Portfolio Capstone",
            duration: w2Weeks,
            status: "upcoming",
            description: "Build and deploy an end-to-end web application with authentication and persistent database storage.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Scaffold full-stack project (React frontend + Node/Express backend + SQLite)", completed: false),
              RoadmapTaskModel(id: 202, title: "Implement user signup, login, password hashing (bcrypt), and JWT auth", completed: false),
              RoadmapTaskModel(id: 203, title: "Deploy frontend to Vercel and backend to Render with live public URLs", completed: false),
              RoadmapTaskModel(id: 204, title: "Write clean GitHub README with setup guides, screenshots, and architecture diagrams", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "Junior Full-Stack ATS Resume & Portfolio",
            duration: w3Weeks,
            status: "upcoming",
            description: "Structure an entry-level resume showcasing deployed projects, GitHub links, and technical competencies.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Highlight full-stack capstone and live deployed links prominently on resume", completed: false),
              RoadmapTaskModel(id: 302, title: "Audit resume against Junior Full-Stack job postings to exceed 85% ATS score", completed: false),
              RoadmapTaskModel(id: 303, title: "Pin top repositories with live demo links and interactive preview GIF walkthroughs", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Junior Full-Stack Coding & Web Fundamentals",
            duration: w4Weeks,
            status: "upcoming",
            description: "Prepare for junior coding challenges, HTTP concepts, database querying, and behavioral loops.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Practice 25 fundamental coding challenges (Arrays, Strings, HashMaps, Recursion)", completed: false),
              RoadmapTaskModel(id: 402, title: "Review Web Fundamentals: HTTP status codes, CORS, cookies vs tokens, and SQL joins", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Junior Full-Stack Technical Interviews", completed: false),
            ],
          ),
        ];
      } else if (isSenior) {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "Distributed Architecture, Micro-Frontends & High Concurrency",
            duration: w1Weeks,
            status: "in_progress",
            description: "Architect scalable web applications, event-driven backends, and decoupled micro-frontends for $roleTitle.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Architect Micro-Frontends with Module Federation, Turborepo monorepos, and shared tokens", completed: true),
              RoadmapTaskModel(id: 102, title: "Design high-throughput event streaming with Kafka/RabbitMQ and Redis Cluster caching", completed: false),
              RoadmapTaskModel(id: 103, title: "Optimize Core Web Vitals (INP < 200ms, LCP < 2.5s) and database query execution plans", completed: false),
              RoadmapTaskModel(id: 104, title: "Implement multi-tenant PostgreSQL schemas with connection pooling and partitioning", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Enterprise Cloud Capstone, Kubernetes & Observability",
            duration: w2Weeks,
            status: "upcoming",
            description: "Architect and deploy an enterprise multi-tier cloud application with automated CI/CD and monitoring.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Containerize microservices with multi-stage Dockerfiles and Helm Kubernetes charts", completed: false),
              RoadmapTaskModel(id: 202, title: "Implement OpenTelemetry distributed tracing, Prometheus metrics, and Grafana alerts", completed: false),
              RoadmapTaskModel(id: 203, title: "Automate zero-downtime blue-green CI/CD deployment pipelines with GitHub Actions", completed: false),
              RoadmapTaskModel(id: 204, title: "Establish automated test automation across unit, integration, and Playwright E2E suites", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "Executive ATS Resume & Architectural Impact",
            duration: w3Weeks,
            status: "upcoming",
            description: "Position your resume for Senior/Staff/Lead Full-Stack roles with high-scale business metrics.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Quantify scale metrics: 99.99% availability, 10M+ daily requests, and infrastructure cost cuts", completed: false),
              RoadmapTaskModel(id: 302, title: "Audit resume against Staff / Principal Full-Stack Engineer and Lead Architect roles", completed: false),
              RoadmapTaskModel(id: 303, title: "Publish Technical RFC / Architecture whitepaper detailing trade-offs and disaster recovery", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Large-Scale System Design & Engineering Leadership",
            duration: w4Weeks,
            status: "upcoming",
            description: "Master distributed systems, consensus protocols, database sharding, and engineering leadership.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Master Staff System Design: Global CDNs, CAP theorem, database sharding, and consensus protocols", completed: false),
              RoadmapTaskModel(id: 402, title: "Prepare for engineering leadership loops: Architecture trade-offs, mentorship, and sprint governance", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Senior System Design and Engineering Leadership interviews", completed: false),
            ],
          ),
        ];
      } else {
        // Entry-to-Mid Level Full-Stack
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "Modern React 19, TypeScript & Production APIs",
            duration: w1Weeks,
            status: "in_progress",
            description: "Solidify end-to-end full-stack development with strict TypeScript, modern React, and clean API design.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Master strict TypeScript across React components, state stores, and backend models", completed: true),
              RoadmapTaskModel(id: 102, title: "Build production RESTful APIs with FastAPI or Express, input validation, and middleware", completed: false),
              RoadmapTaskModel(id: 103, title: "Design normalized PostgreSQL schemas with migrations, indexes, and connection pooling", completed: false),
              RoadmapTaskModel(id: 104, title: "Implement efficient client caching and server state with React Query / TanStack Query", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Production Full-Stack SaaS Capstone & Docker",
            duration: w2Weeks,
            status: "upcoming",
            description: "Build and deploy a complete production-ready full-stack web application with authentication and containerization.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Build full-stack app with Next.js App Router, SSR, and decoupled backend services", completed: false),
              RoadmapTaskModel(id: 202, title: "Implement secure JWT / OAuth2 authentication with role-based access control (RBAC)", completed: false),
              RoadmapTaskModel(id: 203, title: "Write production Dockerfile and Docker Compose multi-container setup (Web + API + DB)", completed: false),
              RoadmapTaskModel(id: 204, title: "Deploy to cloud (Render / AWS) with automated GitHub Actions CI/CD workflows", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "ATS Resume Optimization & Quantified Impact",
            duration: w3Weeks,
            status: "upcoming",
            description: "Highlight technical achievements, deployed links, and business value metrics on your resume.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Quantify full-stack accomplishments: Page speedups, API throughput, and active user metrics", completed: false),
              RoadmapTaskModel(id: 302, title: "Tailor resume keywords to match Mid-Level Full-Stack and Software Engineer descriptions", completed: false),
              RoadmapTaskModel(id: 303, title: "Publish clean GitHub repository with architecture diagrams and API documentation", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Full-Stack System Design & Live Coding",
            duration: w4Weeks,
            status: "upcoming",
            description: "Prepare for full-stack system design, real-time coding rounds, and behavioral evaluations.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Master Full-Stack System Design: Client-server architecture, caching layers, and database indexing", completed: false),
              RoadmapTaskModel(id: 402, title: "Practice live coding rounds: Data structures, asynchronous handlers, and UI state sync", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Technical Interviews with real-time feedback", completed: false),
            ],
          ),
        ];
      }
    }
    // 2. Python / Backend
    else if (roleLower.contains("python") || roleLower.contains("backend") || roleLower.contains("django") || roleLower.contains("fastapi") || roleLower.contains("flask")) {
      if (isIntern) {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "Python Syntax, OOP & Core Data Structures",
            duration: w1Weeks,
            status: "in_progress",
            description: "Master Python 3 fundamentals, object-oriented programming, and essential data structures.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Master Python data types, list comprehensions, and dictionaries", completed: true),
              RoadmapTaskModel(id: 102, title: "Understand OOP concepts: Classes, inheritance, and magic methods", completed: false),
              RoadmapTaskModel(id: 103, title: "Practice Git workflow, branching, and virtual environments (venv)", completed: false),
              RoadmapTaskModel(id: 104, title: "Build first REST API using FastAPI with SQLite database", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Guided Portfolio Capstone & Pytest",
            duration: w2Weeks,
            status: "upcoming",
            description: "Build an end-to-end CRUD project with automated testing to prove your abilities.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Scaffold $roleTitle portfolio project with clean modular structure", completed: false),
              RoadmapTaskModel(id: 202, title: "Write Pytest unit tests for all API endpoints and validation logic", completed: false),
              RoadmapTaskModel(id: 203, title: "Deploy API to Render / Railway with live Swagger documentation", completed: false),
              RoadmapTaskModel(id: 204, title: "Write beginner-friendly GitHub README with architecture diagrams", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "Entry-Level ATS Resume & GitHub Showcase",
            duration: w3Weeks,
            status: "upcoming",
            description: "Structure an entry-level resume emphasizing coursework, personal projects, and core CS skills.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Highlight personal projects and core CS competencies on resume", completed: false),
              RoadmapTaskModel(id: 302, title: "Audit resume against Junior Python postings to achieve 85+ ATS score", completed: false),
              RoadmapTaskModel(id: 303, title: "Pin 3 clean GitHub repositories with live links and demo GIFs", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Junior Coding Rounds & Core CS Prep",
            duration: w4Weeks,
            status: "upcoming",
            description: "Ace foundational algorithmic questions, basic SQL queries, and entry interview loops.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Practice 25 LeetCode Easy problems (Arrays, Strings, HashMaps)", completed: false),
              RoadmapTaskModel(id: 402, title: "Review CS concepts: Big-O notation, HTTP status codes, and SQL joins", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Junior Technical Interviews", completed: false),
            ],
          ),
        ];
      } else if (isSenior) {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "High-Concurrency AsyncIO & Distributed Systems",
            duration: w1Weeks,
            status: "in_progress",
            description: "Master Python GIL internals, event loops, high-throughput microservices, and distributed state.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Analyze Python GIL limitations, AsyncIO event loop internals, and uvloop", completed: true),
              RoadmapTaskModel(id: 102, title: "Architect microservices with FastAPI, gRPC communication, and Pydantic v2", completed: false),
              RoadmapTaskModel(id: 103, title: "Optimize PostgreSQL with partition schemas, indexing, and PgBouncer pooling", completed: false),
              RoadmapTaskModel(id: 104, title: "Design distributed caching (Redis Cluster) and streaming queues with Kafka/Celery", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Enterprise Cloud Architecture & Observability",
            duration: w2Weeks,
            status: "upcoming",
            description: "Architect a resilient, multi-tenant enterprise backend with zero-downtime deployment.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Implement distributed resilience: Circuit breakers, rate-limiting & idempotency", completed: false),
              RoadmapTaskModel(id: 202, title: "Write production Kubernetes manifests, Helm charts, and multi-stage Dockerfiles", completed: false),
              RoadmapTaskModel(id: 203, title: "Integrate OpenTelemetry distributed tracing, Prometheus metrics, and Grafana", completed: false),
              RoadmapTaskModel(id: 204, title: "Automate blue-green CI/CD deployment pipelines with zero downtime", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "Senior/Staff ATS Resume & Business Impact",
            duration: w3Weeks,
            status: "upcoming",
            description: "Position resume for Senior/Staff roles with metrics on throughput, latency, and engineering leadership.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Quantify architectural achievements: Throughput, 99.9% SLAs, and cloud cost cuts", completed: false),
              RoadmapTaskModel(id: 302, title: "Audit resume against Staff / Senior Python Backend recruiter benchmarks", completed: false),
              RoadmapTaskModel(id: 303, title: "Draft high-level System Architecture RFC document as a portfolio centerpiece", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Large-Scale System Design & Leadership Loops",
            duration: w4Weeks,
            status: "upcoming",
            description: "Master distributed system trade-offs, fault tolerance, and cross-functional engineering leadership.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Master System Design: Sharding, CAP theorem, consensus, and event sourcing", completed: false),
              RoadmapTaskModel(id: 402, title: "Prepare for Staff-level trade-off debates, technical deep dives, and post-mortems", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Senior System Design and Leadership interviews", completed: false),
            ],
          ),
        ];
      } else {
        // Entry-to-Mid
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "Advanced Python & Production Backend APIs",
            duration: w1Weeks,
            status: "in_progress",
            description: "Deep-dive into async Python, API design, relational data modeling, and caching for $roleTitle.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Master Python AsyncIO, type hints, generators, and context managers", completed: true),
              RoadmapTaskModel(id: 102, title: "Build scalable REST APIs using FastAPI with dependency injection and middleware", completed: false),
              RoadmapTaskModel(id: 103, title: "Optimize PostgreSQL queries, indexes, connection pooling, and migrations", completed: false),
              RoadmapTaskModel(id: 104, title: "Implement Redis caching and background task workers with Celery", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Microservices & Containerized Capstone",
            duration: w2Weeks,
            status: "upcoming",
            description: "Architect and containerize an enterprise-ready backend system for your portfolio.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Scaffold $roleTitle API service with automated Pytest test suite", completed: false),
              RoadmapTaskModel(id: 202, title: "Write production Dockerfile and Docker Compose multi-service setup", completed: false),
              RoadmapTaskModel(id: 203, title: "Integrate OAuth2 / JWT authentication with role-based permissions (RBAC)", completed: false),
              RoadmapTaskModel(id: 204, title: "Deploy service to cloud (AWS ECS / Render) with health-check monitoring", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "ATS Resume & Backend Profile Polish",
            duration: w3Weeks,
            status: "upcoming",
            description: "Tailor resume to pass backend ATS screening and showcase system design knowledge.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Highlight throughput, latency reductions, and DB benchmarks on resume", completed: false),
              RoadmapTaskModel(id: 302, title: "Scan resume against live Python Backend job descriptions to hit 85+ match", completed: false),
              RoadmapTaskModel(id: 303, title: "Publish clean GitHub repo with architecture diagrams and Swagger documentation", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "System Design & Technical Interviews",
            duration: w4Weeks,
            status: "upcoming",
            description: "Master Python data structures, algorithms, and backend system design interview loops.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Practice 15 core Backend coding challenges (Trees, Graphs, Hashing)", completed: false),
              RoadmapTaskModel(id: 402, title: "Review System Design: Load balancers, caching strategies, and database sharding", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Backend Technical Interviews", completed: false),
            ],
          ),
        ];
      }
    }
    // 2. Frontend / React / Web
    else if (roleLower.contains("react") || roleLower.contains("frontend") || roleLower.contains("web") || roleLower.contains("vue") || roleLower.contains("angular") || roleLower.contains("next")) {
      if (isIntern) {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "HTML5, Modern CSS & JavaScript ES6+",
            duration: w1Weeks,
            status: "in_progress",
            description: "Master modern semantic HTML, Flexbox/Grid layouts, and essential JavaScript programming.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Master CSS Flexbox, Grid, responsive design, and CSS variables", completed: true),
              RoadmapTaskModel(id: 102, title: "Master JavaScript ES6+: Promises, async/await, closures, and DOM manipulation", completed: false),
              RoadmapTaskModel(id: 103, title: "Build first component-driven UI using React and Tailwind CSS", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Interactive React Portfolio Capstone",
            duration: w2Weeks,
            status: "upcoming",
            description: "Build an interactive, fully responsive single-page application connected to a public API.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Build React app with hooks (useState, useEffect, useMemo) and React Router", completed: false),
              RoadmapTaskModel(id: 202, title: "Handle API data fetching, loading spinners, and error boundaries", completed: false),
              RoadmapTaskModel(id: 203, title: "Deploy live website to Vercel / Netlify with custom domain", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "Entry Frontend Resume & Web Portfolio",
            duration: w3Weeks,
            status: "upcoming",
            description: "Showcase deployed live web apps, GitHub source code, and responsive design skills.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Feature live demo links and GitHub repositories prominently on resume", completed: false),
              RoadmapTaskModel(id: 302, title: "Run ATS check against Junior Frontend postings to achieve 85+ score", completed: false),
              RoadmapTaskModel(id: 303, title: "Test responsive UI on mobile, tablet, and desktop viewport sizes", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "JavaScript & UI Coding Rounds",
            duration: w4Weeks,
            status: "upcoming",
            description: "Crack JavaScript conceptual interviews, DOM manipulation exercises, and entry UI challenges.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Practice JS coding questions: Debounce, throttle, deep clone, and event bubbling", completed: false),
              RoadmapTaskModel(id: 402, title: "Review Web Fundamentals: CORS, cookies, local storage, and rendering cycle", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Junior Frontend Interviews", completed: false),
            ],
          ),
        ];
      } else if (isSenior) {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "Advanced TypeScript, Architecture & Web Vitals",
            duration: w1Weeks,
            status: "in_progress",
            description: "Master strict TypeScript, compiler performance, micro-frontend architecture, and Core Web Vitals.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Master advanced TypeScript: Conditional types, template literals, and AST transforms", completed: true),
              RoadmapTaskModel(id: 102, title: "Architect large-scale micro-frontends with Module Federation and monorepos (Turborepo)", completed: false),
              RoadmapTaskModel(id: 103, title: "Optimize Core Web Vitals (INP, LCP, CLS) to sub-second thresholds", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Enterprise Next.js SSR & Design System",
            duration: w2Weeks,
            status: "upcoming",
            description: "Build an accessible, WCAG-compliant design system and enterprise full-stack Next.js app.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Architect full-stack Next.js with Server Components, streaming, and Server Actions", completed: false),
              RoadmapTaskModel(id: 202, title: "Build accessible Design System with Storybook, Radix primitives, and tokens", completed: false),
              RoadmapTaskModel(id: 203, title: "Implement automated visual regression and E2E testing with Playwright", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "Senior ATS Resume & Technical Leadership",
            duration: w3Weeks,
            status: "upcoming",
            description: "Emphasize frontend performance gains, user conversion impact, and design system governance.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Quantify conversion rate improvements, bundle size reductions, and performance wins", completed: false),
              RoadmapTaskModel(id: 302, title: "Optimize resume for Staff / Principal Frontend and UI Architect roles", completed: false),
              RoadmapTaskModel(id: 303, title: "Publish open-source UI package or technical blog post on architecture patterns", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Frontend System Design & Architecture Loops",
            duration: w4Weeks,
            status: "upcoming",
            description: "Ace complex frontend architecture interviews, offline-first sync, and large-scale rendering.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Master Frontend System Design (Google Docs collaborative editor, Infinite feed)", completed: false),
              RoadmapTaskModel(id: 402, title: "Prepare for cross-functional design system reviews and architecture defense", completed: false),
              RoadmapTaskModel(id: 403, title: "Conduct 2 AI Mock Senior Frontend Architecture interviews", completed: false),
            ],
          ),
        ];
      } else {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "Modern TypeScript & State Architecture",
            duration: w1Weeks,
            status: "in_progress",
            description: "Solidify core web performance, modern React patterns, and strict TypeScript patterns.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Master TypeScript generics, utility types, and strict mode", completed: true),
              RoadmapTaskModel(id: 102, title: "Implement efficient client state with Zustand or Redux Toolkit", completed: false),
              RoadmapTaskModel(id: 103, title: "Optimize Web Vitals (LCP, CLS, FID) with bundle splitting and memoization", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Interactive Full-Stack Web Capstone",
            duration: w2Weeks,
            status: "upcoming",
            description: "Build a polished, highly responsive web application with Next.js and Tailwind CSS.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Build responsive app with Next.js App Router, SSR, and Server Actions", completed: false),
              RoadmapTaskModel(id: 202, title: "Design clean accessible UI using Tailwind CSS and Radix UI components", completed: false),
              RoadmapTaskModel(id: 203, title: "Add end-to-end testing with Playwright or Cypress", completed: false),
              RoadmapTaskModel(id: 204, title: "Deploy to Vercel with automated CI/CD and preview environments", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "ATS Resume & Portfolio Polish",
            duration: w3Weeks,
            status: "upcoming",
            description: "Showcase interactive web demos and performance scores to hiring teams.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Add live demo links and interactive previews directly to ATS resume", completed: false),
              RoadmapTaskModel(id: 302, title: "Run ATS keyword audit matching Frontend / React senior positions", completed: false),
              RoadmapTaskModel(id: 303, title: "Curate GitHub profile with clean READMEs, screenshots, and live links", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Frontend Coding & UI System Design",
            duration: w4Weeks,
            status: "upcoming",
            description: "Crack frontend coding rounds, DOM manipulation, and frontend architecture questions.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Practice UI machine coding questions (Virtual list, Autocomplete, Debounce)", completed: false),
              RoadmapTaskModel(id: 402, title: "Review Frontend System Design: Micro-frontends, caching, and CDN delivery", completed: false),
              RoadmapTaskModel(id: 403, title: "Conduct 2 AI Mock Frontend Interviews with instant code feedback", completed: false),
            ],
          ),
        ];
      }
    }
    // 3. Mobile / Flutter / Android / iOS
    else if (roleLower.contains("flutter") || roleLower.contains("mobile") || roleLower.contains("android") || roleLower.contains("ios") || roleLower.contains("dart")) {
      if (isSenior) {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "Advanced Mobile Architecture & Native Platform Channels",
            duration: w1Weeks,
            status: "in_progress",
            description: "Master multi-isolate concurrency, custom render trees, memory profiling, and native interop.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Deep-dive into Dart isolate pools, memory leaks, and DevTools allocation profiles", completed: true),
              RoadmapTaskModel(id: 102, title: "Architect Clean Architecture + Feature-First state management (BLoC / Riverpod)", completed: false),
              RoadmapTaskModel(id: 103, title: "Write custom Platform Channels / FFI bridge to native Kotlin & Swift APIs", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Enterprise Offline Sync & Multi-Store Release",
            duration: w2Weeks,
            status: "upcoming",
            description: "Build an offline-first enterprise app with delta syncing and automated CI/CD release pipelines.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Implement conflict-free offline data sync using SQLite/Drift with websocket delta push", completed: false),
              RoadmapTaskModel(id: 202, title: "Automate Fastlane builds, signed APKs/IPAs, and internal test tracks", completed: false),
              RoadmapTaskModel(id: 203, title: "Establish 85%+ test coverage across unit, widget, and integration tests", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "Senior ATS Resume & Published App Showcase",
            duration: w3Weeks,
            status: "upcoming",
            description: "Highlight published apps, crash-free user sessions (99.8%+), and app startup benchmarks.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Emphasize app store metrics: 100k+ downloads, 60fps frame stability, and crash-free rates", completed: false),
              RoadmapTaskModel(id: 302, title: "Tailor resume to hit 90+ ATS score for Senior Mobile / Lead Flutter roles", completed: false),
              RoadmapTaskModel(id: 303, title: "Publish open-source Flutter package with golden widget tests", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Mobile System Design & Technical Interviews",
            duration: w4Weeks,
            status: "upcoming",
            description: "Master complex mobile system design: Offline sync, image caching pipelines, and platform channels.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Solve Mobile System Design: Offline messaging client, background geolocation, battery optimization", completed: false),
              RoadmapTaskModel(id: 402, title: "Prepare for senior concurrency questions, render pipeline, and memory management", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Senior Mobile Technical Interviews", completed: false),
            ],
          ),
        ];
      } else {
        phases = [
          RoadmapPhaseModel(
            id: 1,
            phaseNumber: 1,
            title: "Flutter Architecture & Dart Deep-Dive",
            duration: w1Weeks,
            status: "in_progress",
            description: "Master reactive state management, asynchronous Dart, and clean mobile architecture.",
            tasks: [
              RoadmapTaskModel(id: 101, title: "Deep-dive into Dart Streams, isolates, and reactive programming", completed: true),
              RoadmapTaskModel(id: 102, title: "Implement scalable state management using BLoC or Riverpod", completed: false),
              RoadmapTaskModel(id: 103, title: "Build custom render objects, slivers, and complex animations", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 2,
            phaseNumber: 2,
            title: "Cross-Platform Production Capstone",
            duration: w2Weeks,
            status: "upcoming",
            description: "Build an offline-first, production-grade mobile app with secure local storage.",
            tasks: [
              RoadmapTaskModel(id: 201, title: "Architect offline sync using SQLite / Hive with REST API fallback", completed: false),
              RoadmapTaskModel(id: 202, title: "Implement push notifications, biometric auth, and deep linking", completed: false),
              RoadmapTaskModel(id: 203, title: "Write unit, widget, and integration tests to hit 80%+ coverage", completed: false),
              RoadmapTaskModel(id: 204, title: "Configure fastlane and automated release pipelines for Android & iOS", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 3,
            phaseNumber: 3,
            title: "ATS Resume & App Store Showcasing",
            duration: w3Weeks,
            status: "upcoming",
            description: "Present published apps, APK/TestFlight links, and mobile engineering achievements.",
            tasks: [
              RoadmapTaskModel(id: 301, title: "Feature published Google Play / App Store links prominently on resume", completed: false),
              RoadmapTaskModel(id: 302, title: "Scan resume against Flutter / Mobile Developer job descriptions", completed: false),
              RoadmapTaskModel(id: 303, title: "Record a 60-second video walkthrough of your mobile app capstone", completed: false),
            ],
          ),
          RoadmapPhaseModel(
            id: 4,
            phaseNumber: 4,
            title: "Mobile System Design & Technical Interviews",
            duration: w4Weeks,
            status: "upcoming",
            description: "Ace mobile-specific design questions, memory management, and platform channels.",
            tasks: [
              RoadmapTaskModel(id: 401, title: "Practice mobile system design (Offline sync, Image caching, Battery efficiency)", completed: false),
              RoadmapTaskModel(id: 402, title: "Master Dart/Flutter concurrency, memory profiling, and frame drop fixes", completed: false),
              RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Mobile Developer Technical Interviews", completed: false),
            ],
          ),
        ];
      }
    }
    // 4. Data / AI / Machine Learning
    else if (roleLower.contains("data") || roleLower.contains("ai") || roleLower.contains("machine learning") || roleLower.contains("ml") || roleLower.contains("llm")) {
      phases = [
        RoadmapPhaseModel(
          id: 1,
          phaseNumber: 1,
          title: isSenior ? "Scalable Data Pipelines & Vector Architectures" : "Data Pipelines & Python Foundations",
          duration: w1Weeks,
          status: "in_progress",
          description: isSenior
              ? "Architect large-scale feature stores, vector embeddings, and real-time streaming architectures."
              : "Build a rock-solid foundation in data structures, SQL transformations, and modern data processing.",
          tasks: [
            RoadmapTaskModel(id: 101, title: "Master vectorised data manipulation with NumPy and Pandas", completed: true),
            RoadmapTaskModel(id: 102, title: "Write advanced SQL queries (Window functions, CTEs, indexing)", completed: false),
            RoadmapTaskModel(id: 103, title: "Build an automated ETL pipeline with schema validation", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 2,
          phaseNumber: 2,
          title: isSenior ? "Production LLM / RAG System & Model Governance" : "AI / ML & GenAI Capstone System",
          duration: w2Weeks,
          status: "upcoming",
          description: "Build an end-to-end Machine Learning / RAG application with vector search and evaluation.",
          tasks: [
            RoadmapTaskModel(id: 201, title: "Implement a RAG system using LangChain / LlamaIndex and a Vector DB", completed: false),
            RoadmapTaskModel(id: 202, title: "Fine-tune or evaluate models using custom metrics and validation sets", completed: false),
            RoadmapTaskModel(id: 203, title: "Deploy inference endpoint with FastAPI and Docker containerization", completed: false),
            RoadmapTaskModel(id: 204, title: "Integrate model latency monitoring and prompt evaluation pipeline", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 3,
          phaseNumber: 3,
          title: isSenior ? "Senior AI/ML Resume & Business ROI Showcase" : "ATS Resume & AI Portfolio Polish",
          duration: w3Weeks,
          status: "upcoming",
          description: "Highlight model performance, dataset sizes, and business impact for recruiters.",
          tasks: [
            RoadmapTaskModel(id: 301, title: "Quantify metrics (accuracy gains, inference latency, cost reductions) on resume", completed: false),
            RoadmapTaskModel(id: 302, title: "Align resume keywords with AI/ML job requirements to exceed 85% ATS score", completed: false),
            RoadmapTaskModel(id: 303, title: "Publish interactive HuggingFace Space or Streamlit demo with clean GitHub repo", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 4,
          phaseNumber: 4,
          title: isSenior ? "Enterprise ML System Design & AI Governance" : "ML System Design & Coding Loops",
          duration: w4Weeks,
          status: "upcoming",
          description: "Prepare for data structure rounds, ML theory questions, and large-scale ML system design.",
          tasks: [
            RoadmapTaskModel(id: 401, title: "Review ML System Design: Recommendation engines, vector retrieval, and feature stores", completed: false),
            RoadmapTaskModel(id: 402, title: "Practice data-oriented coding challenges and algorithm problems", completed: false),
            RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock Technical Interviews tailored to Data/AI roles", completed: false),
          ],
        ),
      ];
    }
    // 5. DevOps / Cloud / SRE
    else if (roleLower.contains("devops") || roleLower.contains("cloud") || roleLower.contains("sre") || roleLower.contains("kubernetes") || roleLower.contains("aws")) {
      phases = [
        RoadmapPhaseModel(
          id: 1,
          phaseNumber: 1,
          title: "Infrastructure as Code & Cloud Foundations",
          duration: w1Weeks,
          status: "in_progress",
          description: "Master Terraform, cloud networking (VPC, subnets), IAM policies, and Linux administration.",
          tasks: [
            RoadmapTaskModel(id: 101, title: "Write declarative multi-tier cloud infrastructure with Terraform / OpenTofu", completed: true),
            RoadmapTaskModel(id: 102, title: "Configure secure cloud networking: VPC peering, NAT gateways, and security groups", completed: false),
            RoadmapTaskModel(id: 103, title: "Automate Linux server hardening, SSH key rotation, and systemd services", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 2,
          phaseNumber: 2,
          title: "Kubernetes, CI/CD & Production GitOps",
          duration: w2Weeks,
          status: "upcoming",
          description: "Build an enterprise CI/CD pipeline and automated GitOps deployment on Kubernetes.",
          tasks: [
            RoadmapTaskModel(id: 201, title: "Deploy production Kubernetes cluster (EKS/GKE) with Helm and Ingress-NGINX", completed: false),
            RoadmapTaskModel(id: 202, title: "Build automated GitHub Actions CI/CD pipeline with Docker security scanning", completed: false),
            RoadmapTaskModel(id: 203, title: "Set up ArgoCD for automated declarative GitOps continuous synchronization", completed: false),
            RoadmapTaskModel(id: 204, title: "Deploy Prometheus, Grafana, and AlertManager for 24/7 cluster monitoring", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 3,
          phaseNumber: 3,
          title: "DevOps ATS Resume & Uptime Portfolio",
          duration: w3Weeks,
          status: "upcoming",
          description: "Showcase 99.99% uptime achievements, infrastructure cost optimizations, and automation metrics.",
          tasks: [
            RoadmapTaskModel(id: 301, title: "Quantify MTTR reductions, deployment frequency gains, and cloud bill savings on resume", completed: false),
            RoadmapTaskModel(id: 302, title: "Scan resume against Senior Cloud/DevOps listings to achieve 88+ ATS score", completed: false),
            RoadmapTaskModel(id: 303, title: "Publish GitHub repo with modular Terraform templates and CI/CD workflows", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 4,
          phaseNumber: 4,
          title: "Site Reliability System Design & Incident Loops",
          duration: w4Weeks,
          status: "upcoming",
          description: "Master disaster recovery, high-availability architecture, and incident management interviews.",
          tasks: [
            RoadmapTaskModel(id: 401, title: "Practice Infrastructure System Design: Multi-region failover, DDoS mitigation, DNS routing", completed: false),
            RoadmapTaskModel(id: 402, title: "Run simulated incident troubleshooting drills and write detailed post-mortems", completed: false),
            RoadmapTaskModel(id: 403, title: "Complete 2 AI Mock DevOps / SRE Technical Interviews", completed: false),
          ],
        ),
      ];
    }
    // 6. General / Custom role (Fully level-adaptive)
    else {
      phases = [
        RoadmapPhaseModel(
          id: 1,
          phaseNumber: 1,
          title: isSenior ? "Advanced $roleTitle Architecture & Patterns" : (isIntern ? "$roleTitle Fundamentals & Tooling Setup" : "$roleTitle Core Foundations & Architecture"),
          duration: w1Weeks,
          status: "in_progress",
          description: isSenior
              ? "Master high-level architectural patterns, scalability tradeoffs, and senior workflows for $roleTitle."
              : (isIntern ? "Build rock-solid baseline fundamentals, developer tooling, and essential concepts for $roleTitle." : "Master fundamental skills, key tools, and architectural patterns demanded for $roleTitle positions."),
          tasks: [
            RoadmapTaskModel(id: 101, title: "Audit key technical competencies and industry best practices for $roleTitle", completed: true),
            RoadmapTaskModel(id: 102, title: isSenior ? "Design scalable component architecture and modular system boundaries" : "Set up professional developer workflow, tooling, and version control", completed: false),
            RoadmapTaskModel(id: 103, title: "Complete adaptive technical assessment to validate $roleTitle core concepts", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 2,
          phaseNumber: 2,
          title: isSenior ? "Enterprise $roleTitle Scalability Capstone" : "$roleTitle Production Capstone Project",
          duration: w2Weeks,
          status: "upcoming",
          description: "Build a standout project that proves your hands-on ability to hiring managers.",
          tasks: [
            RoadmapTaskModel(id: 201, title: "Architect and build an end-to-end $roleTitle capstone project", completed: false),
            RoadmapTaskModel(id: 202, title: "Implement unit tests, error handling, and robust documentation", completed: false),
            RoadmapTaskModel(id: 203, title: "Deploy live demo and write a comprehensive GitHub README", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 3,
          phaseNumber: 3,
          title: isSenior ? "Executive ATS Resume & Leadership Impact" : "ATS Resume & $roleTitle Branding",
          duration: w3Weeks,
          status: "upcoming",
          description: "Tailor your resume and profiles specifically for $roleTitle recruiters.",
          tasks: [
            RoadmapTaskModel(id: 301, title: "Run ATS analysis against 3 live $roleTitle job descriptions", completed: false),
            RoadmapTaskModel(id: 302, title: "Rewrite resume bullet points to emphasize quantifiable business results", completed: false),
            RoadmapTaskModel(id: 303, title: "Optimize LinkedIn headline and portfolio links for target recruiters", completed: false),
          ],
        ),
        RoadmapPhaseModel(
          id: 4,
          phaseNumber: 4,
          title: isSenior ? "Senior System Design & Leadership Interview Prep" : "$roleTitle Interview Prep & Applications",
          duration: w4Weeks,
          status: "upcoming",
          description: "Convert job applications into offers through structured interview practice.",
          tasks: [
            RoadmapTaskModel(id: 401, title: "Review top 25 technical & conceptual interview questions for this role", completed: false),
            RoadmapTaskModel(id: 402, title: "Complete 2 AI-guided Mock Technical Interviews", completed: false),
            RoadmapTaskModel(id: 403, title: "Submit 5 targeted job applications weekly and follow up", completed: false),
          ],
        ),
      ];
    }

    final allTasks = phases.expand((p) => p.tasks).toList();
    final completedCount = allTasks.where((t) => t.completed).length;
    final progressPct = allTasks.isNotEmpty ? ((completedCount / allTasks.length) * 100).round() : 0;

    return RoadmapModel(
      targetRole: roleTitle,
      experienceLevel: experienceLevel,
      overallProgress: progressPct,
      estimatedWeeks: totalWeeks,
      phases: phases,
    );
  }
}
