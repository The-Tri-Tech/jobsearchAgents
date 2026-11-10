class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String plan;
  final String avatarLetter;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.plan,
    required this.avatarLetter,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? 'Student',
      plan: json['plan'] ?? 'Pro plan',
      avatarLetter: json['avatar_letter'] ?? 'A',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'plan': plan,
    'avatar_letter': avatarLetter,
  };
}

class StatCardModel {
  final String title;
  final String value;
  final String actionLabel;
  final String iconType;

  StatCardModel({
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.iconType,
  });

  factory StatCardModel.fromJson(Map<String, dynamic> json) {
    return StatCardModel(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      actionLabel: json['action_label'] ?? '',
      iconType: json['icon_type'] ?? '',
    );
  }
}

class ProgressItemModel {
  final String label;
  final String status;

  ProgressItemModel({required this.label, required this.status});

  factory ProgressItemModel.fromJson(Map<String, dynamic> json) {
    return ProgressItemModel(
      label: json['label'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class TaskItemModel {
  final int id;
  final String title;
  bool completed;

  TaskItemModel({
    required this.id,
    required this.title,
    this.completed = false,
  });

  factory TaskItemModel.fromJson(Map<String, dynamic> json) {
    return TaskItemModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
    );
  }
}

class DashboardOverviewModel {
  final String greeting;
  final String subtitle;
  final UserModel user;
  final List<StatCardModel> metrics;
  final List<ProgressItemModel> weeklyProgress;
  final List<TaskItemModel> todayTasks;
  final List<FollowUpModel> followUps;
  final List<ReminderModel> reminders;

  DashboardOverviewModel({
    required this.greeting,
    required this.subtitle,
    required this.user,
    required this.metrics,
    required this.weeklyProgress,
    required this.todayTasks,
    this.followUps = const [],
    this.reminders = const [],
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewModel(
      greeting: json['greeting'] ?? '',
      subtitle: json['subtitle'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      metrics: (json['metrics'] as List? ?? [])
          .map((m) => StatCardModel.fromJson(m))
          .toList(),
      weeklyProgress: (json['weekly_progress'] as List? ?? [])
          .map((p) => ProgressItemModel.fromJson(p))
          .toList(),
      todayTasks: (json['today_tasks'] as List? ?? [])
          .map((t) => TaskItemModel.fromJson(t))
          .toList(),
      followUps: (json['follow_ups'] as List? ?? [])
          .map((f) => FollowUpModel.fromJson(f))
          .toList(),
      reminders: (json['reminders'] as List? ?? [])
          .map((r) => ReminderModel.fromJson(r))
          .toList(),
    );
  }
}

class ReminderModel {
  final int id;
  final String title;
  final String category;
  final DateTime? dueDate;
  bool completed;

  ReminderModel({
    required this.id,
    required this.title,
    required this.category,
    this.dueDate,
    this.completed = false,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        category: json['category'] ?? 'General',
        dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
        completed: json['completed'] ?? false,
      );
}

class FollowUpModel {
  final int id;
  final String reportTitle;
  final String resumeFilename;
  final DateTime applicationDate;
  final int followUpAfterDays;
  final DateTime followUpDate;
  final String status;

  FollowUpModel({
    required this.id,
    required this.reportTitle,
    required this.resumeFilename,
    required this.applicationDate,
    required this.followUpAfterDays,
    required this.followUpDate,
    required this.status,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) => FollowUpModel(
        id: json['id'] ?? 0,
        reportTitle: json['report_title'] ?? 'Job match follow-up',
        resumeFilename: json['resume_filename'] ?? '',
        applicationDate: DateTime.tryParse(json['application_date'] ?? '') ?? DateTime.now(),
        followUpAfterDays: json['follow_up_after_days'] ?? 0,
        followUpDate: DateTime.tryParse(json['follow_up_date'] ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'pending',
      );
}

class RoadmapTaskModel {
  final int id;
  final String title;
  bool completed;
  final String? resourceLink;

  RoadmapTaskModel({
    required this.id,
    required this.title,
    this.completed = false,
    this.resourceLink,
  });

  factory RoadmapTaskModel.fromJson(Map<String, dynamic> json) => RoadmapTaskModel(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        completed: json['completed'] ?? false,
        resourceLink: json['resource_link'],
      );
}

class RoadmapPhaseModel {
  final int id;
  final int phaseNumber;
  final String title;
  final String duration;
  final String status;
  final String description;
  final List<RoadmapTaskModel> tasks;

  RoadmapPhaseModel({
    required this.id,
    required this.phaseNumber,
    required this.title,
    required this.duration,
    required this.status,
    required this.description,
    required this.tasks,
  });

  factory RoadmapPhaseModel.fromJson(Map<String, dynamic> json) => RoadmapPhaseModel(
        id: json['id'] ?? 0,
        phaseNumber: json['phase_number'] ?? 1,
        title: json['title'] ?? '',
        duration: json['duration'] ?? '',
        status: json['status'] ?? 'upcoming',
        description: json['description'] ?? '',
        tasks: (json['tasks'] as List? ?? [])
            .map((t) => RoadmapTaskModel.fromJson(t))
            .toList(),
      );
}

class RoadmapModel {
  final String targetRole;
  final String experienceLevel;
  int overallProgress;
  final int estimatedWeeks;
  final List<RoadmapPhaseModel> phases;

  RoadmapModel({
    required this.targetRole,
    required this.experienceLevel,
    required this.overallProgress,
    this.estimatedWeeks = 8,
    required this.phases,
  });

  factory RoadmapModel.fromJson(Map<String, dynamic> json) => RoadmapModel(
        targetRole: json['target_role'] ?? 'Full-Stack Developer',
        experienceLevel: json['experience_level'] ?? 'Entry Level',
        overallProgress: json['overall_progress'] ?? 0,
        estimatedWeeks: json['estimated_weeks'] ?? 8,
        phases: (json['phases'] as List? ?? [])
            .map((p) => RoadmapPhaseModel.fromJson(p))
            .toList(),
      );
}
