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
//  Mock bot responses
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
  if (lower.contains('resume') || lower.contains('cv')) {
    return "I can help you improve your resume! Make sure it's ATS-friendly — use standard headings, avoid tables or columns, and include keywords from the job description. Would you like me to analyse a specific section?";
  }
  if (lower.contains('interview')) {
    return "Interview prep is crucial! Practice the STAR method for behavioral questions, research the company thoroughly, and prepare 2–3 thoughtful questions to ask the interviewer. Want me to run a mock interview session?";
  }
  if (lower.contains('job') || lower.contains('apply') || lower.contains('application')) {
    return "Smart job hunting tip: customize your resume and cover letter for each application, apply within 24 hours of posting, and follow up politely after a week. Quality over quantity wins!";
  }
  if (lower.contains('salary') || lower.contains('pay') || lower.contains('compensation')) {
    return "Salary negotiation tip: always research market rates on Glassdoor/LinkedIn first. Let the employer make the first offer when possible, and negotiate with data — not emotions. You've got this! 💪";
  }
  if (lower.contains('skill') || lower.contains('learn') || lower.contains('course')) {
    return "Upskilling is a great investment! For tech roles, focus on the top 3 tools mentioned most in your target JDs. Platforms like Coursera, Udemy, and official docs are great. Want a personalized roadmap?";
  }
  if (lower.contains('linkedin')) {
    return "LinkedIn tip: optimize your headline to include your target role and key skills, not just your current title. Post weekly to stay visible. Recruiters search by keywords, so make sure yours are prominent!";
  }
  if (lower.contains('hi') || lower.contains('hello') || lower.contains('hey')) {
    return "Hello! 👋 I'm your AI Career Assistant. I can help you with resume tips, interview prep, job search strategies, and more. What can I help you with today?";
  }
  if (lower.contains('thank')) {
    return "You're welcome! 😊 Best of luck with your job search. Remember, persistence pays off. Feel free to ask anything else!";
  }
  // Random response for everything else
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

  const ChatbotPanel({
    super.key,
    required this.isDarkMode,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
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

  static const Color _accentBlue = Color(0xFF2563EB);
  static const Color _accentBlueDark = Color(0xFF1D4ED8);

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(_ChatMessage(
      text: "👋 Hi! I'm your AI Career Assistant.\n\nI can help you with:\n• Resume tips & improvements\n• Interview preparation\n• Job search strategies\n• Skill gap analysis\n\nWhat can I help you with today?",
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

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isBotTyping) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, sender: _Sender.user));
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

      reply = await _chatService.sendMessage(
        message: text,
        history: history,
      );
    } catch (_) {
      // Graceful fallback to local tips if backend / LLM is unreachable
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
      width: 360,
      decoration: BoxDecoration(
        color: widget.cardBg,
        border: Border(left: BorderSide(color: widget.cardBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _accentBlue,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Career Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.white70, size: 20),
            tooltip: 'Clear chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(_ChatMessage(
                  text: "Chat cleared! How can I help you today?",
                  sender: _Sender.bot,
                ));
              });
            },
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: _accentBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  size: 15, color: Colors.white),
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
                      height: 1.5,
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFF101828),
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
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
                color: _accentBlue, shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_outlined,
                size: 15, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: _TypingDots(color: widget.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: widget.cardBg,
        border: Border(top: BorderSide(color: widget.cardBorder, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: widget.cardBorder),
              ),
              child: TextField(
                controller: _inputController,
                style: TextStyle(fontSize: 13, color: widget.textPrimary),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask me anything…',
                  hintStyle: TextStyle(
                      color: widget.textSecondary, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _accentBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 18),
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
                  width: 7,
                  height: 7,
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
