class MatchedSkillModel {
  final String skill;
  final String? context;
  const MatchedSkillModel({required this.skill, this.context});
  factory MatchedSkillModel.fromJson(Map<String, dynamic> j) =>
      MatchedSkillModel(skill: j['skill'] ?? '', context: j['context']);
}

class MissingSkillModel {
  final String skill;
  final String importance; // High | Medium | Low
  const MissingSkillModel({required this.skill, required this.importance});
  factory MissingSkillModel.fromJson(Map<String, dynamic> j) =>
      MissingSkillModel(skill: j['skill'] ?? '', importance: j['importance'] ?? 'Medium');
}

class RecommendedRoleModel {
  final String title;
  final int matchScore;
  final String reason;
  const RecommendedRoleModel(
      {required this.title, required this.matchScore, required this.reason});
  factory RecommendedRoleModel.fromJson(Map<String, dynamic> j) =>
      RecommendedRoleModel(
        title: j['title'] ?? '',
        matchScore: (j['match_score'] ?? 0) as int,
        reason: j['reason'] ?? '',
      );
}

class AnalysisReportModel {
  final String resumeUsed;
  final String jdSource;
  final int shortlistingChance;

  final List<MatchedSkillModel> matchedSkills;
  final List<MissingSkillModel> missingSkills;

  final int overallScore;
  final String summaryTitle;
  final List<String> summaryParagraphs;

  final List<RecommendedRoleModel> recommendedRoles;

  const AnalysisReportModel({
    required this.resumeUsed,
    required this.jdSource,
    required this.shortlistingChance,
    required this.matchedSkills,
    required this.missingSkills,
    required this.overallScore,
    required this.summaryTitle,
    required this.summaryParagraphs,
    required this.recommendedRoles,
  });

  factory AnalysisReportModel.fromJson(Map<String, dynamic> j) =>
      AnalysisReportModel(
        resumeUsed: j['resume_used'] ?? '',
        jdSource: j['jd_source'] ?? 'text',
        shortlistingChance: (j['shortlisting_chance'] ?? 0) as int,
        matchedSkills: (j['matched_skills'] as List? ?? [])
            .map((e) => MatchedSkillModel.fromJson(e))
            .toList(),
        missingSkills: (j['missing_skills'] as List? ?? [])
            .map((e) => MissingSkillModel.fromJson(e))
            .toList(),
        overallScore: (j['overall_score'] ?? 0) as int,
        summaryTitle: j['summary_title'] ?? '',
        summaryParagraphs:
            (j['summary_paragraphs'] as List? ?? []).cast<String>(),
        recommendedRoles: (j['recommended_roles'] as List? ?? [])
            .map((e) => RecommendedRoleModel.fromJson(e))
            .toList(),
      );
}
