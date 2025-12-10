import 'package:flutter/material.dart';
import '../style/easystyle.dart';
import '../service/checkin_service.dart';
import '../pages/checkin_model.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/pdf_generator.dart';
import '../widgets/email_dialog.dart';

class EasyPage extends StatefulWidget {
  const EasyPage({super.key});

  @override
  State<EasyPage> createState() => _EasyPageState();
}

class _EasyPageState extends State<EasyPage> {
  List<CheckIn> _allCheckIns = [];
  List<CheckIn> _filteredCheckIns = [];
  final Map<String, double> _employeeTotalHours =
      {}; // NEW: Store total hours per employee
  bool _isLoading = true;
  String _selectedPeriod = 'daily';
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  static const String TARGET_COMPANY = 'Sarathchandra Pharmacy';

  @override
  void initState() {
    super.initState();
    _loadCheckIns();
  }

  Future<Map<String, dynamic>> _fetchEmployeeDetails(String empId) async {
    try {
      print('Fetching details for empId: $empId');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('empdetails')
          .where('empId', isEqualTo: empId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Document found for empId: $empId');
        final data = querySnapshot.docs.first.data();
        print('Document data: $data');

        final nickname = data['nickName'] ?? '-';
        final company = data['company'] ?? '';

        print('Nickname: $nickname, Company: $company');

        return {'nickName': nickname, 'company': company};
      } else {
        print('No document found for empId: $empId');
        return {'nickName': '-', 'company': ''};
      }
    } catch (e) {
      print('Error fetching employee details: $e');
      return {'nickName': '-', 'company': ''};
    }
  }

  // NEW: Calculate total working hours for each employee
  void _calculateTotalHours() {
    _employeeTotalHours.clear();

    for (var checkIn in _filteredCheckIns) {
      final hours = checkIn.getWorkDurationInHours();
      if (hours != null) {
        _employeeTotalHours[checkIn.empId] =
            (_employeeTotalHours[checkIn.empId] ?? 0.0) + hours;
      }
    }
  }

  Future<void> _sendEmail() async {
    if (_filteredCheckIns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No records to send'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EmailDialog(
        checkIns: _filteredCheckIns,
        dateRange: _getDateRangeText(),
        companyName: TARGET_COMPANY,
        employeeTotalHours: _employeeTotalHours, // NEW: Pass total hours
      ),
    );
  }

  Future<void> _loadCheckIns() async {
    setState(() => _isLoading = true);
    try {
      final checkInService = CheckInService();
      checkInService.getCheckIns().listen((checkIns) async {
        print('Received ${checkIns.length} check-ins');

        if (mounted) {
          final detailsFutures = checkIns
              .map((checkIn) => _fetchEmployeeDetails(checkIn.empId))
              .toList();

          final detailsList = await Future.wait(detailsFutures);
          print('Fetched ${detailsList.length} employee details');

          List<CheckIn> enrichedCheckIns = [];
          for (int i = 0; i < checkIns.length; i++) {
            final details = detailsList[i];
            final company = details['company'] as String;

            if (company.trim().toLowerCase() == TARGET_COMPANY.toLowerCase()) {
              final enriched = checkIns[i].copyWith(
                nickName: details['nickName'] as String,
              );
              print(
                'CheckIn $i: empId=${checkIns[i].empId}, nickname=${enriched.nickName}, company=$company',
              );
              enrichedCheckIns.add(enriched);
            } else {
              print(
                'Filtered out: empId=${checkIns[i].empId}, company=$company (not matching $TARGET_COMPANY)',
              );
            }
          }

          if (mounted) {
            setState(() {
              _allCheckIns = enrichedCheckIns;
              _filterCheckIns();
              _isLoading = false;
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading check-ins: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterCheckIns() {
    List<CheckIn> filtered = _allCheckIns;

    switch (_selectedPeriod) {
      case 'daily':
        filtered = filtered.where((c) {
          return c.checkInTime.year == _selectedDate.year &&
              c.checkInTime.month == _selectedDate.month &&
              c.checkInTime.day == _selectedDate.day;
        }).toList();
        break;
      case 'weekly':
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        filtered = filtered.where((c) {
          return c.checkInTime.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ) &&
              c.checkInTime.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
        break;
      case 'monthly':
        filtered = filtered.where((c) {
          return c.checkInTime.year == _selectedDate.year &&
              c.checkInTime.month == _selectedDate.month;
        }).toList();
        break;
      case 'yearly':
        filtered = filtered.where((c) {
          return c.checkInTime.year == _selectedDate.year;
        }).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.empId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.department.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    filtered.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    setState(() {
      _filteredCheckIns = filtered;
      _calculateTotalHours(); // NEW: Calculate total hours after filtering
    });
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _filterCheckIns();
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _filterCheckIns();
    });
  }

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: EasyStyle.getCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(EasyStyle.spacingL),
                decoration: BoxDecoration(
                  gradient: EasyStyle.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(EasyStyle.radiusL),
                    topRight: Radius.circular(EasyStyle.radiusL),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: EasyStyle.headingMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(EasyStyle.spacingL),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(EasyStyle.radiusM),
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: EasyStyle.surfaceColor,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: EasyStyle.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateRangeText() {
    switch (_selectedPeriod) {
      case 'daily':
        return DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate);
      case 'weekly':
        final startOfWeek = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('MMM dd').format(startOfWeek)} - ${DateFormat('MMM dd, yyyy').format(endOfWeek)}';
      case 'monthly':
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case 'yearly':
        return DateFormat('yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Future<void> _downloadPdf() async {
    if (_filteredCheckIns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No records to download'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await PdfGenerator.generateAndDownloadPdf(
        context: context,
        checkIns: _filteredCheckIns,
        dateRange: _getDateRangeText(),
        company: TARGET_COMPANY,
        employeeTotalHours: _employeeTotalHours, // NEW: Pass total hours
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = EasyStyle.isMobile(context);
    final isTablet = EasyStyle.isTablet(context);

    return Scaffold(
      backgroundColor: EasyStyle.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(gradient: EasyStyle.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isMobile),
              _buildFilters(isMobile, isTablet),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: EasyStyle.primaryColor,
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

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? EasyStyle.spacingM : EasyStyle.spacingL,
      ),
      decoration: BoxDecoration(
        color: EasyStyle.cardColor.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: EasyStyle.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: EasyStyle.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(EasyStyle.radiusM),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: EasyStyle.primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: EasyStyle.spacingM),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: EasyStyle.primaryGradient,
              borderRadius: BorderRadius.circular(EasyStyle.radiusM),
            ),
            child: const Icon(Icons.table_chart, color: Colors.white, size: 28),
          ),
          const SizedBox(width: EasyStyle.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Report',
                  style: isMobile
                      ? EasyStyle.headingMedium
                      : EasyStyle.headingLarge,
                ),
                if (!isMobile)
                  Text(
                    '${_filteredCheckIns.length} records • $TARGET_COMPANY',
                    style: EasyStyle.bodyMedium,
                  ),
              ],
            ),
          ),
          // Email Button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
              ),
              borderRadius: BorderRadius.circular(EasyStyle.radiusM),
            ),
            child: IconButton(
              icon: const Icon(Icons.email, color: Colors.white),
              onPressed: _sendEmail,
              tooltip: 'Send via Email',
            ),
          ),
          const SizedBox(width: EasyStyle.spacingS),
          // Download PDF Button
          Container(
            decoration: BoxDecoration(
              gradient: EasyStyle.primaryGradient,
              borderRadius: BorderRadius.circular(EasyStyle.radiusM),
            ),
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadPdf,
              tooltip: 'Download PDF',
            ),
          ),
          const SizedBox(width: EasyStyle.spacingS),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: EasyStyle.primaryColor),
            onPressed: _loadCheckIns,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? EasyStyle.spacingM : EasyStyle.spacingL,
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodButton('Daily', 'daily', Icons.today),
                const SizedBox(width: EasyStyle.spacingS),
                _buildPeriodButton('Weekly', 'weekly', Icons.view_week),
                const SizedBox(width: EasyStyle.spacingS),
                _buildPeriodButton('Monthly', 'monthly', Icons.calendar_month),
                const SizedBox(width: EasyStyle.spacingS),
                _buildPeriodButton('Yearly', 'yearly', Icons.calendar_today),
              ],
            ),
          ),
          const SizedBox(height: EasyStyle.spacingM),

          Row(
            children: [
              Expanded(
                flex: isMobile ? 3 : 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EasyStyle.spacingM,
                    vertical: EasyStyle.spacingS,
                  ),
                  decoration: EasyStyle.getCardDecoration(),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: EasyStyle.primaryColor,
                        ),
                        onPressed: () => _changeDate(
                          _selectedPeriod == 'daily'
                              ? -1
                              : _selectedPeriod == 'weekly'
                              ? -7
                              : _selectedPeriod == 'monthly'
                              ? -30
                              : -365,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Text(
                          _getDateRangeText(),
                          style: EasyStyle.bodyMedium.copyWith(
                            color: EasyStyle.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: EasyStyle.primaryColor,
                        ),
                        onPressed: () => _changeDate(
                          _selectedPeriod == 'daily'
                              ? 1
                              : _selectedPeriod == 'weekly'
                              ? 7
                              : _selectedPeriod == 'monthly'
                              ? 30
                              : 365,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: EasyStyle.spacingM),

              Expanded(
                flex: isMobile ? 2 : 1,
                child: Container(
                  decoration: EasyStyle.getCardDecoration(),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterCheckIns();
                      });
                    },
                    style: EasyStyle.bodyMedium.copyWith(
                      color: EasyStyle.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: EasyStyle.bodyMedium,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: EasyStyle.primaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: EasyStyle.spacingM,
                        vertical: EasyStyle.spacingM,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, IconData icon) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () => _changePeriod(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EasyStyle.spacingM,
          vertical: EasyStyle.spacingS,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? EasyStyle.primaryGradient : null,
          color: isSelected ? null : EasyStyle.cardColor,
          borderRadius: BorderRadius.circular(EasyStyle.radiusM),
          border: Border.all(
            color: isSelected ? Colors.transparent : EasyStyle.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : EasyStyle.textSecondary,
            ),
            const SizedBox(width: EasyStyle.spacingS),
            Text(
              label,
              style: EasyStyle.bodyMedium.copyWith(
                color: isSelected ? Colors.white : EasyStyle.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_filteredCheckIns.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          margin: const EdgeInsets.all(EasyStyle.spacingM),
          decoration: EasyStyle.getCardDecoration(),
          child: Column(
            children: [
              _buildTableHeader(),
              ..._filteredCheckIns.asMap().entries.map(
                (entry) => _buildTableRow(entry.value, entry.key),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: EasyStyle.getTableHeaderDecoration(),
      padding: const EdgeInsets.all(EasyStyle.spacingM),
      child: Row(
        children: [
          _buildHeaderCell('Nickname', 120),
          _buildHeaderCell('Check-in', 100),
          _buildHeaderCell('Check-out', 100),
          _buildHeaderCell('ID', 100),
          _buildHeaderCell('Department', 120),
          _buildHeaderCell('Date', 120),
          _buildHeaderCell('Duration', 100),
          _buildHeaderCell('Meal Breaks', 110),
          _buildHeaderCell('Other Breaks', 110),
          _buildHeaderCell('Total Hours', 110), // NEW: Total hours column
          _buildHeaderCell('Image', 80),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: EasyStyle.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTableRow(CheckIn checkIn, int index) {
    final isEvenRow = index % 2 == 0;
    final rowColor = isEvenRow ? EasyStyle.cardColor : EasyStyle.surfaceColor;
    final totalHours = _employeeTotalHours[checkIn.empId] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(color: EasyStyle.dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(EasyStyle.spacingM),
      child: Row(
        children: [
          _buildCell(checkIn.nickName, 120),
          _buildCell(DateFormat('hh:mm a').format(checkIn.checkInTime), 100),
          _buildCell(
            checkIn.checkOutTime != null
                ? DateFormat('hh:mm a').format(checkIn.checkOutTime!)
                : 'Not checked out',
            100,
          ),
          _buildCell(checkIn.empId, 100),
          _buildChipCell(checkIn.department, 120),
          _buildCell(DateFormat('MMM dd, yy').format(checkIn.checkInTime), 120),
          _buildCell(checkIn.getWorkDuration() ?? '-', 100),
          _buildCell('${checkIn.getTotalMealBreakMinutes()} min', 110),
          _buildCell('${checkIn.getTotalOtherBreakMinutes()} min', 110),
          _buildTotalHoursCell(totalHours, 110), // NEW: Total hours cell
          _buildImageCell(checkIn, 80),
        ],
      ),
    );
  }

  // NEW: Build total hours cell with highlighting
  Widget _buildTotalHoursCell(double hours, double width) {
    final totalHours = hours.floor();
    final totalMinutes = ((hours - totalHours) * 60).round();

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: EasyStyle.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(EasyStyle.radiusS),
          border: Border.all(
            color: EasyStyle.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          '${totalHours}h ${totalMinutes}m',
          style: EasyStyle.bodyMedium.copyWith(
            color: EasyStyle.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildImageCell(CheckIn checkIn, double width) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () => _showImageDialog(checkIn.capturedImageUrl, checkIn.name),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EasyStyle.radiusS),
            border: Border.all(color: EasyStyle.primaryColor, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(EasyStyle.radiusS - 2),
            child: Image.network(
              checkIn.capturedImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: EasyStyle.primaryColor.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    color: EasyStyle.primaryColor,
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: EasyStyle.bodyMedium.copyWith(color: EasyStyle.textPrimary),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildChipCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: EasyStyle.getChipDecoration(EasyStyle.secondaryColor),
        child: Text(
          text,
          style: EasyStyle.bodySmall.copyWith(
            color: EasyStyle.secondaryColor,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(EasyStyle.spacingXL),
            decoration: BoxDecoration(
              color: EasyStyle.cardColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox,
              size: 64,
              color: EasyStyle.textSecondary,
            ),
          ),
          const SizedBox(height: EasyStyle.spacingL),
          Text(
            'No records found',
            style: EasyStyle.headingMedium.copyWith(
              color: EasyStyle.textSecondary,
            ),
          ),
          const SizedBox(height: EasyStyle.spacingS),
          Text('Try adjusting your filters', style: EasyStyle.bodyMedium),
        ],
      ),
    );
  }
}
