class Employee {
  final String? id;
  final String name;
  final String empId;
  final String phone;
  final String address;
  final String department;
  final String userImageUrl;
  final String company;
  final String jobPosition;
  final String checkInTime;
  final String checkOutTime;
  final String emergencyContact;
  final String nickName;
  final String idNumber;
  final String joinDate;
  final DateTime createdAt;
  final List<Map<String, String>>? personalDocuments;
  final List<Map<String, String>>? disciplinaryActions;
  final List<Map<String, String>>? salaryIncrements;
  final List<Map<String, String>>? exitInterviews; // <-- ADD THIS LINE
  final String healthIssues;
  final String comments;
  final String previousWorkplace;
  final bool everWorkedInGroup;
  final List<Map<String, String>>? previousGroupEmployment;

  Employee({
    this.id,
    required this.name,
    required this.empId,
    required this.phone,
    required this.address,
    required this.department,
    required this.userImageUrl,
    required this.emergencyContact,
    required this.nickName,
    required this.idNumber,
    required this.joinDate,
    this.company = '',
    this.jobPosition = '',
    this.checkInTime = '09:00',
    this.checkOutTime = '17:00',
    this.personalDocuments,
    this.disciplinaryActions,
    this.salaryIncrements,
    this.exitInterviews,
    this.healthIssues = '',
    this.comments = '',
    this.previousWorkplace = '',
    this.everWorkedInGroup = false,
    this.previousGroupEmployment, // <-- ADD THIS LINE
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert object to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'empId': empId,
      'phone': phone,
      'address': address,
      'department': department,
      'userImageUrl': userImageUrl,
      'company': company,
      'jobPosition': jobPosition,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'emergencyContact': emergencyContact,
      'nickName': nickName,
      'idNumber': idNumber,
      'joinDate': joinDate,
      'createdAt': createdAt.toIso8601String(),
      'personalDocuments': personalDocuments ?? [],
      'disciplinaryActions': disciplinaryActions ?? [],
      'salaryIncrements': salaryIncrements ?? [],
      'exitInterviews': exitInterviews ?? [], // <-- ADD THIS LINE
      'healthIssues': healthIssues,
      'comments': comments,
      'previousWorkplace': previousWorkplace,
      'everWorkedInGroup': everWorkedInGroup,
      'previousGroupEmployment': previousGroupEmployment ?? [],
    };
  }

  // Create from Firestore document
  factory Employee.fromMap(Map<String, dynamic> map, String id) {
    return Employee(
      id: id,
      name: map['name'] ?? '',
      empId: map['empId'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      department: map['department'] ?? '',
      userImageUrl: map['userImageUrl'] ?? '',
      company: map['company'] ?? '',
      jobPosition: map['jobPosition'] ?? '',
      checkInTime: map['checkInTime'] ?? '09:00',
      checkOutTime: map['checkOutTime'] ?? '17:00',
      emergencyContact: map['emergencyContact'] ?? '',
      nickName: map['nickName'] ?? '',
      idNumber: map['idNumber'] ?? '',
      joinDate: map['joinDate'] ?? '',
      healthIssues: map['healthIssues'] ?? '',
      comments: map['comments'] ?? '',
      previousWorkplace: map['previousWorkplace'] ?? '',
      everWorkedInGroup: map['everWorkedInGroup'] ?? false,
      previousGroupEmployment: map['previousGroupEmployment'] != null
          ? List<Map<String, String>>.from(
              (map['previousGroupEmployment'] as List).map(
                (item) => Map<String, String>.from(item),
              ),
            )
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      personalDocuments: map['personalDocuments'] != null
          ? List<Map<String, String>>.from(
              (map['personalDocuments'] as List).map(
                (item) => Map<String, String>.from(item as Map),
              ),
            )
          : null,
      disciplinaryActions: map['disciplinaryActions'] != null
          ? List<Map<String, String>>.from(
              (map['disciplinaryActions'] as List).map(
                (item) => Map<String, String>.from(item as Map),
              ),
            )
          : null,
      salaryIncrements: map['salaryIncrements'] != null
          ? List<Map<String, String>>.from(
              (map['salaryIncrements'] as List).map(
                (item) => Map<String, String>.from(item as Map),
              ),
            )
          : null,
      // <-- ADD THIS BLOCK
      exitInterviews: map['exitInterviews'] != null
          ? List<Map<String, String>>.from(
              (map['exitInterviews'] as List).map(
                (item) => Map<String, String>.from(item as Map),
              ),
            )
          : null,
    );
  }

  Employee copyWith({
    String? id,
    String? name,
    String? empId,
    String? address,
    String? phone,
    String? department,
    String? userImageUrl,
    String? company,
    String? jobPosition,
    String? checkInTime,
    String? checkOutTime,
    String? emergencyContact,
    String? nickName,
    String? idNumber,
    String? joinDate,
    DateTime? createdAt,
    List<Map<String, String>>? personalDocuments,
    List<Map<String, String>>? disciplinaryActions,
    List<Map<String, String>>? salaryIncrements,
    List<Map<String, String>>? exitInterviews, // <-- ADD THIS LINE
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      empId: empId ?? this.empId,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      department: department ?? this.department,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      company: company ?? this.company,
      jobPosition: jobPosition ?? this.jobPosition,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      nickName: nickName ?? this.nickName,
      idNumber: idNumber ?? this.idNumber,
      joinDate: joinDate ?? this.joinDate,
      createdAt: createdAt ?? this.createdAt,
      personalDocuments: personalDocuments ?? this.personalDocuments,
      disciplinaryActions: disciplinaryActions ?? this.disciplinaryActions,
      salaryIncrements: salaryIncrements ?? this.salaryIncrements,
      exitInterviews:
          exitInterviews ?? this.exitInterviews, // <-- ADD THIS LINE
    );
  }
}
