import 'package:flutter/material.dart';
import 'dart:math';
import '../../data/datasources/chat_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Message model
// ─────────────────────────────────────────────────────────────────────────────

enum _Sender { user, bot }

class _ChatMessage {
  final String text;
  final _Sender sender;
  final DateTime time;

  _ChatMessage({required this.text, required this.sender}) : time = DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Fallback mock bot responses
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _mockResponses = [
  "Great question! Based on your resume, I'd recommend tailoring your skills section to match the job description keywords more closely.",
  "I can help with that! Try highlighting your most recent achievements with measurable outcomes — recruiters love numbers like '30% improvement' or 'managed team of 5'.",
  "Sure! For this role, focus on your problem-solving experience. Make sure your resume mentions relevant tools and technologies from the JD.",
  "That's a common concern. I'd suggest updating your LinkedIn profile summary to align with the roles you're targeting.",
  "Good thinking! Applying within the first 24 hours of a job posting can significantly increase your chances of getting noticed.",
  "For interview prep, start with the STAR method (Situation, Task, Action, Result) for behavioral questions. It works really well!",
  "I noticed your resume has strong technical skills. Consider adding a brief 'Professional Summary' at the top to give recruiters a quick snapshot.",
  "Networking is key! Try reaching out to professionals on LinkedIn who work at companies you're interested in. A warm referral can go a long way.",
  "For your JD match score to improve, focus on the keywords in the 'Requirements' section — these are what ATS systems scan for.",
  "Great progress! Keep applying consistently. Most job seekers land interviews after applying to 15–30 positions, so persistence is key.",
];

String _getMockResponse(String userMessage) {
  final lower = userMessage.toLowerCase();
  if (lower.contains('follow up') || lower.contains('followup') || lower.contains('need to follow')) {
    return "📅 **Today's Follow-Ups**\nYou can check your pending follow-ups scheduled for today directly on your Dashboard Overview. When you apply through the JD Matcher, follow-ups are automatically scheduled and tracked here.";
  }
  if (lower.contains('greater than 50') || lower.contains('suit me') || lower.contains('score')) {
    return "🎯 **Jobs with Match Score > 50%**\nBased on your JD analysis records, any job where your match score exceeds 50% indicates strong potential. You can review all detailed skill breakdowns in the JD Matcher tab.";
  }
  if (lower.contains('how am i doing') || lower.contains('overall') || lower.contains('average')) {
    return "📊 **Overall Career Standing**\nYou are making consistent progress! Keep testing target job descriptions in the JD Matcher and completing adaptive quizzes to elevate your overall match score and ATS readiness.";
  }
  if (lower.contains('resume') || lower.contains('cv')) {
    return "I can help you improve your resume! Make sure it's ATS-friendly — use standard headings, avoid tables or columns, and include keywords from the job description.";
  }
  if (lower.contains('interview')) {
    return "Interview prep is crucial! Practice the STAR method for behavioral questions, research the company thoroughly, and prepare 2–3 thoughtful questions to ask the interviewer.";
  }
  if (lower.contains('salary') || lower.contains('pay') || lower.contains('compensation')) {
    return "Salary negotiation tip: always research market rates on Glassdoor/LinkedIn first. Let the employer make the first offer when possible, and negotiate with data.";
  }
  if (lower.contains('hi') || lower.contains('hello') || lower.contains('hey')) {
    return "Hello! 👋 I'm your SkillBridge AI Career Assistant. How can I help with your job search, follow-ups, or interview prep today?";
  }
  final random = Random();
  return _mockResponses[random.nextInt(_mockResponses.length)];
}

// ─────────────────────────────────────────────────────────────────────────────
//  ChatbotPanel widget
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotPanel extends StatefulWidget {
  final bool isDarkMode;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onClose;

  const ChatbotPanel({
    super.key,
    required this.isDarkMode,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    this.onClose,
  });

  @override
  State<ChatbotPanel> createState() => _ChatbotPanelState();
}

class _ChatbotPanelState extends State<ChatbotPanel> {
  final ChatService _chatService = ChatService();
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = false;
  String? _currentMcpTool;

  static const Color _accentBlue = Color(0xFF2563EB);

  final List<String> _promptSuggestions = [
    "List all my job follow-ups",
    "Today how many jobs I need to follow up?",
    "How many jobs did I apply today?",
    "How many I applied where match score > 50%?",
    "How am I doing overall?",
  ];

  String _resolveMcpToolName(String question) {
    final lower = question.trim().toLowerCase();

    // 1. Follow-ups due today / overdue
    if ((lower.contains('today') || lower.contains('due') || lower.contains('pending')) &&
        (lower.contains('follow up') || lower.contains('followup') || lower.contains('follow-up') || lower.contains('need to follow'))) {
      return 'get_today_follow_ups';
    }

    // 2. All follow-ups (general / list)
    if (lower.contains('follow up') || lower.contains('followup') || lower.contains('follow-up')) {
      return 'get_all_follow_ups';
    }

    // 3. Jobs applied today
    if (lower.contains('applied') || lower.contains('applications') || lower.contains('apply')) {
      if (lower.contains('today') || lower.contains('recent') || lower.contains('how many')) {
        return 'get_today_applied_jobs';
      }
    }

    // 4. Match score > 50% / high match
    if (lower.contains('50') || lower.contains('> 50') || lower.contains('greater than 50') ||
        (lower.contains('match') && (lower.contains('score') || lower.contains('high') || lower.contains('suit')))) {
      return 'get_high_match_jobs';
    }

    // 5. Overall standing / average / progress
    if (lower.contains('overall') || lower.contains('standing') || lower.contains('how am i doing') ||
        lower.contains('average') || lower.contains('progress') || lower.contains('stats')) {
      return 'get_overall_standing';
    }

    // 6. Resume / CV / ATS tools
    if (lower.contains('resume') || lower.contains('cv') || lower.contains('ats')) {
      return 'resume_matcher_tool';
    }

    // 7. General career / interview advisor
    if (lower.contains('interview') || lower.contains('salary') || lower.contains('prep')) {
      return 'interview_prep_tool';
    }

    return 'career_advisor_tool';
  }

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(_ChatMessage(
      text: "👋 Hi! I'm your SkillBridge AI Career Assistant.\n\n"
          "I can help you monitor your job applications, analyze match scores, and prepare for interviews.\n\n"
          "Tap one of the quick questions below or ask me anything career-related!",
      sender: _Sender.bot,
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendPrompt(String text) async {
    _inputController.text = text;
    await _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isBotTyping) return;

    final toolName = _resolveMcpToolName(text);

    setState(() {
      _messages.add(_ChatMessage(text: text, sender: _Sender.user));
      _currentMcpTool = toolName;
      _isBotTyping = true;
      _inputController.clear();
    });
    _scrollToBottom();

    String reply;
    try {
      final history = _messages
          .sublist(0, _messages.length - 1)
          .map((m) => {
                'role': m.sender == _Sender.user ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final res = await _chatService.sendMessage(
        message: text,
        history: history,
      );
      reply = res.reply;
      if (res.toolCalled != null && res.toolCalled!.isNotEmpty) {
        _currentMcpTool = res.toolCalled;
      }
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 600));
      reply = _getMockResponse(text);
    }

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(
        text: reply,
        sender: _Sender.bot,
      ));
      _isBotTyping = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardBg,
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildPromptChips(),
          Expanded(child: _buildMessageList()),
          if (_isBotTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: _accentBlue,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 19),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Career Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'MCP Tools & Guardrails Active',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.white70, size: 18),
            tooltip: 'Clear chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  text: "Chat cleared! How can I help with your job search today?",
                  sender: _Sender.bot,
                ));
              });
            },
          ),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 20),
              tooltip: 'Close Assistant',
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }

  // ── Quick Prompt Suggestion Chips ─────────────────────────────────────────

  Widget _buildPromptChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: widget.cardBorder),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _promptSuggestions.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                elevation: 0,
                pressElevation: 1,
                label: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF1D4ED8),
                  ),
                ),
                backgroundColor: widget.isDarkMode
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEFF6FF),
                side: BorderSide(
                  color: _accentBlue.withOpacity(0.3),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onPressed: _isBotTyping ? null : () => _sendPrompt(prompt),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.sender == _Sender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: _accentBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? _accentBlue
                        : (widget.isDarkMode
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUser ? Colors.white : widget.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(msg.time),
                  style: TextStyle(fontSize: 10, color: widget.textSecondary),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? const Color(0xFF475569)
                    : const Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 15, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    final tool = _currentMcpTool ?? 'career_advisor_tool';
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 10, right: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _accentBlue.withOpacity(0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: _accentBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Calling MCP Tool: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: widget.textSecondary,
                  ),
                ),
                Text(
                  tool,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: _accentBlue,
                  ),
                ),
                const SizedBox(width: 8),
                const _TypingDots(color: _accentBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: widget.cardBg,
        border: Border(top: BorderSide(color: widget.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.cardBorder),
              ),
              child: TextField(
                controller: _inputController,
                style: TextStyle(fontSize: 13, color: widget.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ask about follow-ups, match scores, or career tips…',
                  hintStyle:
                      TextStyle(fontSize: 12, color: widget.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _isBotTyping ? null : _sendMessage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _accentBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chatbot Pop-up Dialog
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotDialog extends StatelessWidget {
  final bool isDarkMode;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  const ChatbotDialog({
    super.key,
    required this.isDarkMode,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = min(size.width * 0.94, 460.0);
    final dialogHeight = min(size.height * 0.84, 660.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cardBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ChatbotPanel(
              isDarkMode: isDarkMode,
              cardBg: cardBg,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}

void showChatbotPopup(
  BuildContext context, {
  required bool isDarkMode,
  required Color cardBg,
  required Color cardBorder,
  required Color textPrimary,
  required Color textSecondary,
}) {
  showDialog(
    context: context,
    builder: (ctx) => ChatbotDialog(
      isDarkMode: isDarkMode,
      cardBg: cardBg,
      cardBorder: cardBorder,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Animated typing dots
// ─────────────────────────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
            final opacity = (sin(phase * pi) * 0.8 + 0.2).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: widget.color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
