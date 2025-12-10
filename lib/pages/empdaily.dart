import 'package:flutter/material.dart';
import '../style/emp_daily_style.dart';
import '../service/checkin_service.dart';
import '../pages/checkin_model.dart';
import 'package:intl/intl.dart';

class EmpDailyPage extends StatefulWidget {
  const EmpDailyPage({super.key});

  @override
  State<EmpDailyPage> createState() => _EmpDailyPageState();
}

class _EmpDailyPageState extends State<EmpDailyPage> {
  List<CheckIn> _allCheckIns = [];
  bool _isLoading = true;
  String _selectedView = 'department'; // department, date, employee
  String? _selectedDepartment;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<void> _loadCheckIns() async {
    setState(() => _isLoading = true);
    try {
      final checkInService = CheckInService();
      checkInService.getCheckIns().listen((checkIns) {
        if (mounted) {
          setState(() {
            _allCheckIns = checkIns;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading check-ins: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handleBack() {
    setState(() {
      if (_selectedView == 'employee') {
        _selectedView = 'date';
        _selectedDate = null;
      } else if (_selectedView == 'date') {
        _selectedView = 'department';
        _selectedDepartment = null;
      }
    });
  }

  Map<String, List<CheckIn>> _groupByDepartment() {
    final Map<String, List<CheckIn>> grouped = {};
    for (var checkIn in _allCheckIns) {
      if (!grouped.containsKey(checkIn.department)) {
        grouped[checkIn.department] = [];
      }
      grouped[checkIn.department]!.add(checkIn);
    }
    return grouped;
  }

  Map<String, List<CheckIn>> _groupByDate(String department) {
    final Map<String, List<CheckIn>> grouped = {};
    final filtered = _allCheckIns.where((c) => c.department == department);
    for (var checkIn in filtered) {
      final dateKey = DateFormat('yyyy-MM-dd').format(checkIn.checkInTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(checkIn);
    }
    return grouped;
  }

  List<CheckIn> _getEmployeeCheckIns(String department, String date) {
    final dateKey = date;
    return _allCheckIns
        .where(
          (c) =>
              c.department == department &&
              DateFormat('yyyy-MM-dd').format(c.checkInTime) == dateKey,
        )
        .toList();
  }

  void _showEmployeeDetail(CheckIn checkIn) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: EmpDailyStyle.getCardDecoration(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
                  decoration: BoxDecoration(
                    gradient: EmpDailyStyle.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checkIn.name,
                              style: EmpDailyStyle.headingMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${checkIn.empId}',
                              style: EmpDailyStyle.bodyMedium.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department and Date Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              Icons.business,
                              'Department',
                              checkIn.department,
                            ),
                          ),
                          const SizedBox(width: EmpDailyStyle.spacingM),
                          Expanded(
                            child: _buildInfoCard(
                              Icons.calendar_today,
                              'Date',
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(checkIn.checkInTime),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EmpDailyStyle.spacingM),

                      // Check-in and Check-out Time Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              Icons.login,
                              'Check-in',
                              '${checkIn.checkInTime.hour.toString().padLeft(2, '0')}:${checkIn.checkInTime.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                          const SizedBox(width: EmpDailyStyle.spacingM),
                          Expanded(
                            child: _buildInfoCard(
                              Icons.logout,
                              'Check-out',
                              checkIn.checkOutTime != null
                                  ? '${checkIn.checkOutTime!.hour.toString().padLeft(2, '0')}:${checkIn.checkOutTime!.minute.toString().padLeft(2, '0')}'
                                  : 'Not checked out',
                            ),
                          ),
                        ],
                      ),

                      // Work Duration (if checked out)
                      if (checkIn.checkOutTime != null) ...[
                        const SizedBox(height: EmpDailyStyle.spacingM),
                        _buildInfoCard(
                          Icons.timer,
                          'Total Work Duration',
                          checkIn.getWorkDuration() ?? 'N/A',
                        ),
                      ],

                      // Breaks Section
                      if (checkIn.mealBreaks.isNotEmpty ||
                          checkIn.otherBreaks.isNotEmpty) ...[
                        const SizedBox(height: EmpDailyStyle.spacingL),
                        Text(
                          'Break History',
                          style: EmpDailyStyle.headingSmall,
                        ),
                        const SizedBox(height: EmpDailyStyle.spacingM),

                        // Meal Breaks
                        if (checkIn.mealBreaks.isNotEmpty) ...[
                          _buildBreakSection(
                            'Meal Breaks',
                            Icons.restaurant,
                            checkIn.mealBreaks
                                .map(
                                  (mb) => {
                                    'start': mb.startTime,
                                    'end': mb.endTime,
                                    'duration': mb.getDuration(),
                                  },
                                )
                                .toList(),
                          ),
                          const SizedBox(height: EmpDailyStyle.spacingM),
                        ],

                        // Other Breaks
                        if (checkIn.otherBreaks.isNotEmpty) ...[
                          _buildBreakSection(
                            'Other Breaks',
                            Icons.coffee,
                            checkIn.otherBreaks
                                .map(
                                  (ob) => {
                                    'start': ob.startTime,
                                    'end': ob.endTime,
                                    'duration': ob.getDuration(),
                                    'reason': ob.reason,
                                  },
                                )
                                .toList(),
                          ),
                          const SizedBox(height: EmpDailyStyle.spacingM),
                        ],

                        // Break Summary
                        Container(
                          padding: const EdgeInsets.all(EmpDailyStyle.spacingM),
                          decoration: BoxDecoration(
                            color: EmpDailyStyle.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: EmpDailyStyle.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBreakStat(
                                'Meal Breaks',
                                '${checkIn.getTotalMealBreakMinutes()} min',
                                Icons.restaurant,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: EmpDailyStyle.borderColor,
                              ),
                              _buildBreakStat(
                                'Other Breaks',
                                '${checkIn.getTotalOtherBreakMinutes()} min',
                                Icons.coffee,
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: EmpDailyStyle.spacingL),

                      // Images Section
                      Text(
                        'Image Verification',
                        style: EmpDailyStyle.headingSmall,
                      ),
                      const SizedBox(height: EmpDailyStyle.spacingM),

                      Row(
                        children: [
                          Expanded(
                            child: _buildImagePreview(
                              'Original Photo',
                              checkIn.originalImageUrl,
                            ),
                          ),
                          const SizedBox(width: EmpDailyStyle.spacingM),
                          Expanded(
                            child: _buildImagePreview(
                              'Captured Photo',
                              checkIn.capturedImageUrl,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakSection(
    String title,
    IconData icon,
    List<Map<String, dynamic>> breaks,
  ) {
    return Container(
      padding: const EdgeInsets.all(EmpDailyStyle.spacingM),
      decoration: BoxDecoration(
        color: EmpDailyStyle.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmpDailyStyle.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: EmpDailyStyle.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: EmpDailyStyle.labelText),
            ],
          ),
          const SizedBox(height: 12),
          ...breaks.map((brk) {
            final start = brk['start'] as DateTime;
            final end = brk['end'] as DateTime?;
            final duration = brk['duration'] as String;
            final reason = brk['reason'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end != null ? '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}' : 'Ongoing'}',
                          style: EmpDailyStyle.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (reason != null && reason.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            reason,
                            style: EmpDailyStyle.bodySmall.copyWith(
                              color: EmpDailyStyle.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: end != null
                          ? EmpDailyStyle.successColor.withOpacity(0.1)
                          : EmpDailyStyle.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      duration,
                      style: EmpDailyStyle.bodySmall.copyWith(
                        color: end != null
                            ? EmpDailyStyle.successColor
                            : EmpDailyStyle.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBreakStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: EmpDailyStyle.accentColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: EmpDailyStyle.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: EmpDailyStyle.accentColor,
          ),
        ),
        Text(
          label,
          style: EmpDailyStyle.bodySmall.copyWith(
            color: EmpDailyStyle.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(EmpDailyStyle.spacingM),
      decoration: BoxDecoration(
        color: EmpDailyStyle.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EmpDailyStyle.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: EmpDailyStyle.primaryColor),
              const SizedBox(width: 8),
              Text(label, style: EmpDailyStyle.labelText),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: EmpDailyStyle.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: EmpDailyStyle.labelText),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showFullImage(imageUrl, label),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EmpDailyStyle.primaryColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: EmpDailyStyle.primaryColor,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: EmpDailyStyle.cardColor,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: EmpDailyStyle.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullImage(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: EmpDailyStyle.headingSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            InteractiveViewer(child: Image.network(imageUrl)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmpDailyStyle.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(gradient: EmpDailyStyle.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildBreadcrumb(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: EmpDailyStyle.primaryColor,
                        ),
                      )
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
      decoration: BoxDecoration(
        color: EmpDailyStyle.cardColor.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: EmpDailyStyle.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button - always show
          Container(
            decoration: BoxDecoration(
              color: EmpDailyStyle.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: EmpDailyStyle.primaryColor,
              ),
              onPressed: () {
                if (_selectedView != 'department') {
                  // Navigate within the page
                  _handleBack();
                } else {
                  // Navigate back to AdminPanel
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(width: EmpDailyStyle.spacingM),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: EmpDailyStyle.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assessment, color: Colors.white, size: 28),
          ),
          const SizedBox(width: EmpDailyStyle.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Check-ins', style: EmpDailyStyle.headingLarge),
                Text(
                  'Total: ${_allCheckIns.length} records',
                  style: EmpDailyStyle.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: EmpDailyStyle.primaryColor),
            onPressed: _loadCheckIns,
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EmpDailyStyle.spacingL,
        vertical: EmpDailyStyle.spacingM,
      ),
      child: Row(
        children: [
          _buildBreadcrumbItem(
            'Departments',
            _selectedView == 'department',
            () {
              setState(() {
                _selectedView = 'department';
                _selectedDepartment = null;
                _selectedDate = null;
              });
            },
          ),
          if (_selectedDepartment != null) ...[
            const Icon(
              Icons.chevron_right,
              color: EmpDailyStyle.textSecondary,
              size: 16,
            ),
            _buildBreadcrumbItem(
              _selectedDepartment!,
              _selectedView == 'date',
              () {
                setState(() {
                  _selectedView = 'date';
                  _selectedDate = null;
                });
              },
            ),
          ],
          if (_selectedDate != null) ...[
            const Icon(
              Icons.chevron_right,
              color: EmpDailyStyle.textSecondary,
              size: 16,
            ),
            _buildBreadcrumbItem(
              DateFormat('MMM dd').format(DateTime.parse(_selectedDate!)),
              _selectedView == 'employee',
              null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(String text, bool isActive, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? EmpDailyStyle.primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: EmpDailyStyle.bodyMedium.copyWith(
            color: isActive
                ? EmpDailyStyle.primaryColor
                : EmpDailyStyle.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedView == 'department') {
      return _buildDepartmentView();
    } else if (_selectedView == 'date') {
      return _buildDateView();
    } else {
      return _buildEmployeeView();
    }
  }

  Widget _buildDepartmentView() {
    final departments = _groupByDepartment();
    if (departments.isEmpty) {
      return _buildEmptyState('No check-ins found');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
      itemCount: departments.length,
      itemBuilder: (context, index) {
        final department = departments.keys.elementAt(index);
        final checkIns = departments[department]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: EmpDailyStyle.spacingM),
          child: _buildDepartmentCard(department, checkIns.length),
        );
      },
    );
  }

  Widget _buildDepartmentCard(String department, int count) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDepartment = department;
          _selectedView = 'date';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
        decoration: EmpDailyStyle.getCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: EmpDailyStyle.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.business_center,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: EmpDailyStyle.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(department, style: EmpDailyStyle.headingSmall),
                  const SizedBox(height: 4),
                  Text(
                    '$count check-in${count > 1 ? 's' : ''}',
                    style: EmpDailyStyle.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EmpDailyStyle.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: EmpDailyStyle.primaryColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateView() {
    final dates = _groupByDate(_selectedDepartment!);
    if (dates.isEmpty) {
      return _buildEmptyState('No check-ins for this department');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates.keys.elementAt(index);
        final checkIns = dates[date]!;

        return Padding(
          padding: const EdgeInsets.only(bottom: EmpDailyStyle.spacingM),
          child: _buildDateCard(date, checkIns.length),
        );
      },
    );
  }

  Widget _buildDateCard(String date, int count) {
    final dateObj = DateTime.parse(date);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _selectedView = 'employee';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
        decoration: EmpDailyStyle.getCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: EmpDailyStyle.accentGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(dateObj),
                    style: EmpDailyStyle.headingMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(dateObj),
                    style: EmpDailyStyle.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: EmpDailyStyle.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(dateObj),
                    style: EmpDailyStyle.headingSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count employee${count > 1 ? 's' : ''} checked in',
                    style: EmpDailyStyle.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EmpDailyStyle.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: EmpDailyStyle.accentColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeView() {
    final employees = _getEmployeeCheckIns(
      _selectedDepartment!,
      _selectedDate!,
    );
    if (employees.isEmpty) {
      return _buildEmptyState('No employees checked in on this date');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final checkIn = employees[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: EmpDailyStyle.spacingM),
          child: _buildEmployeeCard(checkIn),
        );
      },
    );
  }

  Widget _buildEmployeeCard(CheckIn checkIn) {
    return InkWell(
      onTap: () => _showEmployeeDetail(checkIn),
      child: Container(
        padding: const EdgeInsets.all(EmpDailyStyle.spacingL),
        decoration: EmpDailyStyle.getCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EmpDailyStyle.primaryColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  checkIn.capturedImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: EmpDailyStyle.primaryColor.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        color: EmpDailyStyle.primaryColor,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: EmpDailyStyle.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(checkIn.name, style: EmpDailyStyle.headingSmall),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${checkIn.empId}',
                    style: EmpDailyStyle.bodyMedium.copyWith(
                      color: EmpDailyStyle.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.login,
                        size: 14,
                        color: EmpDailyStyle.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${checkIn.checkInTime.hour.toString().padLeft(2, '0')}:${checkIn.checkInTime.minute.toString().padLeft(2, '0')}',
                        style: EmpDailyStyle.bodySmall,
                      ),
                      if (checkIn.checkOutTime != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.logout,
                          size: 14,
                          color: EmpDailyStyle.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${checkIn.checkOutTime!.hour.toString().padLeft(2, '0')}:${checkIn.checkOutTime!.minute.toString().padLeft(2, '0')}',
                          style: EmpDailyStyle.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EmpDailyStyle.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.visibility,
                color: EmpDailyStyle.successColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: EmpDailyStyle.cardColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox,
              size: 64,
              color: EmpDailyStyle.textSecondary,
            ),
          ),
          const SizedBox(height: EmpDailyStyle.spacingL),
          Text(
            message,
            style: EmpDailyStyle.headingSmall.copyWith(
              color: EmpDailyStyle.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
