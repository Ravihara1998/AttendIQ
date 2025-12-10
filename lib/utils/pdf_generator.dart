import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../pages/checkin_model.dart';

class PdfGenerator {
  static Future<void> generateAndDownloadPdf({
    required BuildContext context,
    required List<CheckIn> checkIns,
    required String dateRange,
    required String company,
    required Map<String, double> employeeTotalHours,
  }) async {
    final pdf = pw.Document();

    // Define colors
    final primaryColor = PdfColor.fromHex('#6366f1');
    final headerColor = PdfColor.fromHex('#1e293b');
    final textColor = PdfColor.fromHex('#334155');
    final lightGray = PdfColor.fromHex('#f1f5f9');

    // Add page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context pdfContext) {
          return [
            // Header Section
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                children: [
                  // Company Name
                  pw.Text(
                    company,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: headerColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Title
                  pw.Text(
                    'Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // Date Range
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: lightGray,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      dateRange,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // Generated Date
                  pw.Text(
                    'Generated on: ${DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now())}',
                    style: pw.TextStyle(fontSize: 10, color: textColor),
                  ),
                  pw.SizedBox(height: 4),

                  // Total Records
                  pw.Text(
                    'Total Records: ${checkIns.length}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            pw.Container(
              height: 2,
              color: primaryColor,
              margin: const pw.EdgeInsets.only(bottom: 20),
            ),

            // Table
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#e2e8f0'),
                width: 1,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5), // Nickname
                1: const pw.FlexColumnWidth(1.2), // Check-in
                2: const pw.FlexColumnWidth(1.2), // Check-out
                3: const pw.FlexColumnWidth(1.0), // ID
                4: const pw.FlexColumnWidth(1.5), // Department
                5: const pw.FlexColumnWidth(1.2), // Date
                6: const pw.FlexColumnWidth(1.0), // Duration
                7: const pw.FlexColumnWidth(1.2), // Meal Breaks
                8: const pw.FlexColumnWidth(1.2), // Other Breaks
                9: const pw.FlexColumnWidth(1.2), // total Work Time
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: headerColor),
                  children: [
                    _buildHeaderCell('Nickname'),
                    _buildHeaderCell('Check-in'),
                    _buildHeaderCell('Check-out'),
                    _buildHeaderCell('ID'),
                    _buildHeaderCell('Department'),
                    _buildHeaderCell('Date'),
                    _buildHeaderCell('Duration'),
                    _buildHeaderCell('Meal Breaks'),
                    _buildHeaderCell('Other Breaks'),
                    _buildHeaderCell('Total Work Time'),
                  ],
                ),

                // Data Rows
                ...checkIns.asMap().entries.map((entry) {
                  final index = entry.key;
                  final checkIn = entry.value;
                  final isEven = index % 2 == 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? lightGray : PdfColors.white,
                    ),
                    children: [
                      _buildDataCell(checkIn.nickName),
                      _buildDataCell(
                        DateFormat('hh:mm a').format(checkIn.checkInTime),
                      ),
                      _buildDataCell(
                        checkIn.checkOutTime != null
                            ? DateFormat(
                                'hh:mm a',
                              ).format(checkIn.checkOutTime!)
                            : 'Not checked out',
                      ),
                      _buildDataCell(checkIn.empId),
                      _buildDataCell(checkIn.department),
                      _buildDataCell(
                        DateFormat('MMM dd, yyyy').format(checkIn.checkInTime),
                      ),
                      _buildDataCell(checkIn.getWorkDuration() ?? '-'),
                      _buildDataCell(
                        '${checkIn.getTotalMealBreakMinutes()} min',
                      ),
                      _buildDataCell(
                        '${checkIn.getTotalOtherBreakMinutes()} min',
                      ),
                      _buildDataCell(
                        '${employeeTotalHours[checkIn.empId]?.toStringAsFixed(2) ?? '0.0'} hrs',
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
        footer: (pw.Context pdfContext) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Page ${pdfContext.pageNumber} of ${pdfContext.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: textColor),
            ),
          );
        },
      ),
    );

    // Show print preview and download
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Attendance_Report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildDataCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#334155')),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
