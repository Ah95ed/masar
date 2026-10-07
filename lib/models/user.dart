class User {
  final int id;
  final String fullName;
  final String username;
  final String email;
  final String role;
  final String? phone;
  final String? specialization;
  final int isActive;
  final String approvalStatus;

  User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.role,
    this.phone,
    this.specialization,
    required this.isActive,
    required this.approvalStatus,
  });

  bool get isApproved => approvalStatus.toLowerCase() == 'approved';
  bool get active => isActive == 1;

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'مدير النظام';
      case 'engineer':
        return 'مهندس';
      case 'accountant':
        return 'محاسب';
      case 'warehouse':
        return 'أمين مخزن';
      case 'fleet_manager':
        return 'مسؤول أسطول';
      default:
        return role;
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    int parseActive(dynamic v) {
      if (v == null) return 0;
      if (v == true || v == 1 || v == '1') return 1;
      return 0;
    }

    return User(
      id: parseId(json['id']),
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone']?.toString(),
      specialization: json['specialization']?.toString(),
      isActive: parseActive(json['is_active']),
      approvalStatus: json['approval_status']?.toString() ?? 'approved',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'username': username,
    'email': email,
    'role': role,
    if (phone != null) 'phone': phone,
    if (specialization != null) 'specialization': specialization,
    'is_active': isActive,
    'approval_status': approvalStatus,
  };
}
