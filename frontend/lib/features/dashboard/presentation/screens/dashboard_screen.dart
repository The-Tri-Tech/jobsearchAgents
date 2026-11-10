import 'package:flutter/material.dart';
import 'package:skillbridge_frontend/features/auth/data/datasources/auth_service.dart';
import 'package:skillbridge_frontend/features/auth/data/models/user_model.dart';
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
  String? _prefilledJdText;

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
  Color get _accentGreen => const Color(0xFF16A34A);
  Color get _accentBlue => const Color(0xFF2563EB);
  Color get _accentAmber => const Color(0xFFD97706);

  // ── Roadmap Data ──────────────────────────────────────────────────────────
  late List<_RoadmapPhaseData> _roadmapPhases;

  // ── Jobs Data ─────────────────────────────────────────────────────────────
  late List<_JobData> _jobsList;
  String _jobsFilter = "All";

  @override
  void initState() {
    super.initState();
    _initRoadmapData();
    _initJobsData();
    _loadData();
  }

  void _initRoadmapData() {
    _roadmapPhases = [
      _RoadmapPhaseData(
        phaseNumber: 1,
        title: "Core Foundations & Microservice Architecture",
        duration: "Weeks 1–3",
        status: "in_progress",
        description: "Master modern asynchronous Python, FastAPI dependencies, and containerized development.",
        tasks: [
          _RoadmapTaskData(id: 101, title: "Audit Python 3.12, FastAPI, and Docker core competencies", completed: true),
          _RoadmapTaskData(id: 102, title: "Build asynchronous microservice patterns with clean dependency injection", completed: true),
          _RoadmapTaskData(id: 103, title: "Implement automated unit & integration testing suite using Pytest", completed: false),
        ],
      ),
      _RoadmapPhaseData(
        phaseNumber: 2,
        title: "Production AI Systems & Capstone Project",
        duration: "Weeks 4–7",
        status: "upcoming",
        description: "Architect end-to-end AI Agent orchestration with LLM tool calling, grounding, and fallback.",
        tasks: [
          _RoadmapTaskData(id: 201, title: "Build AI agent workflow with Gemini & multi-model fallback", completed: false),
          _RoadmapTaskData(id: 202, title: "Implement vector search & contextual grounding for job postings", completed: false),
          _RoadmapTaskData(id: 203, title: "Deploy containerized services to cloud with automated CI/CD pipeline", completed: false),
        ],
      ),
      _RoadmapPhaseData(
        phaseNumber: 3,
        title: "ATS Resume & Technical Profile Branding",
        duration: "Weeks 8–9",
        status: "upcoming",
        description: "Tailor resume bullets to highlight business metrics, cloud architecture, and AI achievements.",
        tasks: [
          _RoadmapTaskData(id: 301, title: "Rewrite resume bullets with quantifiable business impact metrics", completed: false),
          _RoadmapTaskData(id: 302, title: "Run JD Matcher against 5 live job postings and optimize keyword scores", completed: false),
          _RoadmapTaskData(id: 303, title: "Polish GitHub portfolio repositories and live deployed demos", completed: false),
        ],
      ),
      _RoadmapPhaseData(
        phaseNumber: 4,
        title: "System Design & Technical Interviews",
        duration: "Weeks 10–12",
        status: "upcoming",
        description: "Master distributed system design patterns, concurrency, and live technical interviews.",
        tasks: [
          _RoadmapTaskData(id: 401, title: "Practice scalable API system design & distributed database caching", completed: false),
          _RoadmapTaskData(id: 402, title: "Complete 3 mock technical interviews on Python, algorithms, & LLM architecture", completed: false),
          _RoadmapTaskData(id: 403, title: "Submit 5 targeted job applications weekly and track responses", completed: false),
        ],
      ),
    ];
  }

  void _initJobsData() {
    _jobsList = [
      _JobData(
        id: 1,
        title: "Senior Python & AI Engineer",
        company: "TechCorp Global",
        location: "Remote",
        type: "Full-Time",
        salary: "\$130k – \$160k",
        matchScore: 92,
        skills: ["Python", "FastAPI", "Docker", "Gemini LLMs", "PostgreSQL"],
        jdText:
            "We are seeking a Senior Python & AI Engineer with expertise in Python, FastAPI, Docker, and LLMs (such as Gemini or OpenAI). Must have experience building API services, agent systems, and automated test suites.",
        isSaved: true,
      ),
      _JobData(
        id: 2,
        title: "Full Stack Engineer (Python & Flutter)",
        company: "Innovate AI Labs",
        location: "Hybrid • Bengaluru",
        type: "Full-Time",
        salary: "₹24L – ₹32L",
        matchScore: 88,
        skills: ["Python", "Flutter", "Dart", "FastAPI", "REST APIs"],
        jdText:
            "Join our team as a Full Stack Engineer building modern web and cross-platform mobile apps with Flutter, connected to high-performance FastAPI backends with AI integrations.",
        isSaved: true,
      ),
      _JobData(
        id: 3,
        title: "AI Agent Orchestration Engineer",
        company: "NextGen Systems",
        location: "Remote",
        type: "Full-Time",
        salary: "\$140k – \$170k",
        matchScore: 85,
        skills: ["LangChain", "Python", "Tool Calling", "Microservices"],
        jdText:
            "Looking for an AI Agent Engineer experienced with agentic workflows, function calling, Gemini APIs, and autonomous task pipelines.",
        isSaved: false,
      ),
      _JobData(
        id: 4,
        title: "Backend Systems Developer",
        company: "CloudScale Tech",
        location: "Remote",
        type: "Full-Time",
        salary: "\$115k – \$140k",
        matchScore: 80,
        skills: ["Python", "FastAPI", "Docker", "SQLAlchemy", "AsyncIO"],
        jdText:
            "Backend developer wanted to build resilient microservices with FastAPI, SQLite/PostgreSQL, and Docker containers.",
        isSaved: false,
      ),
    ];
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

  void _onMetricActionTap(int index) {
    setState(() {
      _activeNavIndex = index;
    });
  }

  void _analyzeJobInJdMatcher(String jdText) {
    setState(() {
      _prefilledJdText = jdText;
      _activeNavIndex = 2; // Navigate to JD Matcher tab
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
          initialJdText: _prefilledJdText,
        );
      case 3:
        return _buildFullRoadmapTab();
      case 4:
      default:
        return _buildFullJobsTab();
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
          _buildBottomSection(),
          const SizedBox(height: 32),
          _buildRoadmapOverviewSection(),
          const SizedBox(height: 32),
          _buildJobsOverviewSection(),
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
      case "roadmap":
      case "lightning":
        icon = Icons.timeline_rounded;
        targetNavIndex = 3; // Roadmap
        break;
      case "briefcase":
      default:
        icon = Icons.work_outline_rounded;
        targetNavIndex = 4; // Jobs
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Weekly Progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              Text(
                "Real activity",
                style: TextStyle(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _activePill,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Tasks",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              Text(
                "${tasks.where((t) => t.completed).length}/${tasks.length} Done",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _accentGreen,
                ),
              ),
            ],
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
                        color: task.completed ? _accentGreen : _textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
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

  // ══════════════════════════════════════════════════════════════════════════
  //  ROADMAP OVERVIEW SECTION (ON OVERVIEW)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRoadmapOverviewSection() {
    final allTasks = _roadmapPhases.expand((p) => p.tasks).toList();
    final completedCount = allTasks.where((t) => t.completed).length;
    final overallProgress = allTasks.isNotEmpty ? ((completedCount / allTasks.length) * 100).round() : 25;

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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.timeline_rounded, color: _accentBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Career Roadmap Progress",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
                      ),
                      Text(
                        "Target Role: Full Stack & AI Engineer (Mid–Senior) · 12-Week Sprint",
                        style: TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _activeNavIndex = 3),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text("View Full Roadmap", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  side: BorderSide(color: _cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress indicator bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: overallProgress / 100,
                    minHeight: 8,
                    backgroundColor: _cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                "$overallProgress% Complete",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _accentBlue),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4 Phases Grid / Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _roadmapPhases.map((phase) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildPhaseOverviewCard(phase),
                      ),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: _roadmapPhases.map((phase) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPhaseOverviewCard(phase),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseOverviewCard(_RoadmapPhaseData phase) {
    final bool isInProgress = phase.status == "in_progress";
    final completedTasks = phase.tasks.where((t) => t.completed).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isInProgress ? _accentBlue.withValues(alpha: 0.04) : _activePill.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInProgress ? _accentBlue.withValues(alpha: 0.3) : _cardBorder,
          width: isInProgress ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isInProgress ? _accentBlue : _textSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Phase ${phase.phaseNumber}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isInProgress ? Colors.white : _textPrimary,
                  ),
                ),
              ),
              Text(
                phase.duration,
                style: TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            phase.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$completedTasks / ${phase.tasks.length} tasks completed",
            style: TextStyle(fontSize: 11, color: _textSecondary),
          ),
          const SizedBox(height: 8),
          ...phase.tasks.take(2).map((task) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        task.completed = !task.completed;
                      });
                    },
                    child: Icon(
                      task.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 14,
                      color: task.completed ? _accentGreen : _textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: task.completed ? _textSecondary : _textPrimary,
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  JOBS OVERVIEW SECTION (ON OVERVIEW)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildJobsOverviewSection() {
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.work_outline_rounded, color: _accentGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Target & Recommended Jobs",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
                      ),
                      Text(
                        "Matched against your uploaded resume and skill overlap",
                        style: TextStyle(fontSize: 12, color: _textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _activeNavIndex = 4),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text("Explore All Jobs", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textPrimary,
                  side: BorderSide(color: _cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2x2 Grid of Job Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              if (isWide) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _jobsList.map((job) {
                    return SizedBox(
                      width: (constraints.maxWidth - 16) / 2,
                      child: _buildJobCard(job),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: _jobsList.map((job) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildJobCard(job),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(_JobData job) {
    final Color scoreColor = job.matchScore >= 85 ? _accentGreen : (job.matchScore >= 70 ? _accentAmber : Colors.red);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${job.company} · ${job.location}",
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: scoreColor),
                    const SizedBox(width: 4),
                    Text(
                      "${job.matchScore}% Match",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: scoreColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Skill tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: job.skills.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _activePill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(s, style: TextStyle(fontSize: 11, color: _textPrimary)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.salary,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textSecondary),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      job.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      size: 20,
                      color: job.isSaved ? _accentBlue : _textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        job.isSaved = !job.isSaved;
                      });
                    },
                    tooltip: job.isSaved ? "Saved" : "Save Job",
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _analyzeJobInJdMatcher(job.jdText),
                    icon: const Icon(Icons.analytics_outlined, size: 14),
                    label: const Text("Analyze in JD Matcher", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _textPrimary,
                      foregroundColor: _cardBg,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DEDICATED ROADMAP TAB (TAB 3)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFullRoadmapTab() {
    final allTasks = _roadmapPhases.expand((p) => p.tasks).toList();
    final completedCount = allTasks.where((t) => t.completed).length;
    final overallProgress = allTasks.isNotEmpty ? ((completedCount / allTasks.length) * 100).round() : 25;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Career Roadmap", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
                  const SizedBox(height: 4),
                  Text("Personalized 12-week learning path tailored to Full Stack & AI Engineer positions.",
                      style: TextStyle(fontSize: 14, color: _textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _activeNavIndex = 2),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Align with New JD"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _textPrimary,
                  foregroundColor: _cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overview banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: overallProgress / 100,
                        strokeWidth: 6,
                        backgroundColor: _cardBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
                      ),
                      Text("$overallProgress%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _accentBlue)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Sprint Progress: Phase 1 of 4 in progress", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                      const SizedBox(height: 4),
                      Text("You have completed $completedCount out of ${allTasks.length} milestones. Keep up the momentum to reach interview-ready status.",
                          style: TextStyle(fontSize: 13, color: _textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // All 4 Detailed Phases
          ..._roadmapPhases.map((phase) => _buildDetailedPhaseSection(phase)),
        ],
      ),
    );
  }

  Widget _buildDetailedPhaseSection(_RoadmapPhaseData phase) {
    final bool isInProgress = phase.status == "in_progress";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isInProgress ? _accentBlue.withValues(alpha: 0.4) : _cardBorder, width: isInProgress ? 1.5 : 1),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isInProgress ? _accentBlue : _textSecondary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${phase.phaseNumber}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phase.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                      Text(phase.duration, style: TextStyle(fontSize: 12, color: _textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isInProgress ? _accentBlue.withValues(alpha: 0.1) : _activePill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isInProgress ? "In Progress" : "Upcoming",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isInProgress ? _accentBlue : _textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(phase.description, style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.5)),
          const SizedBox(height: 16),
          Divider(color: _cardBorder),
          const SizedBox(height: 8),

          // Tasks checklist
          ...phase.tasks.map((task) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
                        color: task.completed ? _accentGreen : _textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
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

  // ══════════════════════════════════════════════════════════════════════════
  //  DEDICATED JOBS TAB (TAB 4)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFullJobsTab() {
    final filteredJobs = _jobsList.where((j) {
      if (_jobsFilter == "Saved") return j.isSaved;
      if (_jobsFilter == "High Match") return j.matchScore >= 85;
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Jobs Explorer", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textPrimary)),
                  const SizedBox(height: 4),
                  Text("Curated opportunities ranked by AI alignment to your verified resume skills.",
                      style: TextStyle(fontSize: 14, color: _textSecondary)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _activeNavIndex = 2),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text("Analyze New JD"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _textPrimary,
                  foregroundColor: _cardBg,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filters Row
          Row(
            children: ["All", "High Match", "Saved"].map((filter) {
              final active = _jobsFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: active,
                  onSelected: (_) => setState(() => _jobsFilter = filter),
                  selectedColor: _textPrimary,
                  labelStyle: TextStyle(
                    color: active ? _cardBg : _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: _activePill,
                  side: BorderSide.none,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Jobs List
          ...filteredJobs.map((job) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildJobCard(job),
            );
          }),
        ],
      ),
    );
  }
}

// ── Models ──────────────────────────────────────────────────────────────────

class _RoadmapPhaseData {
  final int phaseNumber;
  final String title;
  final String duration;
  final String status;
  final String description;
  final List<_RoadmapTaskData> tasks;

  _RoadmapPhaseData({
    required this.phaseNumber,
    required this.title,
    required this.duration,
    required this.status,
    required this.description,
    required this.tasks,
  });
}

class _RoadmapTaskData {
  final int id;
  final String title;
  bool completed;

  _RoadmapTaskData({
    required this.id,
    required this.title,
    required this.completed,
  });
}

class _JobData {
  final int id;
  final String title;
  final String company;
  final String location;
  final String type;
  final String salary;
  final int matchScore;
  final List<String> skills;
  final String jdText;
  bool isSaved;

  _JobData({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.type,
    required this.salary,
    required this.matchScore,
    required this.skills,
    required this.jdText,
    required this.isSaved,
  });
}
