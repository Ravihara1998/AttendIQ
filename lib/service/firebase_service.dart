import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/employee_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'empdetails';

  /// -----------------------------
  /// ADD NEW EMPLOYEE
  /// -----------------------------
  Future<void> addEmployee(Employee employee) async {
    try {
      await _firestore.collection(collectionName).add(employee.toMap());
    } catch (e) {
      throw Exception('Error adding employee: $e');
    }
  }

  /// -----------------------------
  /// CHECK IF EMPLOYEE ID EXISTS
  /// -----------------------------
  Future<bool> isEmployeeIdExists(String empId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('empId', isEqualTo: empId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking employee ID: $e');
    }
  }

  /// -----------------------------
  /// GET EMPLOYEES (STREAM)
  /// -----------------------------
  Stream<List<Employee>> getEmployees() {
    return _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Employee.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// -----------------------------
  /// GET ALL EMPLOYEES (FUTURE)
  /// -----------------------------
  Future<List<Employee>> getAllEmployees() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Employee.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch employees: $e');
    }
  }

  /// -----------------------------
  /// GET SINGLE EMPLOYEE BY DOC ID
  /// -----------------------------
  Future<Employee?> getEmployeeById(String id) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(id).get();
      if (doc.exists) {
        return Employee.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting employee: $e');
    }
  }

  /// -----------------------------
  /// UPDATE EMPLOYEE
  /// -----------------------------
  Future<void> updateEmployee(Employee employee) async {
    try {
      if (employee.id == null || employee.id!.isEmpty) {
        throw Exception('Employee ID is required for update');
      }

      await _firestore
          .collection(collectionName)
          .doc(employee.id)
          .update(employee.toMap());
    } catch (e) {
      throw Exception('Error updating employee: $e');
    }
  }

  /// -----------------------------
  /// DELETE EMPLOYEE
  /// -----------------------------
  Future<void> deleteEmployee(String id) async {
    try {
      await _firestore.collection(collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting employee: $e');
    }
  }

  /// -----------------------------
  /// GET EMPLOYEE BY empId FIELD
  /// -----------------------------
  Future<Employee?> getEmployeeByEmpId(String empId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('empId', isEqualTo: empId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return Employee.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting employee by empId: $e');
    }
  }

  // ---------------------------------------------------------
  //        🔥 HR RECORDS SECTION (DISCIPLINE / SALARY / EXIT)
  // ---------------------------------------------------------

  /// Save Disciplinary Action (Array Union)
  Future<void> addDisciplinaryAction(
    String employeeId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(employeeId).update({
        "disciplinaryActions": FieldValue.arrayUnion([data]),
      });
    } catch (e) {
      throw Exception('Error adding disciplinary action: $e');
    }
  }

  /// Save Salary Increment (Array Union)
  Future<void> addSalaryIncrement(
    String employeeId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(employeeId).update({
        "salaryIncrements": FieldValue.arrayUnion([data]),
      });
    } catch (e) {
      throw Exception('Error adding salary increment: $e');
    }
  }

  /// Save Exit Interview File (Cloudinary link)
  Future<void> addExitInterview(
    String employeeId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionName).doc(employeeId).update({
        "exitInterviews": FieldValue.arrayUnion([data]),
      });
    } catch (e) {
      throw Exception('Error adding exit interview: $e');
    }
  }
}
