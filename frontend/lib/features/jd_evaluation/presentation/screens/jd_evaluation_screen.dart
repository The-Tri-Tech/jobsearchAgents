import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Mock data models
// ─────────────────────────────────────────────────────────────────────────────

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Mock quiz generator (will be replaced by agent call later)
// ─────────────────────────────────────────────────────────────────────────────
List<_QuizQuestion> _generateMockQuestions(String jdText) {
  // Returns 5 hard-coded questions that represent typical JD-based screening.
  // The JD text is accepted so the agent layer can use it later.
  return [
    _QuizQuestion(
      question:
          'Which of the following best describes the primary responsibility mentioned in the Job Description?',
      options: [
        'Managing a team of designers and creating visual assets',
        'Developing and maintaining scalable software solutions',
        'Conducting market research and writing business reports',
        'Coordinating logistics and supply-chain operations',
      ],
      correctIndex: 1,
    ),
    _QuizQuestion(
      question:
          'The JD mentions experience with version control. Which tool is most commonly expected?',
      options: [
        'Microsoft Word Track-Changes',
        'Adobe Version Cue',
        'Git',
        'SVN only',
      ],
      correctIndex: 2,
    ),
    _QuizQuestion(
      question:
          'According to the JD, which soft skill is explicitly highlighted as essential?',
      options: [
        'Graphic design proficiency',
        'Effective verbal and written communication',
        'Physical fitness and stamina',
        'Expertise in classical music theory',
      ],
      correctIndex: 1,
    ),
    _QuizQuestion(
      question:
          'The role requires collaborating in an agile environment. What does "sprint" mean in this context?',
      options: [
        'A physical race to deliver hardware',
        'A fixed time-box during which a set of work is completed',
        'A method of running unit tests at high speed',
        'A type of database migration',
      ],
      correctIndex: 1,
    ),
    _QuizQuestion(
      question:
          'If the JD requires "3+ years of relevant experience", which candidate profile fits best?',
      options: [
        'A fresh graduate with 6 months of internship',
        'A professional with 5 years in an unrelated field',
        'A professional with 4 years of directly relevant experience',
        'A freelancer with 1 year of similar project work',
      ],
      correctIndex: 2,
    ),
  ];
}

// Mock resume filenames
const List<String> _mockResumes = [
  'resume_software_engineer_v3.pdf',
  'resume_fullstack_2024.pdf',
  'resume_backend_specialist.pdf',
];

// ─────────────────────────────────────────────────────────────────────────────
//  Screen states
// ─────────────────────────────────────────────────────────────────────────────

enum _EvalStep { input, quiz, result }

// ─────────────────────────────────────────────────────────────────────────────
//  Widget
// ─────────────────────────────────────────────────────────────────────────────

class JdEvaluationScreen extends StatefulWidget {
  final bool isDarkMode;
  final Color bg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onNavigateToResume;
  final String screenTitle;
  final String screenSubtitle;

  const JdEvaluationScreen({
    super.key,
    required this.isDarkMode,
    required this.bg,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    this.onNavigateToResume,
    this.screenTitle = 'JD Evaluation',
    this.screenSubtitle = 'Check if you\'re ready to apply for this role',
  });

  @override
  State<JdEvaluationScreen> createState() => _JdEvaluationScreenState();
}

class _JdEvaluationScreenState extends State<JdEvaluationScreen>
    with SingleTickerProviderStateMixin {
  // ── Step ──────────────────────────────────────────────────────────────────
  _EvalStep _step = _EvalStep.input;

  // ── Input state ───────────────────────────────────────────────────────────
  final _jdController = TextEditingController();
  String? _selectedResume;
  bool _uploadingResume = false;
  String? _inputError;

  // ── Quiz state ────────────────────────────────────────────────────────────
  List<_QuizQuestion> _questions = [];
  final Map<int, int?> _selectedAnswers = {}; // question index → option index
  int _correctCount = 0;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // ── Colors ────────────────────────────────────────────────────────────────
  Color get _accentGreen => const Color(0xFF16A34A);
  Color get _accentAmber => const Color(0xFFD97706);
  Color get _accentRed => const Color(0xFFDC2626);
  Color get _accentBlue => const Color(0xFF2563EB);
  Color get _pillBg =>
      widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _selectedResume = _mockResumes.first;
  }

  @override
  void dispose() {
    _jdController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────────────────────────────────

  void _onCanIApply() {
    final jd = _jdController.text.trim();
    if (jd.isEmpty) {
      setState(() => _inputError = 'Please enter the Job Description first.');
      return;
    }
    if (_selectedResume == null) {
      setState(() => _inputError = 'Please select or upload a resume.');
      return;
    }
    setState(() {
      _inputError = null;
      _questions = _generateMockQuestions(jd);
      _selectedAnswers.clear();
      _correctCount = 0;
      _step = _EvalStep.quiz;
    });
    _fadeController.forward(from: 0);
  }

  void _onSubmitQuiz() {
    // Validate all answered
    if (_selectedAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Please answer all 5 questions before submitting.'),
          backgroundColor: _accentAmber,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctIndex) correct++;
    }
    setState(() {
      _correctCount = correct;
      _step = _EvalStep.result;
    });
    _fadeController.forward(from: 0);
  }

  void _onReset() {
    setState(() {
      _step = _EvalStep.input;
      _jdController.clear();
      _selectedAnswers.clear();
      _questions = [];
      _inputError = null;
      _selectedResume = _mockResumes.first;
    });
    _fadeController.reset();
  }

  void _onRetakeQuiz() {
    setState(() {
      _selectedAnswers.clear();
      _correctCount = 0;
      _step = _EvalStep.quiz;
    });
    _fadeController.forward(from: 0);
  }

  Future<void> _onUploadResume() async {
    setState(() => _uploadingResume = true);
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 1));
    const fakeUploaded = 'my_resume_uploaded.pdf';
    if (mounted) {
      setState(() {
        _uploadingResume = false;
        _selectedResume = fakeUploaded;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Resume uploaded successfully!'),
          backgroundColor: _accentGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_step) {
      case _EvalStep.input:
        body = _buildInputView();
        break;
      case _EvalStep.quiz:
        body = FadeTransition(opacity: _fadeAnim, child: _buildQuizView());
        break;
      case _EvalStep.result:
        body = FadeTransition(opacity: _fadeAnim, child: _buildResultView());
        break;
    }
    return body;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STEP 1 – Input View
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.screenTitle == 'Quiz'
                          ? Icons.quiz_outlined
                          : Icons.verified_user_outlined,
                      color: _accentBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.screenTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.textPrimary,
                        ),
                      ),
                      Text(
                        widget.screenSubtitle,
                        style: TextStyle(
                            fontSize: 14, color: widget.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Step indicators
              _buildStepIndicator(currentStep: 0),
              const SizedBox(height: 28),

              // JD Input Card
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.article_outlined,
                            color: _accentBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Job Description',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: widget.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                                fontSize: 11,
                                color: _accentBlue,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paste the full job description to get a personalised 5-question screening quiz.',
                      style: TextStyle(
                          fontSize: 13, color: widget.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _jdController,
                      maxLines: 10,
                      style: TextStyle(
                          fontSize: 14,
                          color: widget.textPrimary,
                          height: 1.6),
                      decoration: InputDecoration(
                        hintText:
                            'Paste the job description here…\n\nInclude requirements, responsibilities, and qualifications for best results.',
                        hintStyle: TextStyle(
                            color: widget.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: widget.isDarkMode
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: widget.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: widget.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: _accentBlue, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      onChanged: (_) {
                        if (_inputError != null) {
                          setState(() => _inputError = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Resume selection card
              _buildResumeCard(),
              const SizedBox(height: 20),

              // Error
              if (_inputError != null) ...[
                _buildErrorBanner(_inputError!),
                const SizedBox(height: 16),
              ],

              // Can I Apply button
              _buildCanIApplyButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumeCard() {
    final availableResumes = List<String>.from(_mockResumes);
    if (_selectedResume != null &&
        !availableResumes.contains(_selectedResume)) {
      availableResumes.insert(0, _selectedResume!);
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  color: _accentGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Resume',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                      fontSize: 11,
                      color: _accentGreen,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select one of your existing resumes or upload a new one.',
            style:
                TextStyle(fontSize: 13, color: widget.textSecondary),
          ),
          const SizedBox(height: 16),

          // Resume list
          ...availableResumes.map((resume) {
            final isSelected = _selectedResume == resume;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedResume = resume),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _accentGreen.withOpacity(0.07)
                        : (widget.isDarkMode
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF9FAFB)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? _accentGreen
                          : widget.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        color: isSelected
                            ? _accentGreen
                            : widget.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          resume,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? widget.textPrimary
                                : widget.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: _accentGreen, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Upload button
          OutlinedButton.icon(
            onPressed: _uploadingResume ? null : _onUploadResume,
            icon: _uploadingResume
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _accentBlue),
                  )
                : Icon(Icons.upload_file_outlined,
                    size: 18, color: _accentBlue),
            label: Text(
              _uploadingResume ? 'Uploading…' : 'Upload New Resume',
              style: TextStyle(
                  color: _accentBlue, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _accentBlue.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanIApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _onCanIApply,
        icon: const Icon(Icons.quiz_outlined, size: 20),
        label: const Text(
          'Can I Apply?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STEP 2 – Quiz View
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildQuizView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + title
              _buildQuizHeader(),
              const SizedBox(height: 20),

              // Step indicator
              _buildStepIndicator(currentStep: 1),
              const SizedBox(height: 20),

              // Info banner
              _buildCard(
                bgColor: _accentBlue.withOpacity(0.06),
                borderColor: _accentBlue.withOpacity(0.2),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: _accentBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Answer all 5 questions and click Submit to see your chances of being shortlisted.',
                        style: TextStyle(
                            fontSize: 13,
                            color: widget.textPrimary,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Questions
              ..._questions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildQuestionCard(idx, q),
                );
              }),

              const SizedBox(height: 8),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onSubmitQuiz,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Submit Answers',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.textPrimary,
                    foregroundColor: widget.cardBg,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _step = _EvalStep.input;
            _fadeController.reset();
          }),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _pillBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded,
                    size: 16, color: widget.textSecondary),
                const SizedBox(width: 6),
                Text('Back',
                    style: TextStyle(
                        fontSize: 13, color: widget.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Screening Quiz',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.textPrimary,
                ),
              ),
              Text(
                '5 questions based on the Job Description',
                style:
                    TextStyle(fontSize: 13, color: widget.textSecondary),
              ),
            ],
          ),
        ),
        // Progress badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _pillBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_selectedAnswers.length} / ${_questions.length} answered',
            style: TextStyle(
                fontSize: 12,
                color: widget.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int idx, _QuizQuestion q) {
    final selected = _selectedAnswers[idx];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question number badge + text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected != null
                      ? _accentBlue
                      : _pillBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${idx + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected != null
                          ? Colors.white
                          : widget.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  q.question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Options
          ...q.options.asMap().entries.map((entry) {
            final optIdx = entry.key;
            final optText = entry.value;
            final isSelected = selected == optIdx;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedAnswers[idx] = optIdx;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _accentBlue.withOpacity(0.08)
                        : (widget.isDarkMode
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF9FAFB)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? _accentBlue
                          : widget.cardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? _accentBlue
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? _accentBlue
                                : widget.cardBorder,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          optText,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? widget.textPrimary
                                : widget.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
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

  // ─────────────────────────────────────────────────────────────────────────
  //  STEP 3 – Result View
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildResultView() {
    final verdict = _getVerdict(_correctCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: _onReset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _pillBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_outlined,
                              size: 16, color: widget.textSecondary),
                          const SizedBox(width: 6),
                          Text('Start Over',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: widget.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Your Result',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Step indicator
              _buildStepIndicator(currentStep: 2),
              const SizedBox(height: 24),

              // Score card
              _buildScoreCard(_correctCount, verdict),
              const SizedBox(height: 20),

              // Answer review
              _buildAnswerReview(),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onRetakeQuiz,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retake Quiz'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.textPrimary,
                        side: BorderSide(color: widget.cardBorder),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onReset,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Evaluate Another JD'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.textPrimary,
                        foregroundColor: widget.cardBg,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  _VerdictData _getVerdict(int correct) {
    if (correct > 3) {
      return _VerdictData(
        emoji: '🎉',
        title: 'You Can Apply!',
        subtitle:
            'Best chance for shortlisting — your profile aligns well with this role.',
        color: _accentGreen,
        bgColor: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFBBF7D0),
        label: 'Strong Match',
        labelBg: const Color(0xFFDCFCE7),
        labelText: const Color(0xFF16A34A),
      );
    } else if (correct == 3) {
      return _VerdictData(
        emoji: '👍',
        title: 'Moderate Chances',
        subtitle:
            'You have a moderate chance of selection — consider strengthening a few skills before applying.',
        color: _accentAmber,
        bgColor: const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        label: 'Moderate Match',
        labelBg: const Color(0xFFFEF9C3),
        labelText: const Color(0xFFD97706),
      );
    } else {
      return _VerdictData(
        emoji: '📚',
        title: 'Prepare Well & Apply',
        subtitle:
            'Very less chance for selection right now — prepare well on the gaps identified below and then apply.',
        color: _accentRed,
        bgColor: const Color(0xFFFEF3F2),
        borderColor: const Color(0xFFFEE4E2),
        label: 'Low Match',
        labelBg: const Color(0xFFFEE4E2),
        labelText: const Color(0xFFB42318),
      );
    }
  }

  Widget _buildScoreCard(int correct, _VerdictData v) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: v.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: v.borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Emoji + verdict label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(v.emoji, style: const TextStyle(fontSize: 40)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: v.labelBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  v.label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: v.labelText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Score display
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: v.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      v.subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: widget.textPrimary,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Circular score
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: v.color.withOpacity(0.1),
                  border: Border.all(color: v.color, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$correct/5',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: v.color,
                        ),
                      ),
                      Text(
                        'correct',
                        style: TextStyle(
                            fontSize: 10, color: v.color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: correct / 5,
              minHeight: 10,
              backgroundColor: v.color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(v.color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0 correct',
                  style: TextStyle(
                      fontSize: 12, color: widget.textSecondary)),
              Text('5 correct',
                  style: TextStyle(
                      fontSize: 12, color: widget.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerReview() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined,
                  color: widget.textPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Answer Review',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final userAnswer = _selectedAnswers[idx];
            final isCorrect = userAnswer == q.correctIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? _accentGreen.withOpacity(0.06)
                      : _accentRed.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCorrect
                        ? _accentGreen.withOpacity(0.3)
                        : _accentRed.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color:
                              isCorrect ? _accentGreen : _accentRed,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Q${idx + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCorrect
                                ? _accentGreen
                                : _accentRed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.question,
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isCorrect && userAnswer != null) ...[
                      _answerRow(
                          'Your answer:',
                          q.options[userAnswer],
                          _accentRed),
                      const SizedBox(height: 4),
                    ],
                    _answerRow(
                        'Correct answer:',
                        q.options[q.correctIndex],
                        _accentGreen),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _answerRow(String label, String answer, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.textSecondary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            answer,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Shared widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStepIndicator({required int currentStep}) {
    final steps = ['Enter JD & Resume', 'Answer Quiz', 'View Result'];
    return Row(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final label = entry.value;
        final isDone = idx < currentStep;
        final isActive = idx == currentStep;

        return Expanded(
          child: Row(
            children: [
              if (idx > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDone ? _accentBlue : widget.cardBorder,
                  ),
                ),
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? _accentBlue
                          : (isActive
                              ? _accentBlue.withOpacity(0.15)
                              : _pillBg),
                      border: Border.all(
                        color: (isDone || isActive)
                            ? _accentBlue
                            : widget.cardBorder,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? _accentBlue
                                    : widget.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color:
                          isActive ? _accentBlue : widget.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (idx < steps.length - 1) const SizedBox(width: 0),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCard({
    required Widget child,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor ?? widget.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: borderColor ?? widget.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        border: Border.all(color: const Color(0xFFFEE4E2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFB42318), size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFFB42318)))),
          GestureDetector(
            onTap: () => setState(() => _inputError = null),
            child: const Icon(Icons.close_rounded,
                size: 16, color: Color(0xFFB42318)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Verdict data class
// ─────────────────────────────────────────────────────────────────────────────

class _VerdictData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String label;
  final Color labelBg;
  final Color labelText;

  const _VerdictData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.label,
    required this.labelBg,
    required this.labelText,
  });
}
