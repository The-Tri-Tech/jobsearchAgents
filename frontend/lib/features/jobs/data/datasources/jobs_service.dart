import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillbridge_frontend/core/constants/api_constants.dart';
import 'package:skillbridge_frontend/features/jobs/data/models/job_model.dart';

class JobsService {
  static const String _localJobsKey = "local_stored_jobs";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  Future<List<JobModel>> fetchJobs() async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.jobsEndpoint);

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
        final list = (data['jobs'] as List? ?? [])
            .map((j) => JobModel.fromJson(j))
            .toList();

        // Save fresh copy locally
        _persistLocalJobs(list);
        return list;
      }
    } catch (_) {}

    // Fallback to local storage
    return _loadLocalJobs();
  }

  Future<JobModel> createJob({
    required String title,
    String? company,
    String? location,
    String? jobUrl,
    String? jdText,
    int matchScore = 78,
    String status = "Analyzed",
    String source = "Manual Link",
    String tags = "",
  }) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.jobsEndpoint);

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "company": company ?? "Hiring Company",
          "location": location ?? "Remote",
          "job_url": jobUrl,
          "jd_text": jdText,
          "match_score": matchScore,
          "status": status,
          "source": source,
          "tags": tags,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newJob = JobModel.fromJson(data);
        final current = await _loadLocalJobs();
        current.insert(0, newJob);
        await _persistLocalJobs(current);
        return newJob;
      }
    } catch (_) {}

    // Local fallback creation
    final localJob = JobModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title.trim().isEmpty ? "Tracked Job" : title.trim(),
      company: company ?? "Hiring Company",
      location: location ?? "Remote",
      jobUrl: jobUrl,
      jdText: jdText,
      matchScore: matchScore,
      status: status,
      source: source,
      tags: tags,
      createdAt: DateTime.now(),
    );
    final current = await _loadLocalJobs();
    current.insert(0, localJob);
    await _persistLocalJobs(current);
    return localJob;
  }

  Future<bool> updateJobStatus(int jobId, String newStatus) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.jobStatusEndpoint(jobId));

    try {
      await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({"status": newStatus}),
      );
    } catch (_) {}

    // Update local copy
    final current = await _loadLocalJobs();
    for (var job in current) {
      if (job.id == jobId) {
        job.status = newStatus;
        break;
      }
    }
    await _persistLocalJobs(current);
    return true;
  }

  Future<JobModel?> updateJob(
    int jobId, {
    String? title,
    String? company,
    String? location,
    String? jobUrl,
    String? jdText,
    int? matchScore,
    String? status,
  }) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.jobUpdateEndpoint(jobId));

    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          if (title != null) "title": title,
          if (company != null) "company": company,
          if (location != null) "location": location,
          if (jobUrl != null) "job_url": jobUrl,
          if (jdText != null) "jd_text": jdText,
          if (matchScore != null) "match_score": matchScore,
          if (status != null) "status": status,
        }),
      );
      if (response.statusCode == 200) {
        final updated = JobModel.fromJson(jsonDecode(response.body));
        final current = await _loadLocalJobs();
        final idx = current.indexWhere((j) => j.id == jobId);
        if (idx != -1) {
          current[idx] = updated;
          await _persistLocalJobs(current);
        }
        return updated;
      }
    } catch (_) {}

    // Fallback locally
    final current = await _loadLocalJobs();
    final idx = current.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      final old = current[idx];
      final updated = old.copyWith(
        title: title,
        company: company,
        location: location,
        jobUrl: jobUrl,
        jdText: jdText,
        matchScore: matchScore,
        status: status,
      );
      current[idx] = updated;
      await _persistLocalJobs(current);
      return updated;
    }
    return null;
  }

  Future<bool> deleteJob(int jobId) async {
    final token = await _getToken();
    final url = Uri.parse(ApiConstants.jobDeleteEndpoint(jobId));

    try {
      await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );
    } catch (_) {}

    // Delete locally
    final current = await _loadLocalJobs();
    current.removeWhere((j) => j.id == jobId);
    await _persistLocalJobs(current);
    return true;
  }

  Future<void> _persistLocalJobs(List<JobModel> jobs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jobs.map((j) => {
        "id": j.id,
        "title": j.title,
        "company": j.company,
        "location": j.location,
        "job_url": j.jobUrl,
        "jd_text": j.jdText,
        "match_score": j.matchScore,
        "status": j.status,
        "source": j.source,
        "tags": j.tags,
        "created_at": j.createdAt.toIso8601String(),
      }).toList();
      await prefs.setString(_localJobsKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<List<JobModel>> _loadLocalJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localJobsKey);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        return decoded.map((j) => JobModel.fromJson(j)).toList();
      }
    } catch (_) {}

    // Initial starter jobs if completely empty
    return [
      JobModel(
        id: 101,
        title: "Senior Full-Stack Developer",
        company: "Stripe",
        location: "Remote / Hybrid",
        jobUrl: "https://stripe.com/jobs/full-stack-engineer",
        jdText: "Looking for an experienced Full-Stack Engineer with React 19, TypeScript, and high-throughput Python / Node API services.",
        matchScore: 88,
        status: "Analyzed",
        source: "Link Import",
        tags: "React, Python, Stripe API",
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      JobModel(
        id: 102,
        title: "Python Backend & AI Engineer",
        company: "Databricks",
        location: "San Francisco / Remote",
        jobUrl: "https://databricks.com/careers/python-ai",
        jdText: "Seeking a Python Engineer to develop scalable backend services, FastAPI microservices, and AI vector data integrations.",
        matchScore: 84,
        status: "Analyzed",
        source: "JD Matcher",
        tags: "Python, FastAPI, RAG, PyTorch",
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}

