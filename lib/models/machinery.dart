class Machinery {
  final int id;
  final String code;
  final String name;
  final String? plateNumber;
  final String? operatorName;
  final String status;
  final double hourlyCost;
  final String? notes;

  Machinery({
    required this.id,
    required this.code,
    required this.name,
    this.plateNumber,
    this.operatorName,
    required this.status,
    this.hourlyCost = 0.0,
    this.notes,
  });

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'available':
        return 'متاحة للعمل';
      case 'in_use':
        return 'في الموقع / قيد التشغيل';
      case 'maintenance':
        return 'تحت الصيانة';
      case 'out_of_service':
        return 'خارج الخدمة';
      default:
        return status;
    }
  }

  factory Machinery.fromJson(Map<String, dynamic> json) => Machinery(
    id: (json['id'] as num?)?.toInt() ?? 0,
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    plateNumber: json['plate_number']?.toString(),
    operatorName: json['operator_name']?.toString(),
    status: json['status']?.toString().toLowerCase() ?? 'available',
    hourlyCost: (json['hourly_cost'] as num?)?.toDouble() ?? 0.0,
    notes: json['notes']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    if (plateNumber != null) 'plate_number': plateNumber,
    if (operatorName != null) 'operator_name': operatorName,
    'status': status,
    'hourly_cost': hourlyCost,
    if (notes != null) 'notes': notes,
  };
}