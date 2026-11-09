import 'package:flutter/material.dart';
import 'package:skillbridge_frontend/features/auth/data/datasources/auth_service.dart';
import 'package:skillbridge_frontend/features/auth/data/models/user_model.dart';

class CareerRoadmapScreen extends StatefulWidget {
  final bool isDarkMode;
  final Color bg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onNavigateToQuiz;
  final VoidCallback? onNavigateToInterview;

  const CareerRoadmapScreen({
    super.key,
    required this.isDarkMode,
    required this.bg,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    this.onNavigateToQuiz,
    this.onNavigateToInterview,
  });

  @override
  State<CareerRoadmapScreen> createState() => _CareerRoadmapScreenState();
}

class _CareerRoadmapScreenState extends State<CareerRoadmapScreen> {
  final AuthService _authService = AuthService();
  RoadmapModel? _roadmap;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  Future<void> _loadRoadmap() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authService.fetchRoadmap();
      if (mounted) {
        setState(() {
          _roadmap = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleTask(RoadmapPhaseModel phase, RoadmapTaskModel task) {
    setState(() {
      task.completed = !task.completed;

      // Recalculate phase status & overall progress
      final allTasks = _roadmap!.phases.expand((p) => p.tasks).toList();
      final completedCount = allTasks.where((t) => t.completed).length;
      _roadmap!.overallProgress = allTasks.isNotEmpty
          ? ((completedCount / allTasks.length) * 100).round()
          : 0;
    });
  }

  void _showGenerateDialog() {
    final roleController = TextEditingController(text: _roadmap?.targetRole ?? "Full-Stack Developer");
    const validLevels = ["Intern / Entry Level", "Entry-to-Mid Level", "Senior Level"];
    String selectedLevel = (_roadmap != null && validLevels.contains(_roadmap!.experienceLevel))
        ? _roadmap!.experienceLevel
        : "Entry-to-Mid Level";
    int weeklyHours = 10;
    if (_roadmap != null) {
      if (_roadmap!.estimatedWeeks <= 4) {
        weeklyHours = 30;
      } else if (_roadmap!.estimatedWeeks <= 6) {
        weeklyHours = 20;
      } else if (_roadmap!.estimatedWeeks <= 10) {
        weeklyHours = 10;
      } else {
        weeklyHours = 5;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Customize Career Roadmap",
            style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Target Role", style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: roleController,
                  style: TextStyle(color: widget.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "e.g. Flutter Specialist, Backend Engineer",
                    hintStyle: TextStyle(color: widget.textSecondary, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Experience Level", style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  dropdownColor: widget.cardBg,
                  style: TextStyle(color: widget.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Intern / Entry Level", child: Text("Intern / Entry Level")),
                    DropdownMenuItem(value: "Entry-to-Mid Level", child: Text("Entry-to-Mid Level")),
                    DropdownMenuItem(value: "Senior Level", child: Text("Senior Level")),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedLevel = val);
                  },
                ),
                const SizedBox(height: 16),
                Text("Weekly Study Commitment", style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: weeklyHours.toDouble(),
                        min: 5,
                        max: 30,
                        divisions: 5,
                        label: "$weeklyHours hrs/wk",
                        activeColor: widget.textPrimary,
                        onChanged: (val) => setDialogState(() => weeklyHours = val.toInt()),
                      ),
                    ),
                    Text("$weeklyHours hrs/wk", style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: widget.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isGenerating = true);
                try {
                  final newRoadmap = await _authService.generateCustomRoadmap(
                    targetRole: roleController.text.trim().isEmpty ? "Full-Stack Developer" : roleController.text.trim(),
                    experienceLevel: selectedLevel,
                    weeklyHours: weeklyHours,
                  );
                  if (mounted) {
                    setState(() {
                      _roadmap = newRoadmap;
                      _isGenerating = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("✨ Roadmap updated for ${newRoadmap.targetRole}!"),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (_) {
                  if (mounted) setState(() => _isGenerating = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.textPrimary,
                foregroundColor: widget.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Generate Plan", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: widget.textPrimary),
      );
    }

    final roadmap = _roadmap;
    if (roadmap == null) {
      return Center(
        child: Text("No roadmap available", style: TextStyle(color: widget.textSecondary)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Career Roadmap",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: widget.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "A personalized step-by-step game plan to land your target role.",
                    style: TextStyle(fontSize: 14, color: widget.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _showGenerateDialog,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: Text(_isGenerating ? "Generating..." : "Customize Plan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.textPrimary,
                  foregroundColor: widget.cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overview Goal & Progress Card
          _buildGoalSummaryCard(roadmap),
          const SizedBox(height: 28),

          // Phases Vertical Stepper
          Text(
            "Roadmap Milestones",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: widget.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          ...roadmap.phases.map((phase) => _buildPhaseCard(phase)),
        ],
      ),
    );
  }

  Widget _buildGoalSummaryCard(RoadmapModel roadmap) {
    final allTasks = roadmap.phases.expand((p) => p.tasks).toList();
    final completedCount = allTasks.where((t) => t.completed).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.flag_rounded, color: widget.textPrimary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        roadmap.targetRole,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.textPrimary,
                        ),
                      ),
                      Text(
                        roadmap.experienceLevel,
                        style: TextStyle(fontSize: 12, color: widget.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${roadmap.overallProgress}% Completed",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: roadmap.overallProgress / 100.0,
              minHeight: 8,
              backgroundColor: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(widget.textPrimary),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Summary Stats
          Row(
            children: [
              _buildStatChip(Icons.layers_rounded, "${roadmap.phases.length} Phases"),
              const SizedBox(width: 16),
              _buildStatChip(Icons.check_circle_outline_rounded, "$completedCount / ${allTasks.length} Tasks Done"),
              const SizedBox(width: 16),
              _buildStatChip(Icons.calendar_today_rounded, "${roadmap.estimatedWeeks} Weeks Estimated"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: widget.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: widget.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPhaseCard(RoadmapPhaseModel phase) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (phase.status == "completed") {
      statusColor = const Color(0xFF12B76A);
      statusLabel = "Completed";
      statusIcon = Icons.check_circle_rounded;
    } else if (phase.status == "in_progress") {
      statusColor = const Color(0xFF0284C7);
      statusLabel = "In Progress";
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = widget.textSecondary;
      statusLabel = "Upcoming";
      statusIcon = Icons.lock_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: phase.status == "in_progress" ? widget.textPrimary.withOpacity(0.4) : widget.cardBorder,
          width: phase.status == "in_progress" ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Phase ${phase.phaseNumber} • ${phase.duration}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    phase.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: widget.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            phase.description,
            style: TextStyle(fontSize: 13, color: widget.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Tasks List
          ...phase.tasks.map((task) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: () => _toggleTask(phase, task),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: task.completed ? const Color(0xFF12B76A) : widget.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: task.completed ? widget.textSecondary : widget.textPrimary,
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

