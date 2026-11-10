import 'package:flutter/material.dart';
import 'package:skillbridge_frontend/features/auth/data/datasources/auth_service.dart';
import 'package:skillbridge_frontend/features/auth/data/models/user_model.dart';
import 'package:skillbridge_frontend/features/resume/presentation/screens/resume_screen.dart';
import 'package:skillbridge_frontend/features/jd_matcher/presentation/screens/jd_matcher_screen.dart';
import 'package:skillbridge_frontend/features/dashboard/presentation/screens/career_roadmap_screen.dart';
import 'package:skillbridge_frontend/features/jobs/presentation/screens/jobs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  DashboardOverviewModel? _overview;
  bool _isLoading = true;
  int _activeNavIndex = 0;
  bool _isDarkMode = false;
  String? _prefilledJdText;
  List<FollowUpModel> _followUps = [];
  List<ReminderModel> _reminders = [];
  String _reminderFilter = "All";

  final List<Map<String, dynamic>> _navItems = [
    {"title": "Overview", "icon": Icons.grid_view_rounded},
    {"title": "Resume", "icon": Icons.description_outlined},
    {"title": "JD Matcher", "icon": Icons.search_rounded},
    {"title": "Roadmap", "icon": Icons.timeline_rounded},
    {"title": "Jobs", "icon": Icons.work_outline_rounded},
  ];

  // Dynamic Theme Colors
  Color get _bg => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
  Color get _cardBg => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _cardBorder => _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEAECF0);
  Color get _textPrimary => _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF101828);
  Color get _textSecondary => _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF667085);
  Color get _activePill => _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _authService.fetchDashboardOverview();
      setState(() {
        _overview = data;
        _followUps = List.from(data.followUps);
        _reminders = List.from(data.reminders);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onMetricActionTap(int index) {
    setState(() {
      _activeNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: _bg,
      drawer: !isDesktop ? Drawer(child: _buildSidebar()) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar for Desktop
          if (isDesktop) SizedBox(width: 240, child: _buildSidebar()),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(!isDesktop),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _textPrimary,
                          ),
                        )
                      : _buildActiveTabContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Active Tab Content Switcher ---
  Widget _buildActiveTabContent() {
    switch (_activeNavIndex) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return ResumeScreen(
          isDarkMode: _isDarkMode,
          bg: _bg,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
        );
      case 2:
        return JdMatcherScreen(
          isDarkMode: _isDarkMode,
          bg: _bg,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          onNavigateToResume: () => setState(() => _activeNavIndex = 1),
          onFollowUpCreated: _loadData,
          initialJdText: _prefilledJdText,
        );
      case 3:
        return CareerRoadmapScreen(
          isDarkMode: _isDarkMode,
          bg: _bg,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
        );
      case 4:
      default:
        return JobsScreen(
          key: ValueKey('jobs_screen_$_activeNavIndex'),
          isDarkMode: _isDarkMode,
          bg: _bg,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          onNavigateToJdMatcher: () => setState(() => _activeNavIndex = 2),
        );
    }
  }

  // --- Overview Tab Content ---
  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingHeader(),
          const SizedBox(height: 28),
          _buildMetricCardsRow(),
          const SizedBox(height: 28),
          if (_followUps.isNotEmpty) ...[
            _buildScheduledFollowUpsCard(),
            const SizedBox(height: 28),
          ],
          _buildRemindersCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Sidebar ---
  Widget _buildSidebar() {
    final user = _overview?.user;
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          right: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 24, bottom: 28),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.grid_view_rounded,
                      color: _isDarkMode ? Colors.black : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SkillBridge",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      "AI Career OS",
                      style: TextStyle(
                        fontSize: 10,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nav Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = _activeNavIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() => _activeNavIndex = index);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? _activePill : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 18,
                            color: isActive ? _textPrimary : _textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                              color: isActive ? _textPrimary : _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Profile Card at Sidebar Bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _activePill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _textPrimary,
                    child: Text(
                      user?.avatarLetter ?? "C",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? "Candidate",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          user?.plan ?? "Pro plan",
                          style: TextStyle(
                            fontSize: 11,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Top App Bar ---
  Widget _buildTopAppBar(bool showMenuButton) {
    final currentTitle = _navItems[_activeNavIndex]['title'] as String;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: _cardBg,
        border: Border(
          bottom: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showMenuButton)
                IconButton(
                  icon: Icon(Icons.menu, color: _textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              Text(
                currentTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 20,
                  color: _textSecondary,
                ),
                onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _activeNavIndex = 2),
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text("Run JD Matcher", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  side: BorderSide(color: _cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Greeting Header ---
  Widget _buildGreetingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _overview?.greeting ?? "Good morning, Candidate ✦",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _overview?.subtitle ?? "Your unified career dashboard — track resumes, JD match evaluations, roadmap progress, and jobs.",
          style: TextStyle(
            fontSize: 14,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  // --- 4 Metric Cards Row ---
  Widget _buildMetricCardsRow() {
    final metrics = _overview?.metrics ?? [];
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth < 900;

        if (useGrid) {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: metrics.asMap().entries.map((entry) {
              return SizedBox(
                width: (constraints.maxWidth - 16) / 2,
                child: _buildMetricCard(entry.value, entry.key),
              );
            }).toList(),
          );
        }

        return Row(
          children: metrics.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: idx == metrics.length - 1 ? 0 : 16),
                child: _buildMetricCard(m, idx),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricCard(StatCardModel m, int cardIndex) {
    IconData icon;
    int targetNavIndex = 1;
    switch (m.iconType) {
      case "person":
      case "document":
        icon = Icons.description_outlined;
        targetNavIndex = 1; // Resume
        break;
      case "target":
        icon = Icons.track_changes_rounded;
        targetNavIndex = 2; // JD Matcher
        break;
      case "briefcase":
        icon = Icons.work_outline_rounded;
        targetNavIndex = 4; // Jobs
        break;
      case "calendar":
      case "bell":
        icon = Icons.calendar_today_outlined;
        targetNavIndex = 2; // Follow-up in JD Matcher
        break;
      case "roadmap":
      case "lightning":
      case "timeline":
      default:
        icon = Icons.timeline_rounded;
        targetNavIndex = 3; // Roadmap
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, size: 18, color: _isDarkMode ? Colors.white : const Color(0xFF475467)),
                ),
              ),
              OutlinedButton(
                onPressed: () => _onMetricActionTap(targetNavIndex),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _cardBorder, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  m.actionLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            m.value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            m.title,
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  REMINDERS CARD (ON OVERVIEW)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRemindersCard() {
    final filteredReminders = _reminders.where((r) {
      if (_reminderFilter == "Pending") return !r.completed;
      if (_reminderFilter == "Completed") return r.completed;
      return true;
    }).toList();

    final pendingCount = _reminders.where((r) => !r.completed).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_rounded, size: 20, color: _textPrimary),
                  const SizedBox(width: 10),
                  Text(
                    "Reminders",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$pendingCount pending",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddReminderDialog,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text("Add Reminder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _textPrimary,
                  foregroundColor: _cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter pills (All, Pending, Completed)
          Row(
            children: ["All", "Pending", "Completed"].map((tab) {
              final isSelected = _reminderFilter == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => setState(() => _reminderFilter = tab),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _textPrimary
                          : (_isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _cardBg : _textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // List of reminders
          if (filteredReminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 36, color: _textSecondary.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      _reminderFilter == "Completed"
                          ? "No completed reminders yet."
                          : "No reminders found. Stay on track by adding one!",
                      style: TextStyle(fontSize: 13, color: _textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredReminders.map((reminder) {
              final dueDate = reminder.dueDate;
              String? dueText;
              Color dueColor = const Color(0xFF16A34A);

              if (dueDate != null) {
                final today = DateUtils.dateOnly(DateTime.now());
                final target = DateUtils.dateOnly(dueDate);
                final diff = target.difference(today).inDays;
                if (diff < 0) {
                  dueText = "Overdue by ${-diff}d";
                  dueColor = const Color(0xFFEF4444);
                } else if (diff == 0) {
                  dueText = "Due today";
                  dueColor = const Color(0xFFF59E0B);
                } else if (diff == 1) {
                  dueText = "Due tomorrow";
                  dueColor = const Color(0xFF10B981);
                } else {
                  dueText = "Due in ${diff}d";
                  dueColor = const Color(0xFF2563EB);
                }
              }

              // Category color
              Color catBg;
              Color catColor;
              switch (reminder.category.toLowerCase()) {
                case "application":
                  catBg = const Color(0xFFEFF6FF);
                  catColor = const Color(0xFF2563EB);
                  break;
                case "jd prep":
                  catBg = const Color(0xFFFAF5FF);
                  catColor = const Color(0xFF9333EA);
                  break;
                case "resume":
                  catBg = const Color(0xFFFEF3C7);
                  catColor = const Color(0xFFD97706);
                  break;
                case "roadmap":
                  catBg = const Color(0xFFECFDF5);
                  catColor = const Color(0xFF059669);
                  break;
                default:
                  catBg = const Color(0xFFF1F5F9);
                  catColor = const Color(0xFF475467);
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Radio button / Checkbox
                      InkWell(
                        onTap: () async {
                          setState(() {
                            reminder.completed = !reminder.completed;
                          });
                          await _authService.toggleReminder(reminder.id);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            reminder.completed
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: reminder.completed
                                ? const Color(0xFF10B981)
                                : _textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: reminder.completed ? _textSecondary : _textPrimary,
                                decoration: reminder.completed ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode ? const Color(0xFF334155) : catBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    reminder.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _isDarkMode ? Colors.white : catColor,
                                    ),
                                  ),
                                ),
                                if (dueText != null) ...[
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule_rounded, size: 12, color: dueColor),
                                      const SizedBox(width: 3),
                                      Text(
                                        dueText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: dueColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Delete action
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 16, color: _textSecondary),
                        tooltip: "Dismiss reminder",
                        onPressed: () async {
                          setState(() {
                            _reminders.removeWhere((r) => r.id == reminder.id);
                          });
                          await _authService.deleteReminder(reminder.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // Add Reminder Dialog
  Future<void> _showAddReminderDialog() async {
    final titleController = TextEditingController();
    String selectedCategory = "Application";
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_alert_rounded, size: 20, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 12),
              Text(
                "Add Reminder",
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Reminder Title *",
                      style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "e.g. Follow up on apna application, Review matched skills...",
                      hintStyle: TextStyle(color: _textSecondary, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text("Category",
                      style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: _cardBg,
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Application", child: Text("Application Follow-up")),
                      DropdownMenuItem(value: "JD Prep", child: Text("JD Match / Preparation")),
                      DropdownMenuItem(value: "Resume", child: Text("Resume Update")),
                      DropdownMenuItem(value: "Roadmap", child: Text("Roadmap Milestone")),
                      DropdownMenuItem(value: "General", child: Text("General Reminder")),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  Text("Due Date",
                      style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      {"label": "Today", "days": 0},
                      {"label": "Tomorrow", "days": 1},
                      {"label": "In 3 Days", "days": 3},
                      {"label": "In 1 Week", "days": 7},
                    ].map((preset) {
                      final targetDate = DateUtils.dateOnly(DateTime.now().add(Duration(days: preset["days"] as int)));
                      final isSel = DateUtils.isSameDay(selectedDate, targetDate);
                      return ChoiceChip(
                        label: Text(preset["label"] as String),
                        selected: isSel,
                        selectedColor: const Color(0xFF2563EB),
                        backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : _textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setDialogState(() => selectedDate = targetDate);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: _cardBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: _textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            "Custom Date: ${_formatDashboardDate(selectedDate)}",
                            style: TextStyle(color: _textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(ctx);
                final newReminder = await _authService.createReminder(
                  title: title,
                  category: selectedCategory,
                  dueDate: selectedDate,
                );
                setState(() {
                  _reminders.insert(0, newReminder);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✨ Added reminder: $title"),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _textPrimary,
                foregroundColor: _cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Save Reminder", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SCHEDULED FOLLOW-UPS CARD (ON OVERVIEW)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildScheduledFollowUpsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event_available_rounded, size: 20, color: _textPrimary),
                  const SizedBox(width: 10),
                  Text(
                    "Upcoming Follow-ups",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_followUps.length} scheduled",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._followUps.asMap().entries.map((entry) {
            final followUp = entry.value;
            final today = DateUtils.dateOnly(DateTime.now());
            final dueDate = DateUtils.dateOnly(followUp.followUpDate);
            final daysUntil = dueDate.difference(today).inDays;
            final dueLabel = daysUntil < 0
                ? 'Overdue by ${-daysUntil} ${-daysUntil == 1 ? 'day' : 'days'}'
                : daysUntil == 0
                    ? 'Due today'
                    : 'Due in $daysUntil ${daysUntil == 1 ? 'day' : 'days'}';
            final dueColor = daysUntil < 0
                ? const Color(0xFFEF4444)
                : (daysUntil == 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: dueColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.event_available_outlined, size: 18, color: dueColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_cleanFollowUpJobTitle(followUp.reportTitle),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary)),
                          const SizedBox(height: 3),
                          Text(
                            "${followUp.resumeFilename} • Applied ${_formatDashboardDate(followUp.applicationDate)}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: _textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: dueColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dueLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dueColor),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 16, color: _textSecondary),
                      tooltip: "Dismiss Follow-up",
                      onPressed: () async {
                        setState(() {
                          _followUps.removeWhere((f) => f.id == followUp.id);
                        });
                        await _authService.deleteFollowUp(followUp.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _cleanFollowUpJobTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'Target Role';
    return trimmed;
  }

  String _formatDashboardDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
