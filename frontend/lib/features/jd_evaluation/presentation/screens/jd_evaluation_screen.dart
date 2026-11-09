import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../resume/data/datasources/resume_service.dart';
import '../../../resume/data/models/resume_model.dart';
import '../../data/datasources/jd_evaluation_service.dart';
import '../../data/models/quiz_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Screen Steps
// ─────────────────────────────────────────────────────────────────────────────

enum _EvalStep { input, quiz, result }

// ─────────────────────────────────────────────────────────────────────────────
//  Screen Widget
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
    this.screenSubtitle = "Check if you're ready to apply for this role",
  });

  @override
  State<JdEvaluationScreen> createState() => _JdEvaluationScreenState();
}

class _JdEvaluationScreenState extends State<JdEvaluationScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ───────────────────────────────────────────────────────────────
  final ResumeService _resumeService = ResumeService();
  final JdEvaluationService _evalService = JdEvaluationService();

  // ── Step ──────────────────────────────────────────────────────────────────
  _EvalStep _step = _EvalStep.input;

  // ── Resume State ──────────────────────────────────────────────────────────
  List<ResumeModel> _resumes = [];
  bool _loadingResumes = true;
  String? _selectedResumeFilename;
  bool _uploadingResume = false;

  // ── JD Input State ────────────────────────────────────────────────────────
  final _jdController = TextEditingController();
  String? _inputError;
  bool _generatingQuiz = false;

  // ── Quiz State ────────────────────────────────────────────────────────────
  String _roleTitle = 'Target Role';
  List<QuizQuestionModel> _questions = [];
  final Map<int, int?> _selectedAnswers = {}; // question index -> option index
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
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadResumes();
  }

  @override
  void dispose() {
    _jdController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Data Loading & Upload
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadResumes() async {
    setState(() => _loadingResumes = true);
    try {
      final list = await _resumeService.listResumes();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      if (mounted) {
        setState(() {
          _resumes = list;
          if (_selectedResumeFilename == null ||
              !list.any((r) => r.filename == _selectedResumeFilename)) {
            _selectedResumeFilename =
                list.isNotEmpty ? list.first.filename : null;
          }
          _loadingResumes = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingResumes = false);
      }
    }
  }

  Future<void> _onUploadResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final Uint8List? bytes = file.bytes;
      final String filename = file.name;

      if (bytes == null) {
        _showToast('Could not read file data. Please try again.', isError: true);
        return;
      }

      setState(() => _uploadingResume = true);

      final uploaded = await _resumeService.uploadResume(
        bytes: bytes,
        filename: filename,
      );

      await _loadResumes();

      if (mounted) {
        setState(() {
          _selectedResumeFilename = uploaded.filename;
          _uploadingResume = false;
          _inputError = null;
        });

        _showToast('Resume "${uploaded.filename}" uploaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingResume = false);
        _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _accentRed : _accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Can I Apply Validation & AI Quiz Generation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onCanIApply() async {
    final jd = _jdController.text.trim();

    // 1. Validate JD
    if (jd.isEmpty) {
      setState(() => _inputError = 'Please paste the Job Description first.');
      return;
    }
    if (jd.length < 30) {
      setState(() => _inputError =
          'Job description is too short (${jd.length} chars). Please enter at least 30 characters for an accurate evaluation.');
      return;
    }

    // 2. Validate selected resume
    if (_selectedResumeFilename == null || _selectedResumeFilename!.isEmpty) {
      setState(() => _inputError =
          'Please select or upload a resume to evaluate against this Job Description.');
      return;
    }

    setState(() {
      _inputError = null;
      _generatingQuiz = true;
    });

    try {
      final quizData = await _evalService.generateQuiz(
        resumeFilename: _selectedResumeFilename!,
        jdText: jd,
      );

      if (!mounted) return;

      setState(() {
        _generatingQuiz = false;
        _roleTitle = quizData.roleTitle;
        _questions = quizData.questions;
        _selectedAnswers.clear();
        _correctCount = 0;
        _step = _EvalStep.quiz;
      });
      _fadeController.forward(from: 0);

      // Open the interactive screening pop-up dialog
      _openQuizModalDialog();
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatingQuiz = false;
          _inputError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Modal Pop-up Dialog for 5 MCQs
  // ─────────────────────────────────────────────────────────────────────────

  void _openQuizModalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _ScreeningQuizDialog(
          isDarkMode: widget.isDarkMode,
          cardBg: widget.cardBg,
          cardBorder: widget.cardBorder,
          textPrimary: widget.textPrimary,
          textSecondary: widget.textSecondary,
          accentBlue: _accentBlue,
          accentGreen: _accentGreen,
          accentAmber: _accentAmber,
          accentRed: _accentRed,
          pillBg: _pillBg,
          roleTitle: _roleTitle,
          questions: _questions,
          initialAnswers: _selectedAnswers,
          onQuizSubmitted: (answers, correctCount) {
            setState(() {
              _selectedAnswers.clear();
              _selectedAnswers.addAll(answers);
              _correctCount = correctCount;
              _step = _EvalStep.result;
            });
            _fadeController.forward(from: 0);
          },
          onRetake: () {
            setState(() {
              _selectedAnswers.clear();
              _correctCount = 0;
              _step = _EvalStep.quiz;
            });
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Quiz Submission & Reset
  // ─────────────────────────────────────────────────────────────────────────

  void _onSubmitScreenQuiz() {
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
      if (_selectedAnswers[i] == _questions[i].correctIndex) {
        correct++;
      }
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
    _openQuizModalDialog();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Verdict Definition
  // ─────────────────────────────────────────────────────────────────────────

  _VerdictData _getVerdict(int correct) {
    if (correct >= 4) {
      return _VerdictData(
        emoji: '🎉',
        title: 'You Can Apply',
        subtitle:
            'Excellent score ($correct/5)! Your technical profile and competencies align well with this job description.',
        color: _accentGreen,
        bgColor: widget.isDarkMode
            ? const Color(0xFF052E16)
            : const Color(0xFFF0FDF4),
        borderColor: const Color(0xFF86EFAC),
        label: 'You Can Apply',
        labelBg: widget.isDarkMode
            ? const Color(0xFF14532D)
            : const Color(0xFFDCFCE7),
        labelText: const Color(0xFF16A34A),
      );
    } else if (correct == 3) {
      return _VerdictData(
        emoji: '⚖️',
        title: 'Moderate Chance',
        subtitle:
            'You scored 3/5. You have a moderate chance of moving forward. Reviewing the missed questions below will strengthen your interview performance.',
        color: _accentAmber,
        bgColor: widget.isDarkMode
            ? const Color(0xFF451A03)
            : const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        label: 'Moderate Chance',
        labelBg: widget.isDarkMode
            ? const Color(0xFF78350F)
            : const Color(0xFFFEF9C3),
        labelText: const Color(0xFFD97706),
      );
    } else {
      return _VerdictData(
        emoji: '📚',
        title: 'Prepare and Apply',
        subtitle:
            'You scored $correct/5. There are key technical gaps identified. We recommend preparing on the highlighted areas before submitting your application.',
        color: _accentRed,
        bgColor: widget.isDarkMode
            ? const Color(0xFF450A0A)
            : const Color(0xFFFEF3F2),
        borderColor: const Color(0xFFFCA5A5),
        label: 'Prepare and Apply',
        labelBg: widget.isDarkMode
            ? const Color(0xFF7F1D1D)
            : const Color(0xFFFEE4E2),
        labelText: const Color(0xFFDC2626),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Main Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _EvalStep.input:
        return _buildInputView();
      case _EvalStep.quiz:
        return FadeTransition(opacity: _fadeAnim, child: _buildQuizView());
      case _EvalStep.result:
        return FadeTransition(opacity: _fadeAnim, child: _buildResultView());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STEP 1 – Input View
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _accentBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.quiz_outlined,
                      color: _accentBlue,
                      size: 24,
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
              const SizedBox(height: 24),

              // Step Indicator
              _buildStepIndicator(currentStep: 0),
              const SizedBox(height: 24),

              // Resume Selection & Upload Card
              _buildResumeCard(),
              const SizedBox(height: 20),

              // JD Input Card
              _buildJdCard(),
              const SizedBox(height: 20),

              // Error Banner
              if (_inputError != null) ...[
                _buildErrorBanner(_inputError!),
                const SizedBox(height: 18),
              ],

              // Can I Apply Button
              _buildCanIApplyButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Resume Card (Real API Resumes + Upload)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildResumeCard() {
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
                'Candidate Resume',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 11,
                    color: _accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (!_loadingResumes)
                Text(
                  '${_resumes.length} uploaded',
                  style: TextStyle(fontSize: 12, color: widget.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select an already uploaded resume or upload a new one to evaluate against the JD.',
            style: TextStyle(fontSize: 13, color: widget.textSecondary),
          ),
          const SizedBox(height: 16),

          // Loading state
          if (_loadingResumes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accentBlue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Fetching your uploaded resumes…',
                      style: TextStyle(
                          fontSize: 13, color: widget.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          // Empty State
          else if (_resumes.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.cardBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 36, color: widget.textSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'No resumes uploaded yet',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload your resume below to generate personalized screening questions.',
                    style: TextStyle(
                        fontSize: 12, color: widget.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          // List of available resumes
          else
            ..._resumes.map((resume) {
              final isSelected = _selectedResumeFilename == resume.filename;
              final uploadDate = DateTime.fromMillisecondsSinceEpoch(
                  (resume.uploadedAt * 1000).toInt());
              final formattedDate =
                  DateFormat('dd MMM yyyy, hh:mm a').format(uploadDate);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedResumeFilename = resume.filename;
                      _inputError = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _accentGreen.withOpacity(0.08)
                          : (widget.isDarkMode
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF9FAFB)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? _accentGreen : widget.cardBorder,
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
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resume.filename,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? widget.textPrimary
                                      : widget.textPrimary.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${resume.displaySize} • Uploaded $formattedDate',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? _accentGreen
                              : widget.textSecondary.withOpacity(0.5),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 10),

          // Upload New Resume Button
          OutlinedButton.icon(
            onPressed: _uploadingResume ? null : _onUploadResume,
            icon: _uploadingResume
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accentBlue,
                    ),
                  )
                : Icon(Icons.upload_file_outlined,
                    size: 18, color: _accentBlue),
            label: Text(
              _uploadingResume ? 'Uploading Resume…' : 'Upload New Resume',
              style: TextStyle(
                color: _accentBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _accentBlue.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Job Description Input Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildJdCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined, color: _accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Job Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 11,
                    color: _accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Paste the full job description. The AI will formulate 5 targeted technical screening MCQs based on the requirements.',
            style: TextStyle(fontSize: 13, color: widget.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _jdController,
            maxLines: 9,
            style: TextStyle(
              fontSize: 14,
              color: widget.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Paste the job description here…\n\nInclude required skills, tech stack, key responsibilities, and experience requirements.',
              hintStyle:
                  TextStyle(color: widget.textSecondary, fontSize: 13),
              filled: true,
              fillColor: widget.isDarkMode
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _accentBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) {
              if (_inputError != null) {
                setState(() => _inputError = null);
              }
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Can I Apply Button
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCanIApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generatingQuiz ? null : _onCanIApply,
        icon: _generatingQuiz
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.quiz_outlined, size: 20),
        label: Text(
          _generatingQuiz
              ? 'Generating 5 Screening Questions with LLM…'
              : 'Can I Apply? (Take 5-MCQ Quiz)',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _accentBlue.withOpacity(0.6),
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STEP 2 – Full Screen Quiz View (Fallback or Direct View)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildQuizView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuizHeader(),
              const SizedBox(height: 20),
              _buildStepIndicator(currentStep: 1),
              const SizedBox(height: 20),

              // Pop-up launcher helper banner
              _buildCard(
                bgColor: _accentBlue.withOpacity(0.08),
                borderColor: _accentBlue.withOpacity(0.2),
                child: Row(
                  children: [
                    Icon(Icons.launch_rounded, color: _accentBlue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pop-up quiz active for "$_roleTitle". You can answer in the pop-up or right here on the page.',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openQuizModalDialog,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open Pop-up'),
                      style: TextButton.styleFrom(foregroundColor: _accentBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Questions List
              ..._questions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildQuestionCard(idx, q),
                );
              }),

              const SizedBox(height: 12),

              // Submit Answers Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onSubmitScreenQuiz,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Submit Answers & View Evaluation',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
              const SizedBox(height: 24),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                'Role: $_roleTitle (5 LLM-Generated MCQs)',
                style:
                    TextStyle(fontSize: 13, color: widget.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _pillBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_selectedAnswers.length} / ${_questions.length} answered',
            style: TextStyle(
              fontSize: 12,
              color: widget.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int idx, QuizQuestionModel q) {
    final selected = _selectedAnswers[idx];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected != null ? _accentBlue : _pillBg,
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...q.options.asMap().entries.map((entry) {
            final optIdx = entry.key;
            final optText = entry.value;
            final isSelected = selected == optIdx;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedAnswers[idx] = optIdx;
                  });
                },
                borderRadius: BorderRadius.circular(10),
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
                      color: isSelected ? _accentBlue : widget.cardBorder,
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
          constraints: const BoxConstraints(maxWidth: 780),
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
                          horizontal: 12, vertical: 8),
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
                    'Evaluation Result: $_roleTitle',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildStepIndicator(currentStep: 2),
              const SizedBox(height: 24),

              // Score & Verdict Card
              _buildScoreCard(_correctCount, verdict),
              const SizedBox(height: 20),

              // Detailed Answer & Explanation Review
              _buildAnswerReview(),
              const SizedBox(height: 20),

              // Action Buttons
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(int correct, _VerdictData v) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: v.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: v.borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(v.emoji, style: const TextStyle(fontSize: 38)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: v.labelBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  v.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: v.labelText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: v.color.withOpacity(0.12),
                  border: Border.all(color: v.color, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$correct/5',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: v.color,
                        ),
                      ),
                      Text(
                        'correct',
                        style: TextStyle(fontSize: 11, color: v.color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
              Text('0/5 (Prepare)',
                  style:
                      TextStyle(fontSize: 12, color: widget.textSecondary)),
              Text('3/5 (Moderate)',
                  style:
                      TextStyle(fontSize: 12, color: widget.textSecondary)),
              Text('5/5 (Apply)',
                  style:
                      TextStyle(fontSize: 12, color: widget.textSecondary)),
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
                'Answer Review & Explanations',
                style: TextStyle(
                  fontSize: 16,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isCorrect ? _accentGreen : _accentRed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Q${idx + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCorrect ? _accentGreen : _accentRed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            q.question,
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (!isCorrect && userAnswer != null) ...[
                      _answerRow('Your answer:', q.options[userAnswer],
                          _accentRed),
                      const SizedBox(height: 4),
                    ],
                    _answerRow('Correct answer:',
                        q.options[q.correctIndex], _accentGreen),
                    if (q.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.cardBg.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 14, color: _accentAmber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                q.explanation,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
            color: widget.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Shared UI
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStepIndicator({required int currentStep}) {
    final steps = ['Enter JD & Resume', '5-MCQ Quiz', 'Evaluation Result'];
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
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.normal,
                      color: isActive ? _accentBlue : widget.textSecondary,
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
            child: Text(
              msg,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFFB42318)),
            ),
          ),
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
//  Screening Quiz Dialog (Modal Pop-Up for 5 MCQs)
// ─────────────────────────────────────────────────────────────────────────────

class _ScreeningQuizDialog extends StatefulWidget {
  final bool isDarkMode;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentBlue;
  final Color accentGreen;
  final Color accentAmber;
  final Color accentRed;
  final Color pillBg;
  final String roleTitle;
  final List<QuizQuestionModel> questions;
  final Map<int, int?> initialAnswers;
  final Function(Map<int, int?> answers, int correctCount) onQuizSubmitted;
  final VoidCallback onRetake;

  const _ScreeningQuizDialog({
    required this.isDarkMode,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentBlue,
    required this.accentGreen,
    required this.accentAmber,
    required this.accentRed,
    required this.pillBg,
    required this.roleTitle,
    required this.questions,
    required this.initialAnswers,
    required this.onQuizSubmitted,
    required this.onRetake,
  });

  @override
  State<_ScreeningQuizDialog> createState() => _ScreeningQuizDialogState();
}

class _ScreeningQuizDialogState extends State<_ScreeningQuizDialog> {
  final Map<int, int?> _answers = {};
  bool _submitted = false;
  int _correctCount = 0;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _answers.addAll(widget.initialAnswers);
  }

  void _submit() {
    if (_answers.length < widget.questions.length) {
      setState(() {
        _validationError =
            'Please answer all ${widget.questions.length} questions before submitting.';
      });
      return;
    }

    int correct = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (_answers[i] == widget.questions[i].correctIndex) {
        correct++;
      }
    }

    setState(() {
      _validationError = null;
      _submitted = true;
      _correctCount = correct;
    });

    widget.onQuizSubmitted(_answers, correct);
  }

  void _retake() {
    setState(() {
      _answers.clear();
      _submitted = false;
      _correctCount = 0;
      _validationError = null;
    });
    widget.onRetake();
  }

  _VerdictData _dialogVerdict(int correct) {
    if (correct >= 4) {
      return _VerdictData(
        emoji: '🎉',
        title: 'You Can Apply',
        subtitle:
            'Excellent score of $correct/5! Your skills and technical knowledge align closely with this job description.',
        color: widget.accentGreen,
        bgColor: widget.isDarkMode
            ? const Color(0xFF052E16)
            : const Color(0xFFF0FDF4),
        borderColor: const Color(0xFF86EFAC),
        label: 'You Can Apply',
        labelBg: widget.isDarkMode
            ? const Color(0xFF14532D)
            : const Color(0xFFDCFCE7),
        labelText: const Color(0xFF16A34A),
      );
    } else if (correct == 3) {
      return _VerdictData(
        emoji: '⚖️',
        title: 'Moderate Chance',
        subtitle:
            'You scored 3/5. You have a moderate chance of being shortlisted. Review the missed concepts below to improve.',
        color: widget.accentAmber,
        bgColor: widget.isDarkMode
            ? const Color(0xFF451A03)
            : const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        label: 'Moderate Chance',
        labelBg: widget.isDarkMode
            ? const Color(0xFF78350F)
            : const Color(0xFFFEF9C3),
        labelText: const Color(0xFFD97706),
      );
    } else {
      return _VerdictData(
        emoji: '📚',
        title: 'Prepare and Apply',
        subtitle:
            'You scored $correct/5. We recommend strengthening your preparation on the key technical topics below before applying.',
        color: widget.accentRed,
        bgColor: widget.isDarkMode
            ? const Color(0xFF450A0A)
            : const Color(0xFFFEF3F2),
        borderColor: const Color(0xFFFCA5A5),
        label: 'Prepare and Apply',
        labelBg: widget.isDarkMode
            ? const Color(0xFF7F1D1D)
            : const Color(0xFFFEE4E2),
        labelText: const Color(0xFFDC2626),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: widget.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: widget.cardBorder),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.accentBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.quiz_outlined,
                        color: widget.accentBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _submitted
                              ? 'Quiz Evaluation Result'
                              : 'Screening Quiz: ${widget.roleTitle}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: widget.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _submitted
                              ? 'Scoring verdict & question breakdown'
                              : '5 Multiple Choice Questions based on JD',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_submitted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.pillBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_answers.length}/${widget.questions.length} answered',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: widget.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _submitted ? _buildDialogResultView() : _buildDialogQuestionsView(),
              ),
            ),

            // Dialog Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: widget.cardBorder),
                ),
              ),
              child: _submitted ? _buildResultFooter() : _buildQuizFooter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogQuestionsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_validationError != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFEE4E2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFB42318), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _validationError!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFB42318)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        ...widget.questions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          final selected = _answers[idx];

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: selected != null
                            ? widget.accentBlue
                            : widget.pillBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 12,
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
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...q.options.asMap().entries.map((optEntry) {
                  final optIdx = optEntry.key;
                  final optText = optEntry.value;
                  final isSelected = selected == optIdx;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _answers[idx] = optIdx;
                          _validationError = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.accentBlue.withOpacity(0.08)
                              : widget.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? widget.accentBlue
                                : widget.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? widget.accentBlue
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? widget.accentBlue
                                      : widget.cardBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 11, color: Colors.white)
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
        }),
      ],
    );
  }

  Widget _buildDialogResultView() {
    final v = _dialogVerdict(_correctCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: v.bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: v.borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(v.emoji, style: const TextStyle(fontSize: 32)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: v.labelBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      v.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: v.labelText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: v.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          v.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: widget.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: v.color.withOpacity(0.12),
                      border: Border.all(color: v.color, width: 2.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_correctCount/5',
                            style: TextStyle(
                              fontSize: 19,
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
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _correctCount / 5,
                  minHeight: 8,
                  backgroundColor: v.color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(v.color),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Detailed Review & Explanations',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: widget.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        ...widget.questions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          final userAns = _answers[idx];
          final isCorrect = userAns == q.correctIndex;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCorrect
                  ? widget.accentGreen.withOpacity(0.06)
                  : widget.accentRed.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCorrect
                    ? widget.accentGreen.withOpacity(0.3)
                    : widget.accentRed.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: isCorrect
                          ? widget.accentGreen
                          : widget.accentRed,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Q${idx + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCorrect
                            ? widget.accentGreen
                            : widget.accentRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.question,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!isCorrect && userAns != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your answer: ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          q.options[userAns],
                          style: TextStyle(
                              fontSize: 12,
                              color: widget.accentRed,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct answer: ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.textSecondary),
                    ),
                    Expanded(
                      child: Text(
                        q.options[q.correctIndex],
                        style: TextStyle(
                            fontSize: 12,
                            color: widget.accentGreen,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (q.explanation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.cardBg.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            size: 13, color: widget.accentAmber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            q.explanation,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuizFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.textSecondary,
            side: BorderSide(color: widget.cardBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text(
            'Submit Quiz',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildResultFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _retake,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retake Quiz'),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.textPrimary,
            side: BorderSide(color: widget.cardBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.textPrimary,
            foregroundColor: widget.cardBg,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text(
            'Done / Close',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Verdict Model
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
