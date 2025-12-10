class MealBreak {
  final DateTime startTime;
  final DateTime? endTime;

  MealBreak({required this.startTime, this.endTime});

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory MealBreak.fromMap(Map<String, dynamic> map) {
    return MealBreak(
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }

  bool get isActive => endTime == null;

  String getDuration() {
    if (endTime == null) return 'In Progress';
    final duration = endTime!.difference(startTime);
    final minutes = duration.inMinutes;
    return '$minutes min';
  }
}

class OtherBreak {
  final DateTime startTime;
  final DateTime? endTime;
  final String reason;

  OtherBreak({required this.startTime, this.endTime, required this.reason});

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'reason': reason,
    };
  }

  factory OtherBreak.fromMap(Map<String, dynamic> map) {
    return OtherBreak(
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      reason: map['reason'] ?? '',
    );
  }

  bool get isActive => endTime == null;

  String getDuration() {
    if (endTime == null) return 'In Progress';
    final duration = endTime!.difference(startTime);
    final minutes = duration.inMinutes;
    return '$minutes min';
  }
}

class CheckIn {
  final String? id;
  final String empId;
  final String nickName;
  final String name;
  final String department;
  final String capturedImageUrl;
  final String originalImageUrl;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final bool isClockedIn;
  final List<MealBreak> mealBreaks;
  final List<OtherBreak> otherBreaks;

  CheckIn({
    this.id,
    required this.empId,
    required this.nickName,
    required this.name,
    required this.department,
    required this.capturedImageUrl,
    required this.originalImageUrl,
    DateTime? checkInTime,
    this.checkOutTime,
    this.isClockedIn = true,
    List<MealBreak>? mealBreaks,
    List<OtherBreak>? otherBreaks,
  }) : checkInTime = checkInTime ?? DateTime.now(),
       mealBreaks = mealBreaks ?? [],
       otherBreaks = otherBreaks ?? [];

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'empId': empId,
      'name': name,
      'nickName': nickName,
      'department': department,
      'capturedImageUrl': capturedImageUrl,
      'originalImageUrl': originalImageUrl,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'isClockedIn': isClockedIn,
      'mealBreaks': mealBreaks.map((mb) => mb.toMap()).toList(),
      'otherBreaks': otherBreaks.map((ob) => ob.toMap()).toList(),
      'date': checkInTime.toIso8601String().split('T')[0],
      'time':
          '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}',
    };
  }

  // Create from Firestore document
  factory CheckIn.fromMap(Map<String, dynamic> map, String id) {
    List<MealBreak> mealBreaks = [];
    if (map['mealBreaks'] != null) {
      mealBreaks = (map['mealBreaks'] as List)
          .map((mb) => MealBreak.fromMap(mb as Map<String, dynamic>))
          .toList();
    }

    List<OtherBreak> otherBreaks = [];
    if (map['otherBreaks'] != null) {
      otherBreaks = (map['otherBreaks'] as List)
          .map((ob) => OtherBreak.fromMap(ob as Map<String, dynamic>))
          .toList();
    }

    return CheckIn(
      id: id,
      empId: map['empId'] ?? '',
      nickName: map['nickName'] ?? '-',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      capturedImageUrl: map['capturedImageUrl'] ?? '',
      originalImageUrl: map['originalImageUrl'] ?? '',
      checkInTime: map['checkInTime'] != null
          ? DateTime.parse(map['checkInTime'])
          : DateTime.now(),
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'])
          : null,
      isClockedIn: map['isClockedIn'] ?? true,
      mealBreaks: mealBreaks,
      otherBreaks: otherBreaks,
    );
  }

  // Copy with method
  CheckIn copyWith({
    String? id,
    String? empId,
    String? name,
    String? nickName,
    String? department,
    String? capturedImageUrl,
    String? originalImageUrl,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isClockedIn,
    List<MealBreak>? mealBreaks,
    List<OtherBreak>? otherBreaks,
  }) {
    return CheckIn(
      id: id ?? this.id,
      empId: empId ?? this.empId,
      nickName: nickName ?? this.nickName,
      name: name ?? this.name,
      department: department ?? this.department,
      capturedImageUrl: capturedImageUrl ?? this.capturedImageUrl,
      originalImageUrl: originalImageUrl ?? this.originalImageUrl,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isClockedIn: isClockedIn ?? this.isClockedIn,
      mealBreaks: mealBreaks ?? this.mealBreaks,
      otherBreaks: otherBreaks ?? this.otherBreaks,
    );
  }

  // Helper to get active meal break
  MealBreak? getActiveMealBreak() {
    try {
      return mealBreaks.firstWhere((mb) => mb.isActive);
    } catch (e) {
      return null;
    }
  }

  // Helper to get active other break
  OtherBreak? getActiveOtherBreak() {
    try {
      return otherBreaks.firstWhere((ob) => ob.isActive);
    } catch (e) {
      return null;
    }
  }

  // Helper to get formatted duration
  String? getWorkDuration() {
    if (checkOutTime == null) return null;

    final duration = checkOutTime!.difference(checkInTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '${hours}h ${minutes}m';
  }

  // NEW: Get work duration in hours (decimal format)
  double? getWorkDurationInHours() {
    if (checkOutTime == null) return null;

    // Calculate total duration between check-in and check-out
    final duration = checkOutTime!.difference(checkInTime);
    final totalHours = duration.inMinutes / 60.0;

    // Subtract break times
    final mealBreakHours = getTotalMealBreakMinutes() / 60.0;
    final otherBreakHours = getTotalOtherBreakMinutes() / 60.0;

    // Return net working hours
    final workingHours = totalHours - mealBreakHours - otherBreakHours;

    // Ensure we don't return negative hours
    return workingHours > 0 ? workingHours : 0.0;
  }

  // Get total meal break time
  int getTotalMealBreakMinutes() {
    int total = 0;
    for (var mb in mealBreaks) {
      if (mb.endTime != null) {
        total += mb.endTime!.difference(mb.startTime).inMinutes;
      }
    }
    return total;
  }

  // Get total other break time
  int getTotalOtherBreakMinutes() {
    int total = 0;
    for (var ob in otherBreaks) {
      if (ob.endTime != null) {
        total += ob.endTime!.difference(ob.startTime).inMinutes;
      }
    }
    return total;
  }

  // Add this method to return total work time in minutes
  int getTotalWorkTime() {
    // Example implementation: returns work duration minus breaks
    if (checkOutTime == null) return 0;
    final duration = checkOutTime!.difference(checkInTime).inMinutes;
    final mealBreaks = getTotalMealBreakMinutes();
    final otherBreaks = getTotalOtherBreakMinutes();
    return duration - mealBreaks - otherBreaks;
  }
}
