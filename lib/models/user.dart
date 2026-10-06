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

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: (json['id'] as num?)?.toInt() ?? 0,
    fullName: json['full_name']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    phone: json['phone']?.toString(),
    specialization: json['specialization']?.toString(),
    isActive: (json['is_active'] as num?)?.toInt() ?? 0,
    approvalStatus: json['approval_status']?.toString() ?? 'approved',
  );

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