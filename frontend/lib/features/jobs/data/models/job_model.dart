class JobModel {
  final int id;
  final String title;
  final String company;
  final String location;
  final String? jobUrl;
  final String? jdText;
  final int matchScore;
  String status; // "Analyzed", "Saved", "Applied", "Interviewing", "Offer", "Rejected"
  final String source; // "JD Matcher", "JD Evaluation", "Link Import", "Pasted JD"
  final String tags;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    this.jobUrl,
    this.jdText,
    required this.matchScore,
    required this.status,
    required this.source,
    required this.tags,
    required this.createdAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Job Opportunity',
      company: json['company'] ?? 'Hiring Company',
      location: json['location'] ?? 'Remote',
      jobUrl: json['job_url'],
      jdText: json['jd_text'],
      matchScore: json['match_score'] ?? 75,
      status: json['status'] ?? 'Analyzed',
      source: json['source'] ?? 'JD Matcher',
      tags: json['tags'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'job_url': jobUrl,
      'jd_text': jdText,
      'match_score': matchScore,
      'status': status,
      'source': source,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }

  JobModel copyWith({
    int? id,
    String? title,
    String? company,
    String? location,
    String? jobUrl,
    String? jdText,
    int? matchScore,
    String? status,
    String? source,
    String? tags,
    DateTime? createdAt,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      jobUrl: jobUrl ?? this.jobUrl,
      jdText: jdText ?? this.jdText,
      matchScore: matchScore ?? this.matchScore,
      status: status ?? this.status,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

