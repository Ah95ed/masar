/// نموذج مهندس في قائمة المتصدرين اليومية
class TopEngineerModel {
  final int engineerId;
  final String fullName;
  final double score;
  final int activityCount;
  final int completedTasks;

  TopEngineerModel({
    required this.engineerId,
    required this.fullName,
    required this.score,
    required this.activityCount,
    required this.completedTasks,
  });

  factory TopEngineerModel.fromJson(Map<String, dynamic> json) {
    return TopEngineerModel(
      engineerId: int.tryParse(json['engineer_id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString() ?? 'مهندس بدون اسم',
      score: double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      activityCount: int.tryParse(json['activity_count']?.toString() ?? '0') ?? 0,
      completedTasks: int.tryParse(json['completed_tasks']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'engineer_id': engineerId,
      'full_name': fullName,
      'score': score,
      'activity_count': activityCount,
      'completed_tasks': completedTasks,
    };
  }
}

/// نموذج لوحة تحكم المدير العام (Maxlond Management)
class DashboardModel {
  final int sitesCount;
  final int engineersCount;
  final int machineryCount;
  final int pendingReportsCount;
  final double inventoryValue;
  final List<TopEngineerModel> todayTopEngineers;
  final Map<String, dynamic>? rawData;

  DashboardModel({
    this.sitesCount = 0,
    this.engineersCount = 0,
    this.machineryCount = 0,
    this.pendingReportsCount = 0,
    this.inventoryValue = 0.0,
    this.todayTopEngineers = const [],
    this.rawData,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is List) return val.length;
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    List<TopEngineerModel> engineers = [];
    if (json['today_top_engineers'] != null && json['today_top_engineers'] is List) {
      engineers = (json['today_top_engineers'] as List)
          .map((e) => TopEngineerModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return DashboardModel(
      sitesCount: parseInt(json['sites']),
      engineersCount: parseInt(json['engineers']),
      machineryCount: parseInt(json['machinery']),
      pendingReportsCount: parseInt(json['pending_reports']),
      inventoryValue: parseDouble(json['inventory_value']),
      todayTopEngineers: engineers,
      rawData: json,
    );
  }
}
