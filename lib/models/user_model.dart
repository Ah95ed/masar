/// نموذج بيانات المستخدم والملف الشخصي
class UserModel {
  final int id;
  final String username;
  final String? email;
  final String? fullName;
  final String role; // 'manager', 'admin', 'engineer'
  final String? phone;
  final bool isActive;
  final String? status;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    required this.role,
    this.phone,
    this.isActive = true,
    this.status,
  });

  bool get isManager => role.toLowerCase() == 'manager' || role.toLowerCase() == 'admin';
  bool get isEngineer => role.toLowerCase() == 'engineer';

  String get displayName => (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : username;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString() ?? json['name']?.toString(),
      role: json['role']?.toString().toLowerCase() ?? 'engineer',
      phone: json['phone']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'is_active': isActive,
      'status': status,
    };
  }
}
