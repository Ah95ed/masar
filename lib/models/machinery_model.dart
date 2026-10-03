/// نموذج الآلية أو المعدة الإنشائية
class MachineryModel {
  final int id;
  final String name;
  final String? code;
  final String? type; // حفارة، شاحنة، رافعة، بلدوزر...
  final String status; // operational, under_maintenance, idle, broken
  final int? siteId;
  final String? siteName;
  final String? plateNumber;
  final String? operatorName;

  MachineryModel({
    required this.id,
    required this.name,
    this.code,
    this.type,
    required this.status,
    this.siteId,
    this.siteName,
    this.plateNumber,
    this.operatorName,
  });

  factory MachineryModel.fromJson(Map<String, dynamic> json) {
    return MachineryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'آلية بدون اسم',
      code: json['code']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString().toLowerCase() ?? 'operational',
      siteId: int.tryParse(json['site_id']?.toString() ?? ''),
      siteName: json['site_name']?.toString() ?? json['site']?.toString(),
      plateNumber: json['plate_number']?.toString() ?? json['serial_number']?.toString(),
      operatorName: json['operator_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type,
      'status': status,
      'site_id': siteId,
      'site_name': siteName,
      'plate_number': plateNumber,
      'operator_name': operatorName,
    };
  }
}
