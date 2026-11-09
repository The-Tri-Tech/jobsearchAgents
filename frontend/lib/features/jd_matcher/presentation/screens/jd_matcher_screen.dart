import 'package:flutter/material.dart';
import '../../data/datasources/jd_matcher_service.dart';
import '../../data/models/jd_matcher_model.dart';
import '../../../resume/data/datasources/resume_service.dart';
import '../../../resume/data/models/resume_model.dart';

class JdMatcherScreen extends StatefulWidget {
  final bool isDarkMode;
  final Color bg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onNavigateToResume;
  final VoidCallback? onFollowUpCreated;

  const JdMatcherScreen({
    super.key,
    required this.isDarkMode,
    required this.bg,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    this.onNavigateToResume,
    this.onFollowUpCreated,
  });

  @override
  State<JdMatcherScreen> createState() => _JdMatcherScreenState();
}

class _JdMatcherScreenState extends State<JdMatcherScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ───────────────────────────────────────────────────────────────
  final JdMatcherService _matcherService = JdMatcherService();
  final ResumeService _resumeService = ResumeService();

  // ── State ──────────────────────────────────────────────────────────────────
  List<ResumeModel> _resumes = [];
  bool _loadingResumes = true;
  String? _selectedResumeFilename;

  // JD input
  int _jdInputMode = 0; // 0 = paste text, 1 = url
  final _jdTextController = TextEditingController();
  final _jdUrlController = TextEditingController();

  // Analysis
  bool _analysing = false;
  String? _errorMessage;
  AnalysisReportModel? _report;
  bool _schedulingFollowUp = false;
  bool _followUpEnabled = false;
  String _applicationStatus = 'not_applied';
  bool _updatingStatus = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadResumes();
  }

  @override
  void dispose() {
    _jdTextController.dispose();
    _jdUrlController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadResumes() async {
    setState(() => _loadingResumes = true);
    try {
      final list = await _resumeService.listResumes();
      list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      setState(() {
        _resumes = list;
        if (!list.any((resume) => resume.filename == _selectedResumeFilename)) {
          _selectedResumeFilename =
              list.isNotEmpty ? list.first.filename : null;
        }
        _loadingResumes = false;
      });
    } catch (_) {
      setState(() => _loadingResumes = false);
    }
  }

  ResumeModel? get _selectedResume {
    if (_selectedResumeFilename == null) return null;
    for (final resume in _resumes) {
      if (resume.filename == _selectedResumeFilename) return resume;
    }
    return null;
  }

  Future<void> _analyse() async {
    final resume = _selectedResume;
    if (resume == null) return;

    final jdText = _jdTextController.text.trim();
    final jdUrl = _jdUrlController.text.trim();

    if (_jdInputMode == 0 && jdText.isEmpty) {
      setState(() => _errorMessage = 'Please paste the Job Description text.');
      return;
    }
    if (_jdInputMode == 1) {
      if (jdUrl.isEmpty) {
        setState(
            () => _errorMessage = 'Please enter a valid Job Description URL.');
        return;
      }

      final normalized = jdUrl.startsWith('http://') || jdUrl.startsWith('https://')
          ? jdUrl
          : 'https://$jdUrl';

      final uri = Uri.tryParse(normalized);
      final host = uri?.host.toLowerCase() ?? '';

      if (uri == null || host.isEmpty || !host.contains('.')) {
        setState(() => _errorMessage =
            'Please enter a valid URL (e.g. https://company.com/jobs/123).');
        return;
      }

      if (host.contains('linkedin.com')) {
        final hasJobId = RegExp(r'\d{6,}').hasMatch(normalized);
        if (!hasJobId) {
          setState(() => _errorMessage =
              'Please enter a specific LinkedIn job link (e.g. https://www.linkedin.com/jobs/view/1234567890).');
          return;
        }
      } else if (host.contains('indeed.com') ||
          host.contains('glassdoor.com') ||
          host.contains('naukri.com') ||
          host.contains('ziprecruiter.com')) {
        setState(() => _errorMessage =
            'This job board requires authentication or blocks page reading. Please copy the job description text into "Paste JD Text" instead.');
        return;
      }
    }

    setState(() {
      _analysing = true;
      _errorMessage = null;
      _report = null;
      _followUpEnabled = false;
      _applicationStatus = 'not_applied';
    });

    try {
      final result = await _matcherService.analyse(
        jdText: _jdInputMode == 0 ? jdText : null,
        jdUrl: _jdInputMode == 1 ? jdUrl : null,
        resumeFilename: resume.filename,
      );
      setState(() {
        _report = result;
        _applicationStatus = result.applicationStatus;
        _analysing = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _analysing = false;
      });
    }
  }

  void _resetToInput() {
    setState(() {
      _report = null;
      _errorMessage = null;
      _followUpEnabled = false;
      _applicationStatus = 'not_applied';
    });
    _fadeController.reset();
  }

  Future<void> _showFollowUpDialog(AnalysisReportModel report) async {
    DateTime selectedDate = DateTime.now();
    int selectedDays = 3;
    final initialTitle =
        report.jobTitle.isNotEmpty && report.jobTitle != 'Target Role'
            ? report.jobTitle
            : (report.recommendedRoles.isNotEmpty
                ? report.recommendedRoles.first.title
                : 'Target Job Role');
    final titleController = TextEditingController(text: initialTitle);

    final selection = await showDialog<_FollowUpSelection>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.cardBg,
          title: Text('Enable follow-up',
              style: TextStyle(color: widget.textPrimary)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set the job title and follow-up timeline for your dashboard.',
                  style: TextStyle(fontSize: 13, color: widget.textSecondary),
                ),
                const SizedBox(height: 18),
                Text('Job Title / Role',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: widget.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Senior Software Engineer',
                    hintStyle: TextStyle(
                        color: widget.textSecondary.withOpacity(0.6)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: widget.textPrimary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Application date',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 17),
                  label: Text(_formatDate(selectedDate)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.textPrimary,
                    side: BorderSide(color: widget.cardBorder),
                    minimumSize: const Size(double.infinity, 46),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Follow up after',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: selectedDays,
                  dropdownColor: widget.cardBg,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.cardBorder),
                    ),
                  ),
                  style: TextStyle(color: widget.textPrimary),
                  items: [1, 2, 3, 5, 7, 10, 14, 30]
                      .map((days) => DropdownMenuItem(
                            value: days,
                            child: Text('$days ${days == 1 ? 'day' : 'days'}'),
                          ))
                      .toList(),
                  onChanged: (days) =>
                      setDialogState(() => selectedDays = days ?? 3),
                ),
                const SizedBox(height: 14),
                Text(
                  'Follow-up date: ${_formatDate(selectedDate.add(Duration(days: selectedDays)))}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _accentGreen),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  Text('Cancel', style: TextStyle(color: widget.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final chosenTitle = titleController.text.trim().isNotEmpty
                    ? titleController.text.trim()
                    : initialTitle;
                Navigator.pop(
                  dialogContext,
                  _FollowUpSelection(chosenTitle, selectedDate, selectedDays),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.textPrimary,
                foregroundColor: widget.cardBg,
              ),
              child: const Text('Enable follow-up'),
            ),
          ],
        ),
      ),
    );
    if (selection == null || !mounted) return;

    setState(() => _schedulingFollowUp = true);
    try {
      await _matcherService.createFollowUp(
        reportTitle: selection.jobTitle,
        resumeFilename: report.resumeUsed,
        applicationDate: selection.date,
        followUpAfterDays: selection.days,
      );
      if (!mounted) return;
      setState(() {
        _schedulingFollowUp = false;
        _followUpEnabled = true;
        _applicationStatus = 'applied';
      });
      if (report.analysisId != null) {
        _matcherService
            .updateApplicationStatus(
              analysisId: report.analysisId!,
              status: 'applied',
            )
            .catchError((_) {});
      }
      widget.onFollowUpCreated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Follow-up scheduled for ${_formatDate(selection.date.add(Duration(days: selection.days)))}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _schedulingFollowUp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _accentRed,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
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

  // ── Colours ────────────────────────────────────────────────────────────────

  Color get _accentGreen => const Color(0xFF16A34A);
  Color get _accentRed => const Color(0xFFDC2626);
  Color get _accentBlue => const Color(0xFF2563EB);
  Color get _accentAmber => const Color(0xFFD97706);
  Color get _pillBg =>
      widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7);

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_report != null) {
      return FadeTransition(
        opacity: _fadeAnim,
        child: _buildReport(_report!),
      );
    }
    return _buildInputView();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INPUT VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Text(
                'JD Matcher',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Paste a Job Description or enter its URL, then click Analyse to see how well your resume matches.',
                style: TextStyle(fontSize: 14, color: widget.textSecondary),
              ),
              const SizedBox(height: 28),

              // ── Resume banner ────────────────────────────────────────────
              _buildResumeBanner(),
              const SizedBox(height: 24),

              // ── JD input card ────────────────────────────────────────────
              _buildJdInputCard(),
              const SizedBox(height: 20),

              // ── Error ────────────────────────────────────────────────────
              if (_errorMessage != null) ...[
                _buildErrorBanner(_errorMessage!),
                const SizedBox(height: 16),
              ],

              // ── Analyse button ───────────────────────────────────────────
              _buildAnalyseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumeBanner() {
    if (_loadingResumes) {
      return _card(
        child: Row(
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: widget.textSecondary)),
            const SizedBox(width: 12),
            Text('Loading resumes…',
                style: TextStyle(color: widget.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    final resume = _selectedResume;
    if (resume == null) {
      return _card(
        bgColor: const Color(0xFFFEF9C3),
        borderColor: const Color(0xFFFDE047),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFCA8A04), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No resume uploaded',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF713F12),
                        fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Upload a resume first to run JD matching.',
                    style: TextStyle(color: Color(0xFF713F12), fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: widget.onNavigateToResume,
              child: const Text('Upload →',
                  style: TextStyle(
                      color: Color(0xFFCA8A04), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return _card(
      bgColor: const Color(0xFFF0FDF4),
      borderColor: const Color(0xFFBBF7D0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_rounded,
                    color: _accentGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume for this analysis',
                      style: TextStyle(
                          fontSize: 14,
                          color: widget.textPrimary,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_resumes.length} resume${_resumes.length == 1 ? '' : 's'} available',
                      style:
                          TextStyle(fontSize: 12, color: widget.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey(resume.filename),
            initialValue: resume.filename,
            isExpanded: true,
            dropdownColor: widget.cardBg,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: widget.textSecondary),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.cardBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                borderSide: BorderSide(color: _accentGreen, width: 1.5),
              ),
            ),
            selectedItemBuilder: (context) => _resumes
                .map((item) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${item.filename}  ·  ${item.displaySize}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.textPrimary),
                      ),
                    ))
                .toList(),
            items: _resumes
                .map((item) => DropdownMenuItem<String>(
                      value: item.filename,
                      child: Text(
                        '${item.filename}  ·  ${item.displaySize}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 14, color: widget.textPrimary),
                      ),
                    ))
                .toList(),
            onChanged: _analysing
                ? null
                : (filename) => setState(() {
                      _selectedResumeFilename = filename;
                      _errorMessage = null;
                    }),
          ),
          if (_resumes.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              'The newest resume is selected initially. Choose another to compare it with this job.',
              style: TextStyle(fontSize: 12, color: widget.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJdInputCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle tabs
          Row(
            children: [
              _modeTab(label: 'Paste JD Text', index: 0),
              const SizedBox(width: 8),
              _modeTab(label: 'Enter JD URL', index: 1),
            ],
          ),
          const SizedBox(height: 20),

          // Input area
          if (_jdInputMode == 0)
            TextField(
              controller: _jdTextController,
              maxLines: 10,
              style: TextStyle(
                  fontSize: 14, color: widget.textPrimary, height: 1.6),
              decoration: InputDecoration(
                hintText:
                    'Paste the full job description here…\n\nInclude requirements, responsibilities, and qualifications for best results.',
                hintStyle: TextStyle(color: widget.textSecondary, fontSize: 13),
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
                  borderSide: BorderSide(color: widget.textPrimary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            )
          else
            TextField(
              controller: _jdUrlController,
              style: TextStyle(fontSize: 14, color: widget.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://www.linkedin.com/jobs/view/…',
                hintStyle: TextStyle(color: widget.textSecondary, fontSize: 13),
                prefixIcon: Icon(Icons.link_rounded,
                    color: widget.textSecondary, size: 20),
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
                  borderSide: BorderSide(color: widget.textPrimary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _modeTab({required String label, required int index}) {
    final active = _jdInputMode == index;
    return GestureDetector(
      onTap: () => setState(() {
        _jdInputMode = index;
        _errorMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? widget.textPrimary : _pillBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? widget.cardBg : widget.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyseButton() {
    final hasResume = _selectedResume != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _analysing || !hasResume ? null : _analyse,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.textPrimary,
          foregroundColor: widget.cardBg,
          disabledBackgroundColor: widget.textSecondary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _analysing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: widget.cardBg),
                  ),
                  const SizedBox(width: 10),
                  const Text('Analysing…',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Analyse',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
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
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFFB42318)))),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close_rounded,
                size: 16, color: Color(0xFFB42318)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  REPORT VIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildReport(AnalysisReportModel r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Back button + title ─────────────────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: _resetToInput,
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
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Match Report',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.textPrimary),
                ),
              ),
              _buildApplicationStatusDropdown(r),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _schedulingFollowUp || _followUpEnabled
                    ? null
                    : () => _showFollowUpDialog(r),
                icon: _schedulingFollowUp
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_followUpEnabled
                        ? Icons.check_circle_outline
                        : Icons.notifications_active_outlined),
                label:
                    Text(_followUpEnabled ? 'Follow-up enabled' : 'Follow up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.textPrimary,
                  foregroundColor: widget.cardBg,
                  disabledBackgroundColor: _accentGreen.withOpacity(0.12),
                  disabledForegroundColor: _accentGreen,
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Resume: ${r.resumeUsed}  ·  Source: ${r.jdSource == 'url' ? 'JD URL' : 'Pasted text'}',
            style: TextStyle(fontSize: 13, color: widget.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Shortlisting chance hero ────────────────────────────────────
          _buildShortlistingHero(r.shortlistingChance),
          const SizedBox(height: 28),

          // ── Section 1: Matched vs Missing ───────────────────────────────
          _sectionLabel('1', 'Skills Gap Analysis'),
          const SizedBox(height: 14),
          _buildSkillsSection(r),
          const SizedBox(height: 28),

          // ── Section 2: Summary ──────────────────────────────────────────
          _sectionLabel('2', 'Overall Summary'),
          const SizedBox(height: 14),
          _buildSummarySection(r),
          const SizedBox(height: 28),

          // ── Section 3: Recommended roles ────────────────────────────────
          _sectionLabel('3', 'Recommended Roles'),
          const SizedBox(height: 14),
          _buildRolesSection(r),
          const SizedBox(height: 32),

          // ── Re-analyse ──────────────────────────────────────────────────
          Center(
            child: TextButton.icon(
              onPressed: _resetToInput,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Analyse a different JD'),
              style:
                  TextButton.styleFrom(foregroundColor: widget.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onApplicationStatusChanged(
      AnalysisReportModel report, String newStatus) async {
    setState(() {
      _applicationStatus = newStatus;
      _updatingStatus = true;
    });

    try {
      if (report.analysisId != null) {
        await _matcherService.updateApplicationStatus(
          analysisId: report.analysisId!,
          status: newStatus,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'applied'
                ? 'Application status updated: Applied'
                : 'Application status updated: Not Applied',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: newStatus == 'applied'
              ? const Color(0xFF16A34A)
              : widget.textPrimary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to update status: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: _accentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingStatus = false);
      }
    }
  }

  Widget _buildApplicationStatusDropdown(AnalysisReportModel r) {
    final isApplied = _applicationStatus == 'applied';
    const appliedColor = Color(0xFF16A34A);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isApplied
            ? appliedColor.withValues(alpha: 0.1)
            : widget.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isApplied ? appliedColor : widget.cardBorder,
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _applicationStatus,
          dropdownColor: widget.cardBg,
          borderRadius: BorderRadius.circular(10),
          icon: _updatingStatus
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isApplied ? appliedColor : widget.textSecondary,
                ),
          items: [
            DropdownMenuItem(
              value: 'not_applied',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.radio_button_unchecked,
                      size: 14, color: widget.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Not Applied',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'applied',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: appliedColor),
                  const SizedBox(width: 8),
                  Text(
                    'Applied',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isApplied ? appliedColor : widget.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: _updatingStatus
              ? null
              : (val) {
                  if (val != null && val != _applicationStatus) {
                    _onApplicationStatusChanged(r, val);
                  }
                },
        ),
      ),
    );
  }

  // ── Shortlisting hero ──────────────────────────────────────────────────────

  Widget _buildShortlistingHero(int chance) {
    final Color heroColor;
    final String heroLabel;
    if (chance >= 75) {
      heroColor = _accentGreen;
      heroLabel = 'High chance';
    } else if (chance >= 50) {
      heroColor = _accentAmber;
      heroLabel = 'Moderate chance';
    } else {
      heroColor = _accentRed;
      heroLabel = 'Low chance';
    }

    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular progress indicator + % label
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: chance / 100,
                    strokeWidth: 7,
                    backgroundColor: widget.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(heroColor),
                  ),
                ),
                Text(
                  '$chance%',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: heroColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: heroColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        heroLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: heroColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Shortlisting Chance',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on keyword match, skill overlap and profile alignment.',
                  style: TextStyle(fontSize: 13, color: widget.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 1: Skills ──────────────────────────────────────────────────────

  Widget _buildSkillsSection(AnalysisReportModel r) {
    final isWide = MediaQuery.of(context).size.width >= 760;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildMatchedColumn(r.matchedSkills)),
          const SizedBox(width: 16),
          Expanded(child: _buildMissingColumn(r.missingSkills)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildMatchedColumn(r.matchedSkills),
          const SizedBox(height: 16),
          _buildMissingColumn(r.missingSkills),
        ],
      );
    }
  }

  Widget _buildMatchedColumn(List<MatchedSkillModel> skills) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: _accentGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'What Matched (${skills.length})',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...skills.map((s) => _skillRow(
                skill: s.skill,
                subtitle: s.context,
                iconColor: _accentGreen,
                icon: Icons.check_rounded,
                pillBg: _accentGreen.withOpacity(0.08),
              )),
        ],
      ),
    );
  }

  Widget _buildMissingColumn(List<MissingSkillModel> skills) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_rounded, color: _accentRed, size: 18),
              const SizedBox(width: 8),
              Text(
                'What\'s Missing (${skills.length})',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...skills.map((s) {
            final importanceColor = s.importance == 'High'
                ? _accentRed
                : s.importance == 'Medium'
                    ? _accentAmber
                    : widget.textSecondary;
            return _skillRow(
              skill: s.skill,
              subtitle: '${s.importance} priority',
              subtitleColor: importanceColor,
              iconColor: importanceColor,
              icon: Icons.close_rounded,
              pillBg: importanceColor.withOpacity(0.08),
            );
          }),
        ],
      ),
    );
  }

  Widget _skillRow({
    required String skill,
    String? subtitle,
    Color? subtitleColor,
    required Color iconColor,
    required IconData icon,
    required Color pillBg,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: pillBg, shape: BoxShape.circle),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(skill,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor ?? widget.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 2: Summary ─────────────────────────────────────────────────────

  Widget _buildSummarySection(AnalysisReportModel r) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score badge + title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Score ${r.overallScore}/100',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accentBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            r.summaryTitle,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.textPrimary),
          ),
          const SizedBox(height: 14),
          ...r.summaryParagraphs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  p,
                  style: TextStyle(
                      fontSize: 14, color: widget.textSecondary, height: 1.65),
                ),
              )),
        ],
      ),
    );
  }

  // ── Section 3: Roles ───────────────────────────────────────────────────────

  Widget _buildRolesSection(AnalysisReportModel r) {
    return Column(
      children: r.recommendedRoles.map((role) => _buildRoleCard(role)).toList(),
    );
  }

  Widget _buildRoleCard(RecommendedRoleModel role) {
    final Color barColor;
    if (role.matchScore >= 75) {
      barColor = _accentGreen;
    } else if (role.matchScore >= 55) {
      barColor = _accentAmber;
    } else {
      barColor = _accentRed;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${role.matchScore}%',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: barColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.reason,
                    style: TextStyle(
                        fontSize: 13, color: widget.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: role.matchScore / 100,
                      minHeight: 4,
                      backgroundColor: widget.cardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String number, String title) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration:
              BoxDecoration(color: widget.textPrimary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(number,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: widget.cardBg)),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: widget.textPrimary)),
      ],
    );
  }

  Widget _card({
    required Widget child,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor ?? widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? widget.cardBorder),
      ),
      child: child,
    );
  }
}

class _FollowUpSelection {
  final String jobTitle;
  final DateTime date;
  final int days;

  const _FollowUpSelection(this.jobTitle, this.date, this.days);
}
