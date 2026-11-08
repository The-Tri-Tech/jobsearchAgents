import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../data/datasources/resume_service.dart';
import '../../data/models/resume_model.dart';

class ResumeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Color bg;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  const ResumeScreen({
    super.key,
    required this.isDarkMode,
    required this.bg,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final ResumeService _service = ResumeService();

  List<ResumeModel> _resumes = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadResumes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _service.listResumes();
      setState(() {
        _resumes = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load resumes. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUpload() async {
    // Pick file — PDF, DOC, DOCX only
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true, // needed for web
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final Uint8List? bytes = picked.bytes;
    final String filename = picked.name;

    if (bytes == null) {
      _showError('Could not read file bytes.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final uploaded = await _service.uploadResume(bytes: bytes, filename: filename);
      _showSuccess('"${uploaded.filename}" uploaded successfully!');
      await _loadResumes();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _openFile(ResumeModel resume) async {
    try {
      final bytes = await _service.fetchFileBytes(resume.filename);
      final mimeType = resume.isPdf ? 'application/pdf' : 'application/octet-stream';
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
      // Revoke after a short delay so browser has time to open it
      Future.delayed(const Duration(seconds: 5), () => html.Url.revokeObjectUrl(url));
    } catch (e) {
      _showError('Could not open file: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> _deleteResume(ResumeModel resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Resume', style: TextStyle(color: widget.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${resume.filename}"? This cannot be undone.',
          style: TextStyle(color: widget.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: widget.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD92D20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteResume(resume.filename);
      _showSuccess('"${resume.filename}" deleted.');
      await _loadResumes();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    if (mounted) setState(() { _errorMessage = msg; _successMessage = null; });
  }

  void _showSuccess(String msg) {
    if (mounted) setState(() { _successMessage = msg; _errorMessage = null; });
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildUploadCard(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildBanner(isError: true, message: _errorMessage!),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            _buildBanner(isError: false, message: _successMessage!),
          ],
          const SizedBox(height: 28),
          _buildResumeList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resume Manager',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: widget.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload, manage, and view your resumes. Supported formats: PDF, DOC, DOCX (max 10 MB).',
          style: TextStyle(fontSize: 14, color: widget.textSecondary),
        ),
      ],
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUpload,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isUploading
                ? widget.textPrimary.withOpacity(0.4)
                : widget.cardBorder,
            width: 2,
            // dashed effect via BoxBorder is not built-in; use solid + dash
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isUploading)
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: widget.textPrimary,
                ),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.upload_file_rounded,
                    size: 28, color: widget.textPrimary),
              ),
            const SizedBox(height: 14),
            Text(
              _isUploading ? 'Uploading…' : 'Click to upload a resume',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, DOC or DOCX · Max 10 MB',
              style: TextStyle(fontSize: 13, color: widget.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner({required bool isError, required String message}) {
    final bgColor = isError
        ? const Color(0xFFFEF3F2)
        : const Color(0xFFF0FDF4);
    final borderColor = isError
        ? const Color(0xFFFEE4E2)
        : const Color(0xFFBBF7D0);
    final textColor = isError
        ? const Color(0xFFB42318)
        : const Color(0xFF15803D);
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: textColor)),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _errorMessage = null;
              _successMessage = null;
            }),
            child: Icon(Icons.close_rounded, size: 16, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Uploaded Resumes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            if (!_isLoading)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_resumes.length}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.textSecondary),
                ),
              ),
            const Spacer(),
            // Refresh button
            IconButton(
              onPressed: _isLoading ? null : _loadResumes,
              icon: Icon(Icons.refresh_rounded,
                  size: 20, color: widget.textSecondary),
              tooltip: 'Refresh list',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: widget.textPrimary),
            ),
          )
        else if (_resumes.isEmpty)
          _buildEmptyState()
        else
          Container(
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: widget.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.cardBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _resumes.length,
              separatorBuilder: (_, __) =>
                  Divider(color: widget.cardBorder, height: 1, thickness: 1),
              itemBuilder: (_, i) => _buildResumeItem(_resumes[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.description_outlined,
              size: 40, color: widget.textSecondary),
          const SizedBox(height: 12),
          Text(
            'No resumes uploaded yet',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: widget.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Click the upload card above to add your first resume.',
            style: TextStyle(fontSize: 13, color: widget.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeItem(ResumeModel resume) {
    final icon = resume.isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded;
    final iconColor = resume.isPdf ? const Color(0xFFD92D20) : const Color(0xFF1D4ED8);
    final typeLabel = resume.isPdf ? 'PDF' : (resume.filename.toLowerCase().endsWith('.docx') ? 'DOCX' : 'DOC');

    return InkWell(
      onTap: () => _openFile(resume),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // File type icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resume.filename,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _chip(typeLabel, iconColor.withOpacity(0.12), iconColor),
                      const SizedBox(width: 8),
                      Text(
                        resume.displaySize,
                        style: TextStyle(
                            fontSize: 12, color: widget.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Open in new tab hint
            Tooltip(
              message: 'Open in new tab',
              child: Icon(Icons.open_in_new_rounded,
                  size: 18, color: widget.textSecondary),
            ),
            const SizedBox(width: 8),

            // Delete button
            Tooltip(
              message: 'Delete',
              child: IconButton(
                onPressed: () => _deleteResume(resume),
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: widget.textSecondary),
                hoverColor: const Color(0xFFFEF3F2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
