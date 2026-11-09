import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skillbridge_frontend/features/jobs/data/datasources/jobs_service.dart';
import 'package:skillbridge_frontend/features/jobs/data/models/job_model.dart';

class JobsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Color bg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onNavigateToJdMatcher;

  const JobsScreen({
    super.key,
    required this.isDarkMode,
    required this.bg,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    this.onNavigateToJdMatcher,
  });

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobsService _jobsService = JobsService();
  List<JobModel> _allJobs = [];
  bool _isLoading = true;
  String _selectedFilter = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterTabs = [
    "All",
    "Analyzed",
    "Applied",
  ];

  // Advanced Filters State
  int? _minMatchScore;
  String? _selectedLocationType; // "All", "Remote", "Hybrid", "On-site"
  String? _selectedSource; // "All", "Link Import", "Pasted JD", "Manual Entry"
  String _sortBy = "newest"; // "newest", "score_desc", "title_asc", "company_asc"

  int get _activeFilterCount {
    int count = 0;
    if (_minMatchScore != null) count++;
    if (_selectedLocationType != null && _selectedLocationType != "All") count++;
    if (_selectedSource != null && _selectedSource != "All") count++;
    if (_sortBy != "newest") count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _selectedFilter = "All";
      _minMatchScore = null;
      _selectedLocationType = null;
      _selectedSource = null;
      _sortBy = "newest";
      _searchController.clear();
      _searchQuery = "";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    final jobs = await _jobsService.fetchJobs();
    if (mounted) {
      setState(() {
        _allJobs = jobs;
        _isLoading = false;
      });
    }
  }

  List<JobModel> get _filteredJobs {
    var result = _allJobs.where((job) {
      final matchesFilter = _selectedFilter == "All" ||
          job.status.toLowerCase() == _selectedFilter.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          job.title.toLowerCase().contains(query) ||
          job.company.toLowerCase().contains(query) ||
          job.tags.toLowerCase().contains(query) ||
          (job.jobUrl ?? "").toLowerCase().contains(query);

      final matchesScore = _minMatchScore == null || job.matchScore >= _minMatchScore!;

      final matchesLocation = _selectedLocationType == null ||
          _selectedLocationType == "All" ||
          job.location.toLowerCase().contains(_selectedLocationType!.toLowerCase());

      final matchesSource = _selectedSource == null ||
          _selectedSource == "All" ||
          job.source.toLowerCase().contains(_selectedSource!.toLowerCase());

      return matchesFilter && matchesSearch && matchesScore && matchesLocation && matchesSource;
    }).toList();

    if (_sortBy == "score_desc") {
      result.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    } else if (_sortBy == "title_asc") {
      result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortBy == "company_asc") {
      result.sort((a, b) => a.company.toLowerCase().compareTo(b.company.toLowerCase()));
    } else {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  Widget _buildFilterBadge(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  void _detectJobDetailsFromInputs({
    required String url,
    required String jdText,
    required TextEditingController titleCtrl,
    required TextEditingController companyCtrl,
    required void Function(void Function()) setDialogState,
  }) {
    String detectedTitle = "";
    String detectedCompany = "";

    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        final host = uri.host.toLowerCase();
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

        if (host.contains("linkedin.com")) {
          for (final seg in segments) {
            if (seg.toLowerCase().contains("-at-")) {
              final parts = seg.split("-at-");
              final compPart = parts.last.split("-").first;
              if (compPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(compPart)) {
                detectedCompany = _toTitleCase(compPart.replaceAll("-", " "));
              }
            }
          }
        } else if (host.contains("greenhouse.io") && segments.isNotEmpty) {
          detectedCompany = _toTitleCase(segments[0].replaceAll("-", " "));
        } else if (host.contains("lever.co") && segments.isNotEmpty) {
          detectedCompany = _toTitleCase(segments[0].replaceAll("-", " "));
        } else if (host.contains("amazon")) {
          detectedCompany = "Amazon";
        } else if (host.contains("google")) {
          detectedCompany = "Google";
        } else if (host.contains("microsoft")) {
          detectedCompany = "Microsoft";
        } else if (host.contains("apple")) {
          detectedCompany = "Apple";
        } else if (host.contains("meta")) {
          detectedCompany = "Meta";
        } else if (host.contains("netflix")) {
          detectedCompany = "Netflix";
        } else {
          final parts = host.split(".").where((p) => !["www", "careers", "jobs", "job", "career", "com", "io", "co", "org", "net"].contains(p)).toList();
          if (parts.isNotEmpty && parts[0].toLowerCase() != "linkedin") {
            detectedCompany = _toTitleCase(parts[0]);
          }
        }

        for (final seg in segments.reversed) {
          var clean = seg.replaceAll(RegExp(r'-\d+$'), '').replaceAll(RegExp(r'^\d+-'), '');
          if (clean.toLowerCase().contains("-at-")) {
            clean = clean.split("-at-").first;
          }
          final ignored = ["jobs", "view", "job", "careers", "details", "results", "http", "https", "www", "company"];
          if (clean.length > 3 && !RegExp(r'^\d+$').hasMatch(clean) && !ignored.contains(clean.toLowerCase())) {
            final words = clean.replaceAll("-", " ").replaceAll("_", " ");
            if (RegExp(r'(developer|engineer|manager|lead|architect|analyst|designer|scientist|intern|specialist)', caseSensitive: false).hasMatch(words)) {
              detectedTitle = _toTitleCase(words);
              break;
            } else if (detectedTitle.isEmpty && words.toLowerCase() != "https" && words.toLowerCase() != "http") {
              detectedTitle = _toTitleCase(words);
            }
          }
        }
      } catch (_) {}
    }

    if (jdText.isNotEmpty) {
      final firstChunk = jdText.length > 500 ? jdText.substring(0, 500) : jdText;
      final mAtComp = RegExp(
        r"([A-Za-z0-9 /&()+.\#\-]{3,80})\s+(?:at|@)\s+([A-Za-z0-9 &.,'-]{2,40})",
        caseSensitive: false,
      ).firstMatch(firstChunk);
      if (mAtComp != null) {
        final candTitle = mAtComp.group(1)!.trim();
        final candComp = mAtComp.group(2)!.trim();
        if (detectedTitle.isEmpty && candTitle.toLowerCase() != "https" && candTitle.toLowerCase() != "http") {
          detectedTitle = candTitle;
        }
        if (detectedCompany.isEmpty && candComp.toLowerCase() != "linkedin") {
          detectedCompany = candComp;
        }
      }

      final lines = jdText.split("\n").map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (detectedCompany.isEmpty) {
        for (final l in lines.take(12)) {
          final mComp = RegExp(r"^(?:Company|Organization|Employer)\s*:\s*([A-Za-z0-9 &.,'-]{2,40})", caseSensitive: false).firstMatch(l);
          if (mComp != null && mComp.group(1)!.trim().toLowerCase() != "linkedin") {
            detectedCompany = mComp.group(1)!.trim();
            break;
          }
          final mAbout = RegExp(r"^(?:About|Join|Welcome to)\s+([A-Z][A-Za-z0-9 &.,'-]{1,30})").firstMatch(l);
          if (mAbout != null) {
            final c = mAbout.group(1)!.trim();
            if (!["us", "our", "the role", "this job", "the team", "linkedin"].contains(c.toLowerCase())) {
              detectedCompany = c;
              break;
            }
          }
        }
      }

      if (detectedTitle.isEmpty) {
        for (final l in lines.take(12)) {
          final mTitle = RegExp(r'^(?:Job\s*Title|Position|Role|Title)\s*:\s*([A-Za-z0-9 /&()+.\#\-]{3,70})', caseSensitive: false).firstMatch(l);
          if (mTitle != null && mTitle.group(1)!.trim().toLowerCase() != "https") {
            detectedTitle = mTitle.group(1)!.trim();
            break;
          }
        }
        if (detectedTitle.isEmpty) {
          for (final l in lines.take(8)) {
            final cleaned = l.replaceAll(RegExp(r'^[#*\-•\d.]+\s*'), '').trim();
            if (cleaned.length >= 4 && cleaned.length <= 75 && RegExp(r'(developer|engineer|manager|lead|architect|analyst|designer|scientist|intern|specialist)', caseSensitive: false).hasMatch(cleaned)) {
              if (!cleaned.toLowerCase().startsWith("we are") && !cleaned.toLowerCase().startsWith("looking for") && !cleaned.toLowerCase().startsWith("requirements") && !cleaned.toLowerCase().startsWith("http")) {
                detectedTitle = cleaned;
                break;
              }
            }
          }
        }
        if (detectedTitle.isEmpty && lines.isNotEmpty) {
          final first = lines.first.replaceAll(RegExp(r'^[#*\-•\d.]+\s*'), '').trim();
          if (first.length >= 4 && first.length <= 60 && !first.toLowerCase().startsWith("http") && !first.toLowerCase().startsWith("www")) {
            detectedTitle = first;
          }
        }
      }
    }

    if (detectedTitle.toLowerCase() == "https" || detectedTitle.toLowerCase() == "http") {
      detectedTitle = "";
    }
    if (detectedCompany.toLowerCase() == "linkedin") {
      detectedCompany = "";
    }

    setDialogState(() {
      if (detectedTitle.isNotEmpty && titleCtrl.text.isEmpty) {
        titleCtrl.text = detectedTitle;
      }
      if (detectedCompany.isNotEmpty && companyCtrl.text.isEmpty) {
        companyCtrl.text = detectedCompany;
      }
    });
  }

  String _cleanJobTitle(JobModel job) {
    var title = job.title.trim();
    if (title.toLowerCase() == 'https' || title.toLowerCase() == 'http' || title.isEmpty) {
      if (job.jdText != null && job.jdText!.isNotEmpty) {
        final m = RegExp(r'^([A-Za-z0-9 /&()+.\#\-]{3,80})\s+(?:at|@)\s+', caseSensitive: false).firstMatch(job.jdText!);
        if (m != null) return m.group(1)!.trim();
      }
      return 'Target Role';
    }
    if (title.startsWith('js Developer')) return 'Next.js Developer Intern';
    if (title.startsWith('js / React Native')) return 'Junior Full-Stack & Mobile App Developer (React / Next.js / React Native)';
    return title;
  }

  String _cleanJobCompany(JobModel job) {
    var comp = job.company.trim();
    if (comp.toLowerCase() == 'linkedin' || comp.toLowerCase() == 'hiring company' || comp.isEmpty) {
      if (job.jdText != null && job.jdText!.isNotEmpty) {
        final m = RegExp(r"\b(?:at|@)\s+([A-Za-z0-9 &.,'-]{2,35})", caseSensitive: false).firstMatch(job.jdText!);
        if (m != null && m.group(1)!.trim().toLowerCase() != 'linkedin') {
          return m.group(1)!.trim();
        }
      }
    }
    return comp.isEmpty ? 'Hiring Company' : comp;
  }

  String _extractRoleDescriptionPreview(String? raw, String title, String company) {
    if (raw == null || raw.trim().isEmpty) return '';
    final trimmed = raw.trim();

    final paragraphs = trimmed.split(RegExp(r'\n\s*\n|\r\n\s*\r\n'));

    for (final para in paragraphs) {
      final cleanPara = para.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
      if (cleanPara.isEmpty) continue;

      final lower = cleanPara.toLowerCase();
      final isHeaderOnly = (title.isNotEmpty && lower == title.toLowerCase()) ||
          (company.isNotEmpty && lower == company.toLowerCase()) ||
          lower.startsWith('${title.toLowerCase()} at ${company.toLowerCase()}') ||
          (cleanPara.length < 50 && (lower.startsWith('job title:') || lower.startsWith('position:') || lower.startsWith('location:')));

      if (!isHeaderOnly && cleanPara.length >= 20) {
        final stripped = cleanPara.replaceAll(
          RegExp(r'^(?:About\s+(?:the\s+)?(?:role|job|company)|job\s+summary|overview|description|role\s+summary|mission)\s*[:—\-]?\s*', caseSensitive: false),
          '',
        ).trim();
        if (stripped.length >= 15) {
          return stripped;
        }
      }
    }

    final lines = trimmed.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length > 1) {
      return lines.sublist(1).join(' ').trim();
    }
    return trimmed;
  }

  Future<void> _showAddJobDialog() async {
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    final urlController = TextEditingController();
    final jdTextController = TextEditingController();
    String selectedStatus = "Analyzed";

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Add Job or Link",
            style: TextStyle(
              color: widget.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Job Posting URL / Link",
                      style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlController,
                    style: TextStyle(color: widget.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "https://linkedin.com/jobs/view/... or company career link",
                      hintStyle: TextStyle(color: widget.textSecondary, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      _detectJobDetailsFromInputs(
                        url: val,
                        jdText: jdTextController.text,
                        titleCtrl: titleController,
                        companyCtrl: companyController,
                        setDialogState: setDialogState,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text("Job Role / Title *",
                      style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: widget.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "e.g. Senior Full-Stack Engineer, Python Developer",
                      hintStyle: TextStyle(color: widget.textSecondary, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Company Name",
                                style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: companyController,
                              style: TextStyle(color: widget.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: "e.g. Stripe, Google, Startup",
                                hintStyle: TextStyle(color: widget.textSecondary, fontSize: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status",
                                style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedStatus,
                              dropdownColor: widget.cardBg,
                              style: TextStyle(color: widget.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: const [
                                DropdownMenuItem(value: "Analyzed", child: Text("Analyzed")),
                                DropdownMenuItem(value: "Applied", child: Text("Applied")),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedStatus = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text("Job Description (Optional snippet)",
                      style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: jdTextController,
                    maxLines: 4,
                    style: TextStyle(color: widget.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Paste job details, responsibilities, or requirements...",
                      hintStyle: TextStyle(color: widget.textSecondary, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (val) {
                      _detectJobDetailsFromInputs(
                        url: urlController.text,
                        jdText: val,
                        titleCtrl: titleController,
                        companyCtrl: companyController,
                        setDialogState: setDialogState,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel", style: TextStyle(color: widget.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(ctx);
                final newJob = await _jobsService.createJob(
                  title: title,
                  company: companyController.text.trim().isEmpty ? "Hiring Company" : companyController.text.trim(),
                  jobUrl: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                  jdText: jdTextController.text.trim().isEmpty ? null : jdTextController.text.trim(),
                  status: selectedStatus,
                  source: urlController.text.trim().isNotEmpty ? "Link Import" : "Manual Entry",
                );
                setState(() {
                  _allJobs.insert(0, newJob);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("✨ Added ${newJob.title} to Jobs Tracker!"),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.textPrimary,
                foregroundColor: widget.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Save Job", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showJdDetailsModal(JobModel job) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: TextStyle(color: widget.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("${job.company} • ${job.location}", style: TextStyle(color: widget.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: widget.textSecondary),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (job.jobUrl != null && job.jobUrl!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 16, color: widget.textPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            job.jobUrl!,
                            style: TextStyle(color: const Color(0xFF0284C7), fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: "Copy Link",
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: job.jobUrl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Link copied to clipboard!"), duration: Duration(seconds: 2)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text("Job Description", style: TextStyle(color: widget.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  job.jdText != null && job.jdText!.isNotEmpty
                      ? job.jdText!
                      : "No full text stored for this job. You can update it or open the original source link.",
                  style: TextStyle(color: widget.textSecondary, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close", style: TextStyle(color: widget.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showFiltersPageModal() {
    int? tempMinScore = _minMatchScore;
    String? tempLocation = _selectedLocationType ?? "All";
    String? tempSource = _selectedSource ?? "All";
    String tempSort = _sortBy;
    String tempStatus = _selectedFilter;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          int calculateMatchingCount() {
            return _allJobs.where((j) {
              final sMatch = tempStatus == "All" || j.status.toLowerCase() == tempStatus.toLowerCase();
              final scoreMatch = tempMinScore == null || j.matchScore >= tempMinScore!;
              final locMatch = tempLocation == "All" || j.location.toLowerCase().contains(tempLocation!.toLowerCase());
              final srcMatch = tempSource == "All" || j.source.toLowerCase().contains(tempSource!.toLowerCase());
              return sMatch && scoreMatch && locMatch && srcMatch;
            }).length;
          }

          final matchingCount = calculateMatchingCount();

          return AlertDialog(
            backgroundColor: widget.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tune_rounded, size: 20, color: widget.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Filters",
                          style: TextStyle(
                            color: widget.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Refine your tracked jobs",
                          style: TextStyle(color: widget.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: widget.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 540),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Section
                    Text("Job Status", style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ["All", "Analyzed", "Applied"].map((st) {
                        final sel = tempStatus == st;
                        return ChoiceChip(
                          label: Text(st),
                          selected: sel,
                          selectedColor: widget.textPrimary,
                          backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                          labelStyle: TextStyle(
                            color: sel ? widget.cardBg : widget.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setModalState(() => tempStatus = st),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Match Score Filter
                    Text("Minimum Match Score", style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {"label": "All Scores", "val": null},
                        {"label": "≥ 80% (High Match)", "val": 80},
                        {"label": "≥ 70% (Good Match)", "val": 70},
                        {"label": "≥ 50% (Any Fit)", "val": 50},
                      ].map((item) {
                        final sel = tempMinScore == item["val"];
                        return ChoiceChip(
                          label: Text(item["label"] as String),
                          selected: sel,
                          selectedColor: const Color(0xFF10B981),
                          backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : widget.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setModalState(() => tempMinScore = item["val"] as int?),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Location / Workplace Filter
                    Text("Location / Workplace", style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ["All", "Remote", "Hybrid", "On-site"].map((loc) {
                        final sel = tempLocation == loc;
                        return ChoiceChip(
                          label: Text(loc),
                          selected: sel,
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : widget.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setModalState(() => tempLocation = loc),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Import Source Filter
                    Text("Import Source", style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ["All", "Link Import", "Pasted JD", "Manual Entry"].map((src) {
                        final sel = tempSource == src;
                        return ChoiceChip(
                          label: Text(src),
                          selected: sel,
                          selectedColor: const Color(0xFF8B5CF6),
                          backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : widget.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setModalState(() => tempSource = src),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Sort By
                    Text("Sort By", style: TextStyle(color: widget.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: tempSort,
                      dropdownColor: widget.cardBg,
                      style: TextStyle(color: widget.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: "newest", child: Text("Newest Added First")),
                        DropdownMenuItem(value: "score_desc", child: Text("Highest Match Score First")),
                        DropdownMenuItem(value: "title_asc", child: Text("Role Title (A → Z)")),
                        DropdownMenuItem(value: "company_asc", child: Text("Company Name (A → Z)")),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => tempSort = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setModalState(() {
                    tempMinScore = null;
                    tempLocation = "All";
                    tempSource = "All";
                    tempSort = "newest";
                    tempStatus = "All";
                  });
                },
                child: const Text("Reset All", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _minMatchScore = tempMinScore;
                    _selectedLocationType = tempLocation;
                    _selectedSource = tempSource;
                    _sortBy = tempSort;
                    _selectedFilter = tempStatus;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.textPrimary,
                  foregroundColor: widget.cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                ),
                child: Text("Apply ($matchingCount Jobs)", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: widget.textPrimary, strokeWidth: 2),
      );
    }

    final totalJobs = _allJobs.length;
    final analyzedJobs = _allJobs.where((j) => j.status == "Analyzed").length;
    final appliedJobs = _allJobs.where((j) => j.status == "Applied").length;
    final avgScore = _allJobs.isNotEmpty
        ? (_allJobs.map((j) => j.matchScore).reduce((a, b) => a + b) / _allJobs.length).round()
        : 0;

    final jobs = _filteredJobs;

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
                    "Jobs Explorer & Tracker",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: widget.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Every job link and job description brought to the website is tracked here.",
                    style: TextStyle(fontSize: 14, color: widget.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _loadJobs,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text("Refresh"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.textPrimary,
                      side: BorderSide(color: widget.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddJobDialog,
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: const Text("Add Job or Link"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.textPrimary,
                      foregroundColor: widget.cardBg,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overview Metrics Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.cardBorder),
            ),
            child: Row(
              children: [
                _buildStatColumn("Total Jobs Brought", "$totalJobs", Icons.work_outline_rounded),
                _buildStatDivider(),
                _buildStatColumn("Analyzed", "$analyzedJobs", Icons.auto_awesome_rounded),
                _buildStatDivider(),
                _buildStatColumn("Applied", "$appliedJobs", Icons.send_rounded),
                _buildStatDivider(),
                _buildStatColumn("Avg Match Score", totalJobs > 0 ? "$avgScore%" : "--", Icons.speed_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search & Filter Controls
          Row(
            children: [
              // Search Input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: widget.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: widget.textSecondary),
                    hintText: "Search by role, company, or link...",
                    hintStyle: TextStyle(color: widget.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: widget.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: widget.cardBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),

              // Filter Tabs
              Row(
                children: _filterTabs.map((tab) {
                  final isSelected = _selectedFilter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = tab),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.textPrimary
                              : (widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? widget.cardBg : widget.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(width: 8),

              // Filters Page Button
              InkWell(
                onTap: _showFiltersPageModal,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeFilterCount > 0
                        ? const Color(0xFF2563EB)
                        : (widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _activeFilterCount > 0
                          ? const Color(0xFF2563EB)
                          : widget.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: _activeFilterCount > 0 ? Colors.white : widget.textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _activeFilterCount > 0 ? "Filters ($_activeFilterCount)" : "Filters",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _activeFilterCount > 0 ? Colors.white : widget.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Active Filter Chips Strip
          if (_activeFilterCount > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Active Filters:",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.textSecondary),
                ),
                if (_minMatchScore != null)
                  _buildFilterBadge("Score ≥ $_minMatchScore%", () => setState(() => _minMatchScore = null)),
                if (_selectedLocationType != null && _selectedLocationType != "All")
                  _buildFilterBadge("Location: $_selectedLocationType", () => setState(() => _selectedLocationType = null)),
                if (_selectedSource != null && _selectedSource != "All")
                  _buildFilterBadge("Source: $_selectedSource", () => setState(() => _selectedSource = null)),
                if (_sortBy != "newest")
                  _buildFilterBadge(
                    _sortBy == "score_desc" ? "Sort: Score" : (_sortBy == "title_asc" ? "Sort: Title" : "Sort: Company"),
                    () => setState(() => _sortBy = "newest"),
                  ),
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text("Clear all", style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Jobs List View
          if (jobs.isEmpty)
            _buildEmptyState()
          else
            ...jobs.map((job) => _buildJobCard(job)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: widget.textPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textPrimary)),
              Text(label, style: TextStyle(fontSize: 11, color: widget.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: widget.cardBorder,
    );
  }

  Widget _buildJobCard(JobModel job) {
    Color matchColor;
    if (job.matchScore >= 80) {
      matchColor = const Color(0xFF12B76A);
    } else if (job.matchScore >= 65) {
      matchColor = const Color(0xFF0284C7);
    } else {
      matchColor = const Color(0xFFF59E0B);
    }

    final cleanTitle = _cleanJobTitle(job);
    final cleanCompany = _cleanJobCompany(job);
    final rolePreview = _extractRoleDescriptionPreview(job.jdText, cleanTitle, cleanCompany);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                cleanCompany.isNotEmpty ? cleanCompany[0].toUpperCase() : "J",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              cleanTitle,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: matchColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${job.matchScore}% Match",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: matchColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Pill Dropdown
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ["Analyzed", "Applied", "Offer", "Rejected"].contains(job.status)
                            ? job.status
                            : "Analyzed",
                        dropdownColor: widget.cardBg,
                        style: TextStyle(color: widget.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        items: ["Analyzed", "Applied", "Offer", "Rejected"]
                            .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                            .toList(),
                        onChanged: (newSt) {
                          if (newSt != null) {
                            setState(() => job.status = newSt);
                            _jobsService.updateJobStatus(job.id, newSt);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Company & Details
                Row(
                  children: [
                    Text(cleanCompany, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.textPrimary)),
                    Text(" • ${job.location}", style: TextStyle(fontSize: 12, color: widget.textSecondary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFEAECF0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        job.source,
                        style: TextStyle(fontSize: 10, color: widget.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),

                if (rolePreview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    rolePreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: widget.textSecondary, height: 1.45),
                  ),
                ],

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    if (job.jobUrl != null && job.jobUrl!.isNotEmpty) ...[
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: job.jobUrl!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Job link copied to clipboard!"), duration: Duration(seconds: 2)),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: widget.cardBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new_rounded, size: 13, color: widget.textPrimary),
                              const SizedBox(width: 5),
                              Text("Copy Job Link", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    InkWell(
                      onTap: () => _showJdDetailsModal(job),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: widget.cardBorder),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notes_rounded, size: 13, color: widget.textSecondary),
                            const SizedBox(width: 5),
                            Text("View Details", style: TextStyle(fontSize: 11, color: widget.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    if (widget.onNavigateToJdMatcher != null) ...[
                      InkWell(
                        onTap: widget.onNavigateToJdMatcher,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: widget.cardBorder),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.compare_arrows_rounded, size: 13, color: widget.textSecondary),
                              const SizedBox(width: 5),
                              Text("Match Against Resume", style: TextStyle(fontSize: 11, color: widget.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(40),
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.work_outline_rounded, size: 26, color: widget.textPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              "No Jobs Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              "Whenever you analyze a JD, import a job link, or paste a description, it will be automatically tracked right here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: widget.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddJobDialog,
              icon: const Icon(Icons.add_link_rounded, size: 16),
              label: const Text("Add First Job or Link"),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.textPrimary,
                foregroundColor: widget.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

