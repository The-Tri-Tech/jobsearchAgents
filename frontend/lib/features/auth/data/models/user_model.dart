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
      value: json['value'] ?? '--',
      actionLabel: json['action_label'] ?? '',
      iconType: json['icon_type'] ?? 'person',
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
        applicationDate: DateTime.parse(json['application_date']),
        followUpAfterDays: json['follow_up_after_days'] ?? 0,
        followUpDate: DateTime.parse(json['follow_up_date']),
        status: json['status'] ?? 'pending',
      );
}

class DashboardOverviewModel {
  final String greeting;
  final String subtitle;
  final UserModel user;
  final List<StatCardModel> metrics;
  final List<ProgressItemModel> weeklyProgress;
  final List<TaskItemModel> todayTasks;
  final List<FollowUpModel> followUps;

  DashboardOverviewModel({
    required this.greeting,
    required this.subtitle,
    required this.user,
    required this.metrics,
    required this.weeklyProgress,
    required this.todayTasks,
    required this.followUps,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewModel(
      greeting: json['greeting'] ?? 'Good morning, Student ✦',
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
    );
  }
}
