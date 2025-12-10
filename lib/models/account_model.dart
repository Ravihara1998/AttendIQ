class Account {
  final String? id;
  final String username;
  final String email;
  final String role; // 'Admin' or 'Super Admin'
  final String? company; // Only for Admin role
  final DateTime createdAt;

  Account({
    this.id,
    required this.username,
    required this.email,
    required this.role,
    this.company,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'company': company,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory Account.fromMap(Map<String, dynamic> map, String id) {
    return Account(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Admin',
      company: map['company'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  // Copy with method for updates
  Account copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? company,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
