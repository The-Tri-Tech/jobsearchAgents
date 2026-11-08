import 'package:flutter/material.dart';
import 'package:skillbridge_frontend/features/auth/data/datasources/auth_service.dart';
import 'package:skillbridge_frontend/features/auth/data/models/user_model.dart';
import 'package:skillbridge_frontend/features/auth/presentation/screens/auth_screen.dart';
import 'package:skillbridge_frontend/features/resume/presentation/screens/resume_screen.dart';
import 'package:skillbridge_frontend/features/jd_matcher/presentation/screens/jd_matcher_screen.dart';

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

  final List<Map<String, dynamic>> _navItems = [
    {"title": "Overview", "icon": Icons.grid_view_rounded},
    {"title": "Resume", "icon": Icons.description_outlined},
    {"title": "JD Matcher", "icon": Icons.search_rounded},
    {"title": "Roadmap", "icon": Icons.timeline_rounded},
    {"title": "Quiz", "icon": Icons.help_outline_rounded},
    {"title": "Interview", "icon": Icons.chat_bubble_outline_rounded},
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
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
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
        );
      case 3:
        return _buildSectionPlaceholder(
          title: "Career Roadmap",
          subtitle: "Your step-by-step personalized learning path based on targeted job roles.",
          icon: Icons.timeline_rounded,
          actionText: "Generate Roadmap",
        );
      case 4:
        return _buildSectionPlaceholder(
          title: "Adaptive Quizzes",
          subtitle: "Test and benchmark your core skills with AI-tailored technical quizzes.",
          icon: Icons.help_outline_rounded,
          actionText: "Start Adaptive Quiz",
        );
      case 5:
        return _buildSectionPlaceholder(
          title: "Mock Interviews",
          subtitle: "Practice realistic technical and behavioral interviews with instant AI feedback.",
          icon: Icons.chat_bubble_outline_rounded,
          actionText: "Start Mock Interview",
        );
      case 6:
        return _buildSectionPlaceholder(
          title: "Jobs Explorer",
          subtitle: "Explore curated job listings tailored to your resume score and match rate.",
          icon: Icons.work_outline_rounded,
          actionText: "Search Job Openings",
        );
      default:
        return _buildOverviewContent();
    }
  }

  // --- Overview Tab Content (Screenshot layout) ---
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
          _buildBottomSection(),
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

          // User Footer Profile Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: _isDarkMode ? const Color(0xFF334155) : const Color(0xFF101828),
                    child: Text(
                      user?.avatarLetter ?? "A",
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
                          user?.fullName ?? "Student",
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
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: _textSecondary),
                    color: _cardBg,
                    onSelected: (val) {
                      if (val == "logout") _handleLogout();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: "logout",
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 16, color: Color(0xFFD92D20)),
                            SizedBox(width: 8),
                            Text("Log Out", style: TextStyle(color: Color(0xFFD92D20), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
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
    final user = _overview?.user;
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
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),

          // Search Bar
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: _textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: _textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: "Search anything...",
                        hintStyle: TextStyle(color: _textSecondary, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Theme moon toggle
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: _textSecondary,
            ),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),

          // Bell notification
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, size: 21, color: _textSecondary),
                onPressed: () {},
              ),
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // User avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: _isDarkMode ? const Color(0xFF334155) : const Color(0xFF101828),
            child: Text(
              user?.avatarLetter ?? "A",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --- Greeting Header ---
  Widget _buildGreetingHeader() {
    final greeting = _overview?.greeting ?? "Good morning, Student ✦";
    final subtitle = _overview?.subtitle ??
        "This view updates from your real resume, JD, roadmap, quiz, interview, and jobs activity.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
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
        icon = Icons.person_outline_rounded;
        targetNavIndex = 1; // Resume
        break;
      case "target":
        icon = Icons.track_changes_rounded;
        targetNavIndex = 2; // JD Matcher
        break;
      case "lightning":
        icon = Icons.bolt_rounded;
        targetNavIndex = 4; // Quiz
        break;
      case "briefcase":
      default:
        icon = Icons.work_outline_rounded;
        targetNavIndex = 6; // Jobs
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Action Pill
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
          const SizedBox(height: 24),

          // Big Metric Value
          Text(
            m.value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Label
          Text(
            m.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Section (Weekly Progress + Today's Tasks) ---
  Widget _buildBottomSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        if (isNarrow) {
          return Column(
            children: [
              _buildWeeklyProgressCard(),
              const SizedBox(height: 20),
              _buildTodayTasksCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildWeeklyProgressCard()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildTodayTasksCard()),
          ],
        );
      },
    );
  }

  // Weekly Progress Card
  Widget _buildWeeklyProgressCard() {
    final progressList = _overview?.weeklyProgress ?? [];
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
          Text(
            "Weekly Progress",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          ...progressList.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (idx < progressList.length - 1)
                  Divider(color: _cardBorder, height: 1, thickness: 1),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Today's Tasks Card
  Widget _buildTodayTasksCard() {
    final tasks = _overview?.todayTasks ?? [];
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
          Text(
            "Today's Tasks",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...tasks.map((task) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    task.completed = !task.completed;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: task.completed ? _textPrimary : _textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: task.completed ? _textSecondary : _textPrimary,
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

  // --- Sub-section placeholder view ---
  Widget _buildSectionPlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionText,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(40),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: _textPrimary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _textPrimary,
                foregroundColor: _cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _activeNavIndex = 0),
              child: Text("← Back to Overview", style: TextStyle(color: _textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
