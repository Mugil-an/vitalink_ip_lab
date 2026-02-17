class ReportModel {
  final String id;
  final DateTime testDate;
  final double inrValue;
  final String? notes;
  final bool isCritical;
  final String fileUrl;

  ReportModel({
    required this.id,
    required this.testDate,
    required this.inrValue,
    this.notes,
    required this.isCritical,
    required this.fileUrl,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['_id'] as String? ?? '',
      testDate: json['test_date'] is String
          ? DateTime.tryParse(json['test_date'] as String) ?? DateTime.now()
          : json['test_date'] is DateTime
              ? json['test_date'] as DateTime
              : DateTime.now(),
      inrValue: (json['inr_value'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      isCritical: json['is_critical'] as bool? ?? false,
      fileUrl: json['file_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'test_date': testDate.toIso8601String(),
      'inr_value': inrValue,
      'notes': notes,
      'is_critical': isCritical,
      'file_url': fileUrl,
    };
  }
}
