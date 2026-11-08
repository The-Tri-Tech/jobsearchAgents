class ResumeModel {
  final String filename;
  final int sizeBytes;
  final double uploadedAt; // epoch seconds (st_mtime)
  final String url;

  ResumeModel({
    required this.filename,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.url,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      filename: json['filename'] ?? '',
      sizeBytes: (json['size_bytes'] ?? 0) as int,
      uploadedAt: (json['uploaded_at'] ?? 0).toDouble(),
      url: json['url'] ?? '',
    );
  }

  String get displaySize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isPdf => filename.toLowerCase().endsWith('.pdf');
  bool get isDoc =>
      filename.toLowerCase().endsWith('.doc') ||
      filename.toLowerCase().endsWith('.docx');
}
