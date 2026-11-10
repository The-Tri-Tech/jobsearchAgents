import 'package:flutter/material.dart';
import 'package:skillbridge_frontend/features/auth/data/datasources/auth_service.dart';
import 'package:skillbridge_frontend/features/auth/data/models/user_model.dart';
import 'package:skillbridge_frontend/features/auth/presentation/screens/auth_screen.dart';
import 'package:skillbridge_frontend/features/resume/presentation/screens/resume_screen.dart';
import 'package:skillbridge_frontend/features/jd_matcher/presentation/screens/jd_matcher_screen.dart';
import 'package:skillbridge_frontend/features/jd_matcher/data/datasources/jd_matcher_service.dart';
import 'package:skillbridge_frontend/features/jd_evaluation/presentation/screens/jd_evaluation_screen.dart';
import 'package:skillbridge_frontend/features/chatbot/presentation/widgets/chatbot_panel.dart';
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
  bool _isChatOpen = false;
  List<ReminderModel> _reminders = [];
  String _reminderFilter = "All";
  List<FollowUpModel> _followUps = [];

  final List<Map<String, dynamic>> _navItems = [
    {"title": "Overview", "icon": Icons.grid_view_rounded},
    {"title": "Resume", "icon": Icons.description_outlined},
    {"title": "JD Matcher", "icon": Icons.search_rounded},
    {"title": "JD Evaluation", "icon": Icons.verified_user_outlined},
    {"title": "Roadmap", "icon": Icons.timeline_rounded},
    {"title": "Jobs", "icon": Icons.work_outline_rounded},
  ];

  // Dynamic Theme Colors
  Color get _bg =>
      _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
  Color get _cardBg => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _cardBorder =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFEAECF0);
  Color get _textPrimary =>
      _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF101828);
  Color get _textSecondary =>
      _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF667085);
  Color get _activePill =>
      _isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7);

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
        _reminders = List.from(data.reminders);
        _followUps = List.from(data.followUps);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshOverviewSilently() async {
    try {
      final data = await _authService.fetchDashboardOverview();
      if (mounted) {
        setState(() {
          _overview = data;
          _reminders = List.from(data.reminders);
          _followUps = List.from(data.followUps);
        });
      }
    } catch (_) {
      // Keep the last dashboard state if a background refresh fails.
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

  Future<void> _showProfileDialog() async {
    final user = _overview?.user;
    final nameCtrl = TextEditingController(text: user?.fullName ?? "Student");
    final phoneCtrl = TextEditingController(text: user?.phoneNumber ?? "+91 98765 43210");
    final emailCtrl = TextEditingController(text: user?.email ?? "student@skillbridge.ai");
    final locCtrl = TextEditingController(text: user?.location ?? "Bengaluru, Karnataka, India");
    final roleCtrl = TextEditingController(text: user?.targetRole ?? "Associate Product Manager");
    final bioCtrl = TextEditingController(text: user?.bio ?? "Aspiring Product & Tech Professional");
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _isDarkMode ? const Color(0xFF334155) : const Color(0xFF101828),
                    child: Text(
                      user?.avatarLetter ?? "S",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? "Student Profile",
                        style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Active Account",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user?.plan ?? "Pro plan",
                            style: TextStyle(color: _textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: _textSecondary),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Full Name
                  Text("Full Name", style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: _textSecondary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phone Number & Email Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Phone Number", style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: phoneCtrl,
                              style: TextStyle(color: _textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.phone_outlined, size: 18, color: _textSecondary),
                                hintText: "+91 98765 43210",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email ID", style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: emailCtrl,
                              style: TextStyle(color: _textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined, size: 18, color: _textSecondary),
                                hintText: "student@skillbridge.ai",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Target Role & Location Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Target Role / Headline", style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: roleCtrl,
                              style: TextStyle(color: _textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.work_outline_rounded, size: 18, color: _textSecondary),
                                hintText: "e.g. Associate Product Manager",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Location", style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: locCtrl,
                              style: TextStyle(color: _textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.location_on_outlined, size: 18, color: _textSecondary),
                                hintText: "e.g. Bengaluru, India",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bio / Details
                  Text("About / Bio Details", style: TextStyle(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bioCtrl,
                    maxLines: 2,
                    style: TextStyle(color: _textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.badge_outlined, size: 18, color: _textSecondary),
                      ),
                      hintText: "Brief summary of skills, background, or career goals...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        final updatedUser = await _authService.updateProfile(
                          fullName: nameCtrl.text.trim(),
                          phoneNumber: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          location: locCtrl.text.trim(),
                          targetRole: roleCtrl.text.trim(),
                          bio: bioCtrl.text.trim(),
                        );
                        Navigator.pop(ctx);
                        setState(() {
                          if (_overview != null) {
                            _overview = DashboardOverviewModel(
                              greeting: "Good morning, ${updatedUser.fullName.split(' ').first} ✦",
                              subtitle: _overview!.subtitle,
                              user: updatedUser,
                              metrics: _overview!.metrics,
                              weeklyProgress: _overview!.weeklyProgress,
                              reminders: _reminders,
                              todayTasks: _overview!.todayTasks,
                              followUps: _followUps,
                            );
                          }
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✨ Profile details updated successfully!"),
                              backgroundColor: Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _textPrimary,
                foregroundColor: _cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Save Details", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _onMetricActionTap(int index) {
    setState(() {
      _activeNavIndex = index;
    });
  }

  void _toggleChatbot() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: _bg,
      drawer: !isDesktop ? Drawer(child: _buildSidebar()) : null,
      floatingActionButton: (_activeNavIndex == 0 && !_isChatOpen)
          ? Container(
              margin: const EdgeInsets.only(bottom: 8, right: 8),
              child: FloatingActionButton(
                onPressed: _toggleChatbot,
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 6,
                shape: const CircleBorder(),
                tooltip: 'Ask SkillBridge AI',
                child: const Icon(Icons.auto_awesome, size: 26),
              ),
            )
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

          // Chatbot Side Panel expanded on right side of the screen
          if (_isChatOpen)
            Container(
              width: isDesktop ? 400 : (screenWidth * 0.88).clamp(320.0, 420.0),
              decoration: BoxDecoration(
                color: _cardBg,
                border: Border(
                  left: BorderSide(color: _cardBorder, width: 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(-4, 0),
                  ),
                ],
              ),
              child: ChatbotPanel(
                isDarkMode: _isDarkMode,
                cardBg: _cardBg,
                cardBorder: _cardBorder,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
                onClose: () {
                  setState(() {
                    _isChatOpen = false;
                  });
                },
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
          onFollowUpCreated: _refreshOverviewSilently,
        );
      case 3:
        return JdEvaluationScreen(
          isDarkMode: _isDarkMode,
          bg: _bg,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          onNavigateToResume: () => setState(() => _activeNavIndex = 1),
        );
      case 4:
        return CareerRoadmapScreen(
          isDarkMode: _isDarkMode,
          bg: _bg,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
        );
      case 5:
        return JobsScreen(
          isDarkMode: _isDarkMode,
          bg: _bg,
          cardBg: _cardBg,
          cardBorder: _cardBorder,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          onNavigateToJdMatcher: () => setState(() => _activeNavIndex = 2),
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
                      "AI Job Assistant",
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
                      if (index == 0) _refreshOverviewSilently();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w500,
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
            child: InkWell(
              onTap: _showProfileDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: _isDarkMode
                          ? const Color(0xFF334155)
                          : const Color(0xFF101828),
                      child: Text(
                        user?.avatarLetter ?? "S",
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
                      icon:
                          Icon(Icons.more_vert, size: 18, color: _textSecondary),
                      color: _cardBg,
                      onSelected: (val) {
                        if (val == "profile") _showProfileDialog();
                        if (val == "logout") _handleLogout();
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: "profile",
                          child: Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 16, color: _textPrimary),
                              const SizedBox(width: 8),
                              Text("Profile Details",
                                  style: TextStyle(
                                      color: _textPrimary, fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: "logout",
                          child: Row(
                            children: [
                              Icon(Icons.logout,
                                  size: 16, color: Color(0xFFD92D20)),
                              SizedBox(width: 8),
                              Text("Log Out",
                                  style: TextStyle(
                                      color: Color(0xFFD92D20), fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                icon: Icon(Icons.notifications_none_rounded,
                    size: 21, color: _textSecondary),
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

          // Chat button
          Tooltip(
            message: _isChatOpen ? 'Close AI Assistant' : 'Open AI Assistant',
            child: GestureDetector(
              onTap: _toggleChatbot,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: _isChatOpen
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isChatOpen
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    _isChatOpen ? Icons.chat_bubble_rounded : Icons.auto_awesome,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // User avatar
          InkWell(
            onTap: _showProfileDialog,
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 16,
              backgroundColor:
                  _isDarkMode ? const Color(0xFF334155) : const Color(0xFF101828),
              child: Text(
                user?.avatarLetter ?? "S",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
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
        "This view updates from your real resume, JD, roadmap, and jobs activity.";

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
                padding:
                    EdgeInsets.only(right: idx == metrics.length - 1 ? 0 : 16),
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
      case "document":
      case "person":
        icon = Icons.description_outlined;
        targetNavIndex = 1; // Resume
        break;
      case "target":
        icon = Icons.track_changes_rounded;
        targetNavIndex = 2; // JD Matcher
        break;
      case "briefcase":
        icon = Icons.work_outline_rounded;
        targetNavIndex = 5; // Jobs
        break;
      case "bell":
      case "event":
      default:
        icon = Icons.event_available_rounded;
        targetNavIndex = 2; // Follow-ups / JD Matcher
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
                  color: _isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon,
                      size: 18,
                      color:
                          _isDarkMode ? Colors.white : const Color(0xFF475467)),
                ),
              ),
              OutlinedButton(
                onPressed: () => _onMetricActionTap(targetNavIndex),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _cardBorder, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  // --- Bottom Section (Follow-ups + Reminders) ---
  Widget _buildBottomSection() {
    if (_followUps.isEmpty) {
      return _buildRemindersCard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        if (isNarrow) {
          return Column(
            children: [
              _buildFollowUpsCard(),
              const SizedBox(height: 20),
              _buildRemindersCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildFollowUpsCard()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildRemindersCard()),
          ],
        );
      },
    );
  }

  // Follow-ups Card (Prominently displayed)
  Widget _buildFollowUpsCard() {
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
                    value: selectedCategory,
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

  // Reminders Card (Replaces Today's Tasks)
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _textPrimary
                          : (_isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 11,
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
                    Icon(Icons.check_circle_outline_rounded, size: 36, color: _textSecondary.withOpacity(0.5)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Checkbox
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
                      const SizedBox(width: 10),

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
                            const SizedBox(height: 4),
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
                                      Icon(Icons.schedule_rounded, size: 11, color: dueColor),
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

                      // Delete Button
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 16, color: _textSecondary),
                        tooltip: "Delete Reminder",
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

  String _cleanFollowUpJobTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'Target Role';

    final lower = trimmed.toLowerCase();
    if (lower.contains('java/spring') || lower.contains('java / spring')) {
      return 'Java / Spring Developer';
    }
    if (lower.contains('backend-focused') ||
        lower.contains('backend‑focused') ||
        lower.contains('backend foundations')) {
      return 'Backend Software Engineer';
    }
    if (lower.contains('entry-level') ||
        lower.contains('graduate, missing') ||
        lower.contains('lacking required')) {
      if (lower.contains('python')) {
        return 'Python Developer';
      }
      return 'Software Engineer';
    }

    return trimmed;
  }

  String _formatDashboardDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
                color: _isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFF2F4F7),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(actionText,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _activeNavIndex = 0),
              child: Text("← Back to Overview",
                  style: TextStyle(color: _textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
