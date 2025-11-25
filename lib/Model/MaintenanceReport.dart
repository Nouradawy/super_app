class MaintenanceReports{
  final int? id;
  final String userId;
  final String reportCode;
  final String title;
  final String description;
  final String category;
  final String states;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  MaintenanceReports({
    this.id,
    required this.userId,
    required this.reportCode,
    required this.title,
    required this.description,
    required this.category,
    required this.states,
    this.createdAt,
    this.updatedAt,
  });

  factory MaintenanceReports.fromJson(Map<String,dynamic> json){
    return MaintenanceReports(
        id:json["id"],
        userId: json["user_id"],
        reportCode: json['report_code'],
        title: json["title"],
        description: json["description"],
        category: json["category"],
        states: json["status"],
        createdAt:  DateTime.tryParse(json["created_at"]),
        updatedAt:  DateTime.tryParse(json["updated_at"])
    );
  }

}

class MaintenanceReportsAttachments{
  final int? id;
  final int reportId;
  final List sourceUrl;
  final DateTime? createdAt;

  MaintenanceReportsAttachments({
    this.id,
    required this.reportId,
    required this.sourceUrl,
    required this.createdAt
});

  factory MaintenanceReportsAttachments.fromJson(Map<String,dynamic> json){
    return MaintenanceReportsAttachments(
        id:json['id'],
        reportId: json['report_id'],
        sourceUrl: json['source_url'],
        createdAt: DateTime.tryParse(json['created_at']),
    );
  }
}

enum MaintenanceReportType{
  maintenance,
  security,
  careService,
}