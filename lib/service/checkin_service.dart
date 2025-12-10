import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/checkin_model.dart';

class CheckInService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'checkemp';

  /// Add a new check-in record
  Future<void> addCheckIn(CheckIn checkIn) async {
    try {
      await _firestore.collection(collectionName).add(checkIn.toMap());
    } catch (e) {
      throw Exception('Error adding check-in: $e');
    }
  }

  /// Get all check-ins
  Stream<List<CheckIn>> getCheckIns() {
    return _firestore
        .collection(collectionName)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CheckIn.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get check-ins by employee ID
  Stream<List<CheckIn>> getCheckInsByEmpId(String empId) {
    return _firestore
        .collection(collectionName)
        .where('empId', isEqualTo: empId)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CheckIn.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get today's check-ins for an employee
  Future<List<CheckIn>> getTodayCheckIns(String empId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('empId', isEqualTo: empId)
          .get();

      // Filter by date in memory
      final todayCheckIns = querySnapshot.docs
          .map((doc) => CheckIn.fromMap(doc.data(), doc.id))
          .where((checkIn) {
            return checkIn.checkInTime.isAfter(startOfDay) &&
                checkIn.checkInTime.isBefore(endOfDay);
          })
          .toList();

      // Sort by checkInTime (most recent first)
      todayCheckIns.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

      return todayCheckIns;
    } catch (e) {
      throw Exception('Error getting today\'s check-ins: $e');
    }
  }

  /// Check if employee is currently clocked in (today)
  Future<CheckIn?> getCurrentClockedInStatus(String empId) async {
    try {
      final todayCheckIns = await getTodayCheckIns(empId);

      // Sort by check-in time to get the most recent
      todayCheckIns.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

      // Return the latest check-in that is still clocked in
      for (var checkIn in todayCheckIns) {
        if (checkIn.isClockedIn) {
          return checkIn;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error checking clocked in status: $e');
    }
  }

  /// Clock out an employee (update existing check-in record)
  Future<void> clockOut(String checkInId) async {
    try {
      await _firestore.collection(collectionName).doc(checkInId).update({
        'checkOutTime': DateTime.now().toIso8601String(),
        'isClockedIn': false,
      });
    } catch (e) {
      throw Exception('Error clocking out: $e');
    }
  }

  /// Start meal break
  Future<void> startMealBreak(String checkInId, CheckIn currentCheckIn) async {
    try {
      final newMealBreak = MealBreak(startTime: DateTime.now());
      final updatedMealBreaks = List<MealBreak>.from(currentCheckIn.mealBreaks)
        ..add(newMealBreak);

      await _firestore.collection(collectionName).doc(checkInId).update({
        'mealBreaks': updatedMealBreaks.map((mb) => mb.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Error starting meal break: $e');
    }
  }

  /// End meal break
  Future<void> endMealBreak(String checkInId, CheckIn currentCheckIn) async {
    try {
      // Find the active meal break and end it
      final updatedMealBreaks = currentCheckIn.mealBreaks.map((mb) {
        if (mb.isActive) {
          return MealBreak(startTime: mb.startTime, endTime: DateTime.now());
        }
        return mb;
      }).toList();

      await _firestore.collection(collectionName).doc(checkInId).update({
        'mealBreaks': updatedMealBreaks.map((mb) => mb.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Error ending meal break: $e');
    }
  }

  /// Start other break with reason
  Future<void> startOtherBreak(
    String checkInId,
    CheckIn currentCheckIn,
    String reason,
  ) async {
    try {
      final newOtherBreak = OtherBreak(
        startTime: DateTime.now(),
        reason: reason,
      );
      final updatedOtherBreaks = List<OtherBreak>.from(
        currentCheckIn.otherBreaks,
      )..add(newOtherBreak);

      await _firestore.collection(collectionName).doc(checkInId).update({
        'otherBreaks': updatedOtherBreaks.map((ob) => ob.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Error starting other break: $e');
    }
  }

  /// End other break
  Future<void> endOtherBreak(String checkInId, CheckIn currentCheckIn) async {
    try {
      // Find the active other break and end it
      final updatedOtherBreaks = currentCheckIn.otherBreaks.map((ob) {
        if (ob.isActive) {
          return OtherBreak(
            startTime: ob.startTime,
            endTime: DateTime.now(),
            reason: ob.reason,
          );
        }
        return ob;
      }).toList();

      await _firestore.collection(collectionName).doc(checkInId).update({
        'otherBreaks': updatedOtherBreaks.map((ob) => ob.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Error ending other break: $e');
    }
  }

  /// Check if employee has already checked in today
  Future<bool> hasCheckedInToday(String empId) async {
    try {
      final todayCheckIns = await getTodayCheckIns(empId);
      return todayCheckIns.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking today\'s check-in: $e');
    }
  }

  /// Delete a check-in record
  Future<void> deleteCheckIn(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting check-in: $e');
    }
  }
}
