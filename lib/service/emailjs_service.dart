import 'dart:convert';
import 'package:http/http.dart' as http;
import '../pages/checkin_model.dart';
import 'package:intl/intl.dart';

class EmailJSService {
  static const String _serviceId = 'service_au2l5ar';
  static const String _templateId = 'template_5vjh9yg';
  static const String _publicKey = 'f67eFmRDNwJnFWc0S';

  static Future<bool> sendAttendanceReport({
    required String toEmail,
    required List<CheckIn> checkIns,
    required String dateRange,
    required String companyName,
    required Map<String, double> employeeTotalHours, // NEW: Add this parameter
  }) async {
    try {
      // Generate HTML table
      final tableHtml = _generateHtmlTable(checkIns, employeeTotalHours);

      // Prepare email parameters
      final emailParams = {
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'to_email': toEmail,
          'company_name': companyName,
          'date_range': dateRange,
          'record_count': checkIns.length.toString(),
          'table_data': tableHtml,
        },
      };

      // Send email via EmailJS API
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(emailParams),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully');
        return true;
      } else {
        print('Failed to send email: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  // NEW: Helper function to format decimal hours to "Xh Ym" format
  static String _formatHoursToHM(double hours) {
    final totalHours = hours.floor();
    final totalMinutes = ((hours - totalHours) * 60).round();
    return '${totalHours}h ${totalMinutes}m';
  }

  static String _generateHtmlTable(
    List<CheckIn> checkIns,
    Map<String, double> employeeTotalHours, // NEW: Add parameter
  ) {
    final buffer = StringBuffer();

    // Start table with styling
    buffer.write('''
<table style="width: 100%; border-collapse: collapse; font-family: Arial, sans-serif; font-size: 14px;">
  <thead>
    <tr style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Nickname</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Check-in</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Check-out</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Employee ID</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Department</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Date</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Duration</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Meal Breaks</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Other Breaks</th>
      <th style="padding: 12px; text-align: left; border: 1px solid #ddd;">Total Hours</th>
    </tr>
  </thead>
  <tbody>
    ''');

    // Add rows
    for (int i = 0; i < checkIns.length; i++) {
      final checkIn = checkIns[i];
      final isEven = i % 2 == 0;
      final bgColor = isEven ? '#f8f9fa' : '#ffffff';

      // Get total hours for this employee
      final totalHours = employeeTotalHours[checkIn.empId] ?? 0.0;
      final totalHoursFormatted = _formatHoursToHM(totalHours);

      buffer.write('''
    <tr style="background-color: $bgColor;">
      <td style="padding: 10px; border: 1px solid #ddd;">${checkIn.nickName}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${DateFormat('hh:mm a').format(checkIn.checkInTime)}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${checkIn.checkOutTime != null ? DateFormat('hh:mm a').format(checkIn.checkOutTime!) : 'Not checked out'}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${checkIn.empId}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">
        <span style="background-color: #e3f2fd; color: #1976d2; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 600;">
          ${checkIn.department}
        </span>
      </td>
      <td style="padding: 10px; border: 1px solid #ddd;">${DateFormat('MMM dd, yyyy').format(checkIn.checkInTime)}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${checkIn.getWorkDuration() ?? '-'}</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${checkIn.getTotalMealBreakMinutes()} min</td>
      <td style="padding: 10px; border: 1px solid #ddd;">${checkIn.getTotalOtherBreakMinutes()} min</td>
      <td style="padding: 10px; border: 1px solid #ddd; background-color: #e8f5e9; color: #2e7d32; font-weight: bold;">$totalHoursFormatted</td>
    </tr>
      ''');
    }

    // Close table
    buffer.write('''
  </tbody>
</table>
    ''');

    return buffer.toString();
  }

  // Email validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
