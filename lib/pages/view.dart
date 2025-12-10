import 'package:flutter/material.dart';
import '../style/view_style.dart';
import '../style/admin_style.dart';
import '../service/firebase_service.dart';
import '../service/cloudinary_service.dart';
import 'employee_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/document_list_viewer.dart';
import 'package:file_picker/file_picker.dart'; // Add this
import 'dart:convert'; // Add this for JSON encoding
import 'package:url_launcher/url_launcher.dart';

class EmployeeView extends StatefulWidget {
  const EmployeeView({super.key});

  @override
  State<EmployeeView> createState() => _EmployeeViewState();
}

class _EmployeeViewState extends State<EmployeeView> {
  final _firebaseService = FirebaseService();
  final _searchController = TextEditingController();

  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // final List<Map<String, String>> _disciplinaryActions = [];
  // final List<Map<String, String>> _salaryIncrements = [];
  // final List<Map<String, String>> _exitInterviews = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // In _EmployeeViewState class, update the _loadEmployees method:

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final allEmployees = await _firebaseService.getAllEmployees();

      // Filter employees by company (case insensitive)
      final filteredByCompany = allEmployees.where((employee) {
        return employee.company.trim().toLowerCase() ==
            'sarathchandra pharmacy'.toLowerCase();
      }).toList();

      setState(() {
        _allEmployees = filteredByCompany;
        _filteredEmployees = filteredByCompany;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ViewStyle.showSnackBar(
          context,
          'Error loading employees: $e',
          isError: true,
        );
      }
    }
  }

  void _searchEmployees(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredEmployees = _allEmployees;
      } else {
        _filteredEmployees = _allEmployees.where((employee) {
          return employee.empId.toLowerCase().contains(_searchQuery) ||
              employee.name.toLowerCase().contains(_searchQuery) ||
              employee.phone.toLowerCase().contains(_searchQuery) ||
              employee.department.toLowerCase().contains(_searchQuery) ||
              employee.company.toLowerCase().contains(_searchQuery) ||
              employee.jobPosition.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _showEmployeeDetails(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => _EmployeeDetailsDialog(
        employee: employee,
        onUpdate: () {
          _loadEmployees();
        },
        onDelete: () {
          _loadEmployees();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ViewStyle.isDesktop(context);

    return Scaffold(
      backgroundColor: ViewStyle.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ViewStyle.primaryColor,
        title: Text('Employee Directory', style: ViewStyle.appBarTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmployees,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: TextField(
                controller: _searchController,
                style: ViewStyle.bodyLarge,
                decoration: ViewStyle.getSearchDecoration(),
                onChanged: _searchEmployees,
              ),
            ),
          ),

          // Employee Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  '${_filteredEmployees.length} ${_filteredEmployees.length == 1 ? 'Employee' : 'Employees'}',
                  style: ViewStyle.bodyMedium.copyWith(
                    color: ViewStyle.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Employee List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ViewStyle.primaryColor,
                    ),
                  )
                : _filteredEmployees.isEmpty
                ? _buildEmptyState()
                : _buildEmployeeGrid(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ViewStyle.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: ViewStyle.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty
                ? 'No employees found'
                : 'No results for "$_searchQuery"',
            style: ViewStyle.headingSmall.copyWith(
              color: ViewStyle.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add employees to get started'
                : 'Try a different search term',
            style: ViewStyle.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeGrid(bool isDesktop) {
    return GridView.builder(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop
            ? 3
            : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
        childAspectRatio: isDesktop ? 1.0 : 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = _filteredEmployees[index];
        return _buildEmployeeCard(employee);
      },
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return GestureDetector(
      onTap: () => _showEmployeeDetails(employee),
      child: Container(
        decoration: ViewStyle.getCardDecoration(),
        child: Column(
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        employee.userImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: ViewStyle.primaryColor.withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              size: 64,
                              color: ViewStyle.primaryColor,
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Info Section
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: ViewStyle.headingSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (employee.jobPosition.isNotEmpty)
                          Text(
                            employee.jobPosition,
                            style: ViewStyle.bodySmall.copyWith(
                              color: ViewStyle.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: ViewStyle.primaryGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                employee.empId,
                                style: ViewStyle.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 12,
                              color: ViewStyle.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                employee.department,
                                style: ViewStyle.bodySmall.copyWith(
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeDetailsDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _EmployeeDetailsDialog({
    required this.employee,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_EmployeeDetailsDialog> createState() => _EmployeeDetailsDialogState();
}

class _EmployeeDetailsDialogState extends State<_EmployeeDetailsDialog> {
  final _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _departmentController;
  late TextEditingController _companyController;
  late TextEditingController _jobPositionController;
  late TextEditingController _disciplinaryController;
  late TextEditingController _salaryIncrementController;
  late TextEditingController _exitInterviewController;
  // Add these new controllers
  late TextEditingController _nickNameController;
  late TextEditingController _healthIssuesController;
  late TextEditingController _commentsController;
  late TextEditingController _previousWorkplaceController;
  late TextEditingController _idNumberController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _joinDateController;
  late TextEditingController _everWorkedInGroupController;
  late TextEditingController _previousGroupEmploymentController;

  // ADD THESE THREE LINES:
  List<Map<String, String>> _disciplinaryActions = [];
  List<Map<String, String>> _salaryIncrements = [];
  List<Map<String, String>> _exitInterviews = [];

  bool _isEditing = false;
  bool _isLoading = false;
  File? _newImage;
  XFile? _newXFile;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;

  final List<String> _departments = [
    'Engineering',
    'Human Resources',
    'Marketing',
    'Sales',
    'Finance',
    'Operations',
    'IT Support',
    'Customer Service',
    'Security',
  ];

  final List<String> _companies = [
    'Sarathchandra Home Center',
    'Sarathchandra Pharmacy',
    'Account Office',
    'Sarathchandra Jewellers',
    'Sarathchandra Enterprises',
    'Sarathchandra Trading',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _phoneController = TextEditingController(text: widget.employee.phone);
    _addressController = TextEditingController(text: widget.employee.address);
    _departmentController = TextEditingController(
      text: widget.employee.department,
    );
    _companyController = TextEditingController(text: widget.employee.company);
    _jobPositionController = TextEditingController(
      text: widget.employee.jobPosition,
    );

    _nickNameController = TextEditingController(text: widget.employee.nickName);
    _healthIssuesController = TextEditingController(
      text: widget.employee.healthIssues,
    );
    _commentsController = TextEditingController(text: widget.employee.comments);
    _previousWorkplaceController = TextEditingController(
      text: widget.employee.previousWorkplace,
    );
    _idNumberController = TextEditingController(text: widget.employee.idNumber);
    _emergencyContactController = TextEditingController(
      text: widget.employee.emergencyContact,
    );
    _joinDateController = TextEditingController(text: widget.employee.joinDate);

    _everWorkedInGroupController = TextEditingController(
      text: widget.employee.everWorkedInGroup ? 'Yes' : 'No',
    );
    _previousGroupEmploymentController = TextEditingController(
      text: widget.employee.previousGroupEmployment != null
          ? widget.employee.previousGroupEmployment!
                .map((e) => e['position'] ?? '')
                .join(', ')
          : '',
    );

    // ADD THESE THREE:
    _disciplinaryController = TextEditingController();
    _salaryIncrementController = TextEditingController();
    _exitInterviewController = TextEditingController();

    _disciplinaryActions = List.from(widget.employee.disciplinaryActions ?? []);
    _salaryIncrements = List.from(widget.employee.salaryIncrements ?? []);
    _exitInterviews = List.from(widget.employee.exitInterviews ?? []);

    _checkInTime = _parseTimeString(widget.employee.checkInTime);
    _checkOutTime = _parseTimeString(widget.employee.checkOutTime);
  }

  TimeOfDay _parseTimeString(String timeStr) {
    if (timeStr.isEmpty) return const TimeOfDay(hour: 9, minute: 0);
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    _companyController.dispose();
    _jobPositionController.dispose();
    _disciplinaryController.dispose();
    _salaryIncrementController.dispose();
    _exitInterviewController.dispose();
    super.dispose();
    _nickNameController.dispose();
    _healthIssuesController.dispose();
    _commentsController.dispose();
    _previousWorkplaceController.dispose();
    _idNumberController.dispose();
    _emergencyContactController.dispose();
    _joinDateController.dispose();
    _everWorkedInGroupController.dispose();
    _previousGroupEmploymentController.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newXFile = pickedFile;
          if (!kIsWeb) {
            _newImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      ViewStyle.showSnackBar(context, 'Error picking image: $e', isError: true);
    }
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime! : _checkOutTime!,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            colorScheme: const ColorScheme.light(
              primary: ViewStyle.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  Future<void> _openDisciplinaryDialog() async {
    DateTime? selectedDate;
    final reasonController = TextEditingController();
    List<Map<String, String>> disciplinaryDocuments =
        []; // NEW: Store documents

    final result = await showDialog<Map<String, dynamic>>(
      // Changed from Map<String, String> to Map<String, dynamic>
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formattedDate() {
              if (selectedDate == null) return 'Select date';
              final dd = selectedDate!.day.toString().padLeft(2, '0');
              final mm = selectedDate!.month.toString().padLeft(2, '0');
              final yyyy = selectedDate!.year.toString();
              return '$dd/$mm/$yyyy';
            }

            // NEW: Function to pick and upload document
            Future<void> pickAndUploadDocument() async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: [
                    'pdf',
                    'doc',
                    'docx',
                    'jpg',
                    'jpeg',
                    'png',
                  ],
                  allowMultiple: false,
                );

                if (result == null || result.files.isEmpty) return;

                PlatformFile pickedFile = result.files.first;

                if (pickedFile.size > 10 * 1024 * 1024) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File size should not exceed 10MB'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // Ask for document name
                final docName = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final nameController = TextEditingController();
                    return AlertDialog(
                      title: const Text('Document Name'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g., Warning Letter, Investigation Report',
                        ),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (nameController.text.trim().isNotEmpty) {
                              Navigator.pop(
                                context,
                                nameController.text.trim(),
                              );
                            }
                          },
                          style: AdminStyle.getPrimaryButtonStyle(),
                          child: const Text('Continue'),
                        ),
                      ],
                    );
                  },
                );

                if (docName == null || docName.trim().isEmpty) return;

                // Show uploading indicator
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading document...'),
                        ],
                      ),
                      duration: Duration(seconds: 30),
                    ),
                  );
                }

                // Upload to Cloudinary
                String documentUrl;
                if (kIsWeb) {
                  if (pickedFile.bytes == null) {
                    throw Exception('Could not read file data');
                  }
                  documentUrl = await CloudinaryService.uploadDocument(
                    bytes: pickedFile.bytes!,
                    fileName: pickedFile.name,
                  );
                } else {
                  if (pickedFile.path == null) {
                    throw Exception('Could not read file path');
                  }
                  documentUrl = await CloudinaryService.uploadDocument(
                    file: File(pickedFile.path!),
                    fileName: pickedFile.name,
                  );
                }

                // Add to documents list
                setDialogState(() {
                  disciplinaryDocuments.add({
                    'name': docName,
                    'link': documentUrl,
                    'fileName': pickedFile.name,
                    'fileSize': _formatFileSize(pickedFile.size),
                    'uploadDate': DateTime.now().toIso8601String(),
                  });
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Document uploaded successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error uploading document: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AdminStyle.primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.report_problem,
                              color: AdminStyle.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add Disciplinary Action',
                              style: AdminStyle.bodyLargeBlack.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Date selector
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(1990),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AdminStyle.primaryColor,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedDate != null
                                  ? AdminStyle.primaryColor.withOpacity(0.6)
                                  : AdminStyle.borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: selectedDate != null
                                    ? AdminStyle.primaryColor
                                    : AdminStyle.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  formattedDate(),
                                  style: AdminStyle.bodyLarge.copyWith(
                                    color: selectedDate != null
                                        ? AdminStyle.primaryColor
                                        : AdminStyle.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Reason
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        onChanged: (value) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Enter reason',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminStyle.borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminStyle.primaryColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // NEW: Documents Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: disciplinaryDocuments.isNotEmpty
                                ? AdminStyle.primaryColor.withOpacity(0.3)
                                : AdminStyle.borderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 18,
                                  color: AdminStyle.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Supporting Documents',
                                  style: AdminStyle.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                if (disciplinaryDocuments.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AdminStyle.primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${disciplinaryDocuments.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (disciplinaryDocuments.isNotEmpty)
                              ...disciplinaryDocuments.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final doc = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AdminStyle.borderColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.description,
                                        size: 16,
                                        color: AdminStyle.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc['name'] ?? 'Document',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (doc['fileSize'] != null)
                                              Text(
                                                doc['fileSize']!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        color: Colors.red,
                                        onPressed: () {
                                          setDialogState(() {
                                            disciplinaryDocuments.removeAt(
                                              index,
                                            );
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            OutlinedButton.icon(
                              onPressed: pickAndUploadDocument,
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                disciplinaryDocuments.isEmpty
                                    ? 'Add Document'
                                    : 'Add Another',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AdminStyle.primaryColor,
                                side: BorderSide(
                                  color: AdminStyle.primaryColor.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: AdminStyle.getSecondaryButtonStyle(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  (selectedDate != null &&
                                      reasonController.text.trim().isNotEmpty)
                                  ? () {
                                      final dd = selectedDate!.day
                                          .toString()
                                          .padLeft(2, '0');
                                      final mm = selectedDate!.month
                                          .toString()
                                          .padLeft(2, '0');
                                      final yyyy = selectedDate!.year
                                          .toString();
                                      Navigator.of(context).pop({
                                        'date': '$dd/$mm/$yyyy',
                                        'reason': reasonController.text.trim(),
                                        'documents':
                                            disciplinaryDocuments, // NEW: Include documents
                                      });
                                    }
                                  : null,
                              style: AdminStyle.getPrimaryButtonStyle(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text('Save'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final disciplinaryData = {
          'date': result['date'] as String,
          'reason': result['reason'] as String,
          'documents': jsonEncode(
            result['documents'] ?? [],
          ), // NEW: Store documents as JSON
        };

        // Save to Firebase immediately
        await _firebaseService.addDisciplinaryAction(
          widget.employee.id!,
          disciplinaryData,
        );

        // Refresh local state
        setState(() {
          _disciplinaryActions.add(disciplinaryData);
          _disciplinaryController.text =
              '${_disciplinaryActions.length} action(s) added';
          _isLoading = false;
        });

        if (mounted) {
          ViewStyle.showSnackBar(
            context,
            'Disciplinary action added successfully!',
          );
          widget.onUpdate(); // Refresh parent list
        }
      } catch (e) {
        if (mounted) {
          ViewStyle.showSnackBar(
            context,
            'Error saving disciplinary action: $e',
            isError: true,
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _openSalaryIncrementDialog() async {
    DateTime? selectedDate;
    final approvedController = TextEditingController();
    final previousController = TextEditingController();
    final currentController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Use setDialogState instead of setState
            String formattedDate() {
              if (selectedDate == null) return 'Select date';
              final dd = selectedDate!.day.toString().padLeft(2, '0');
              final mm = selectedDate!.month.toString().padLeft(2, '0');
              final yyyy = selectedDate!.year.toString();
              return '$dd/$mm/$yyyy';
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AdminStyle.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.trending_up,
                            color: AdminStyle.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add Salary Increment',
                          style: AdminStyle.bodyLargeBlack.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Date selector
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(1990),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AdminStyle.primaryColor,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(
                            () => selectedDate = picked,
                          ); // Use setDialogState
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedDate != null
                                ? AdminStyle.primaryColor.withOpacity(0.6)
                                : AdminStyle.borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: selectedDate != null
                                  ? AdminStyle.primaryColor
                                  : AdminStyle.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formattedDate(),
                                style: AdminStyle.bodyLarge.copyWith(
                                  color: selectedDate != null
                                      ? AdminStyle.primaryColor
                                      : AdminStyle.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Approved by
                    TextField(
                      controller: approvedController,
                      onChanged: (value) => setDialogState(
                        () {},
                      ), // Trigger rebuild on text change
                      decoration: InputDecoration(
                        hintText: 'Approved by',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AdminStyle.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminStyle.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Previous salary
                    TextField(
                      controller: previousController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(
                        () {},
                      ), // Trigger rebuild on text change
                      decoration: InputDecoration(
                        hintText: 'Previous salary',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminStyle.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Current salary
                    TextField(
                      controller: currentController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setDialogState(
                        () {},
                      ), // Trigger rebuild on text change
                      decoration: InputDecoration(
                        hintText: 'Current salary',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AdminStyle.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: AdminStyle.getSecondaryButtonStyle(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                (selectedDate != null &&
                                    approvedController.text.trim().isNotEmpty &&
                                    previousController.text.trim().isNotEmpty &&
                                    currentController.text.trim().isNotEmpty)
                                ? () {
                                    final dd = selectedDate!.day
                                        .toString()
                                        .padLeft(2, '0');
                                    final mm = selectedDate!.month
                                        .toString()
                                        .padLeft(2, '0');
                                    final yyyy = selectedDate!.year.toString();
                                    Navigator.of(context).pop({
                                      'date': '$dd/$mm/$yyyy',
                                      'approvedBy': approvedController.text
                                          .trim(),
                                      'previousSalary': previousController.text
                                          .trim(),
                                      'currentSalary': currentController.text
                                          .trim(),
                                    });
                                  }
                                : null,
                            style: AdminStyle.getPrimaryButtonStyle(),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text('Save'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        // Save to Firebase immediately
        await _firebaseService.addSalaryIncrement(widget.employee.id!, result);

        // Refresh local state
        setState(() {
          _salaryIncrements.add(result);
          _salaryIncrementController.text =
              '${_salaryIncrements.length} increment(s) added';
          _isLoading = false;
        });

        if (mounted) {
          ViewStyle.showSnackBar(
            context,
            'Salary increment added successfully!',
          );
          widget.onUpdate(); // Refresh parent list
        }
      } catch (e) {
        if (mounted) {
          ViewStyle.showSnackBar(
            context,
            'Error saving salary increment: $e',
            isError: true,
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _openExitInterviewDialog() async {
    DateTime? selectedDate;
    final conductedByController = TextEditingController();
    final commentsController = TextEditingController();
    List<Map<String, String>> exitDocuments = []; // NEW: Store documents

    final result = await showDialog<Map<String, dynamic>>(
      // Changed from Map<String, String> to Map<String, dynamic>
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formattedDate() {
              if (selectedDate == null) return 'Select date';
              final dd = selectedDate!.day.toString().padLeft(2, '0');
              final mm = selectedDate!.month.toString().padLeft(2, '0');
              final yyyy = selectedDate!.year.toString();
              return '$dd/$mm/$yyyy';
            }

            // NEW: Function to pick and upload document
            Future<void> pickAndUploadDocument() async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: [
                    'pdf',
                    'doc',
                    'docx',
                    'jpg',
                    'jpeg',
                    'png',
                  ],
                  allowMultiple: false,
                );

                if (result == null || result.files.isEmpty) return;

                PlatformFile pickedFile = result.files.first;

                if (pickedFile.size > 10 * 1024 * 1024) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('File size should not exceed 10MB'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // Ask for document name
                final docName = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    final nameController = TextEditingController();
                    return AlertDialog(
                      title: const Text('Document Name'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Exit Letter, Clearance Form',
                        ),
                        autofocus: true,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (nameController.text.trim().isNotEmpty) {
                              Navigator.pop(
                                context,
                                nameController.text.trim(),
                              );
                            }
                          },
                          style: AdminStyle.getPrimaryButtonStyle(),
                          child: const Text('Continue'),
                        ),
                      ],
                    );
                  },
                );

                if (docName == null || docName.trim().isEmpty) return;

                // Show uploading indicator
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading document...'),
                        ],
                      ),
                      duration: Duration(seconds: 30),
                    ),
                  );
                }

                // Upload to Cloudinary
                String documentUrl;
                if (kIsWeb) {
                  if (pickedFile.bytes == null) {
                    throw Exception('Could not read file data');
                  }
                  documentUrl = await CloudinaryService.uploadDocument(
                    bytes: pickedFile.bytes!,
                    fileName: pickedFile.name,
                  );
                } else {
                  if (pickedFile.path == null) {
                    throw Exception('Could not read file path');
                  }
                  documentUrl = await CloudinaryService.uploadDocument(
                    file: File(pickedFile.path!),
                    fileName: pickedFile.name,
                  );
                }

                // Add to documents list
                setDialogState(() {
                  exitDocuments.add({
                    'name': docName,
                    'link': documentUrl,
                    'fileName': pickedFile.name,
                    'fileSize': _formatFileSize(pickedFile.size),
                    'uploadDate': DateTime.now().toIso8601String(),
                  });
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Document uploaded successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error uploading document: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AdminStyle.primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.exit_to_app,
                              color: AdminStyle.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add Exit Interview',
                              style: AdminStyle.bodyLargeBlack.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Date selector
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(1990),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AdminStyle.primaryColor,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedDate != null
                                  ? AdminStyle.primaryColor.withOpacity(0.6)
                                  : AdminStyle.borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: selectedDate != null
                                    ? AdminStyle.primaryColor
                                    : AdminStyle.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  formattedDate(),
                                  style: AdminStyle.bodyLarge.copyWith(
                                    color: selectedDate != null
                                        ? AdminStyle.primaryColor
                                        : AdminStyle.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Conducted by
                      TextField(
                        controller: conductedByController,
                        onChanged: (value) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Who conducted the interview',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminStyle.borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminStyle.primaryColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Comments
                      TextField(
                        controller: commentsController,
                        maxLines: 5,
                        onChanged: (value) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Comments / Notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminStyle.borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AdminStyle.primaryColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // NEW: Documents Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: exitDocuments.isNotEmpty
                                ? AdminStyle.primaryColor.withOpacity(0.3)
                                : AdminStyle.borderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 18,
                                  color: AdminStyle.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Exit Documents',
                                  style: AdminStyle.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                if (exitDocuments.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AdminStyle.primaryColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${exitDocuments.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (exitDocuments.isNotEmpty)
                              ...exitDocuments.asMap().entries.map((entry) {
                                final index = entry.key;
                                final doc = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AdminStyle.borderColor,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.description,
                                        size: 16,
                                        color: AdminStyle.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              doc['name'] ?? 'Document',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (doc['fileSize'] != null)
                                              Text(
                                                doc['fileSize']!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                        ),
                                        color: Colors.red,
                                        onPressed: () {
                                          setDialogState(() {
                                            exitDocuments.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            OutlinedButton.icon(
                              onPressed: pickAndUploadDocument,
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                exitDocuments.isEmpty
                                    ? 'Add Document'
                                    : 'Add Another',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AdminStyle.primaryColor,
                                side: BorderSide(
                                  color: AdminStyle.primaryColor.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: AdminStyle.getSecondaryButtonStyle(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  (selectedDate != null &&
                                      conductedByController.text
                                          .trim()
                                          .isNotEmpty &&
                                      commentsController.text.trim().isNotEmpty)
                                  ? () {
                                      final dd = selectedDate!.day
                                          .toString()
                                          .padLeft(2, '0');
                                      final mm = selectedDate!.month
                                          .toString()
                                          .padLeft(2, '0');
                                      final yyyy = selectedDate!.year
                                          .toString();
                                      Navigator.of(context).pop({
                                        'date': '$dd/$mm/$yyyy',
                                        'conductedBy': conductedByController
                                            .text
                                            .trim(),
                                        'comments': commentsController.text
                                            .trim(),
                                        'documents':
                                            exitDocuments, // NEW: Include documents
                                      });
                                    }
                                  : null,
                              style: AdminStyle.getPrimaryButtonStyle(),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text('Save'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final exitData = {
          'date': result['date'] as String,
          'conductedBy': result['conductedBy'] as String,
          'comments': result['comments'] as String,
          'documents': jsonEncode(result['documents'] ?? []),
        };

        // Save to Firebase immediately
        await _firebaseService.addExitInterview(widget.employee.id!, exitData);

        // Refresh local state
        setState(() {
          _exitInterviews.add(exitData);
          _exitInterviewController.text =
              '${_exitInterviews.length} interview(s) added';
          _isLoading = false;
        });

        if (mounted) {
          ViewStyle.showSnackBar(context, 'Exit interview added successfully!');
          widget.onUpdate(); // Refresh parent list
        }
      } catch (e) {
        if (mounted) {
          ViewStyle.showSnackBar(
            context,
            'Error saving exit interview: $e',
            isError: true,
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // NEW: Add helper method for file size formatting (add this after _openExitInterviewDialog)
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Replace your _updateEmployee() method in view.dart with this:

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = widget.employee.userImageUrl;

      if (_newXFile != null) {
        imageUrl = await CloudinaryService.uploadImage(
          kIsWeb ? _newXFile! : _newImage!,
        );
      }

      final updatedEmployee = Employee(
        id: widget.employee.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        empId: widget.employee.empId,
        address: _addressController.text.trim(),
        department: _departmentController.text,
        userImageUrl: imageUrl,
        company: _companyController.text.trim(),
        jobPosition: _jobPositionController.text,
        nickName: _nickNameController.text.trim(),
        healthIssues: _healthIssuesController.text.trim(),
        comments: _commentsController.text.trim(),
        previousWorkplace: _previousWorkplaceController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        joinDate: _joinDateController.text.trim(),
        previousGroupEmployment:
            _previousGroupEmploymentController.text.trim().isEmpty
            ? null
            : _previousGroupEmploymentController.text
                  .split(',')
                  .map((e) => {'position': e.trim()})
                  .toList(),
        everWorkedInGroup:
            _everWorkedInGroupController.text.trim().toLowerCase() == 'yes',
        checkInTime:
            '${_checkInTime!.hour.toString().padLeft(2, '0')}:${_checkInTime!.minute.toString().padLeft(2, '0')}',
        checkOutTime:
            '${_checkOutTime!.hour.toString().padLeft(2, '0')}:${_checkOutTime!.minute.toString().padLeft(2, '0')}',
        // Keep existing HR records - don't overwrite them
        personalDocuments: widget.employee.personalDocuments,
        disciplinaryActions: widget.employee.disciplinaryActions,
        salaryIncrements: widget.employee.salaryIncrements,
        exitInterviews: widget.employee.exitInterviews,
      );

      await _firebaseService.updateEmployee(updatedEmployee);

      if (mounted) {
        ViewStyle.showSnackBar(context, 'Employee updated successfully!');
        Navigator.pop(context);
        widget.onUpdate();
      }
    } catch (e) {
      if (mounted) {
        ViewStyle.showSnackBar(
          context,
          'Error updating employee: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEmployee() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete ${widget.employee.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ViewStyle.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _firebaseService.deleteEmployee(widget.employee.id!);
        if (mounted) {
          ViewStyle.showSnackBar(context, 'Employee deleted successfully!');
          Navigator.pop(context);
          widget.onDelete();
        }
      } catch (e) {
        if (mounted) {
          ViewStyle.showSnackBar(
            context,
            'Error deleting employee: $e',
            isError: true,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ViewStyle.isDesktop(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 700 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        decoration: ViewStyle.getDialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with image
            Stack(
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        _newXFile != null && kIsWeb
                            ? _newXFile!.path
                            : widget.employee.userImageUrl,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: _pickImage,
                      backgroundColor: ViewStyle.primaryColor,
                      child: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
              ],
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _isEditing ? _buildEditForm() : _buildViewContent(),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ViewStyle.surfaceColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  // Update your _EmployeeDetailsDialogState class in view.dart
  // Replace the entire _buildViewContent() method with this enhanced version:

  Widget _buildViewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and Position
        Text(widget.employee.name, style: ViewStyle.headingLarge),
        if (widget.employee.jobPosition.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.employee.jobPosition,
            style: ViewStyle.bodyLarge.copyWith(
              color: ViewStyle.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Basic Info Grid
        _buildBasicInfoGrid(),
        const SizedBox(height: 20),

        // Personal Details Section
        _buildSectionHeader('Personal Details', Icons.person_outline),
        const SizedBox(height: 12),
        _buildPersonalDetails(),
        const SizedBox(height: 20),

        // Working Hours Section
        _buildSectionHeader('Working Hours', Icons.access_time),
        const SizedBox(height: 12),
        _buildWorkingHours(),
        const SizedBox(height: 20),

        // Personal Documents Section (if available)
        if (widget.employee.personalDocuments != null &&
            widget.employee.personalDocuments!.isNotEmpty) ...[
          _buildSectionHeader('Personal Documents', Icons.folder_outlined),
          const SizedBox(height: 12),
          _buildPersonalDocuments(),
          const SizedBox(height: 20),
        ],

        // HR Records Section - Categorized View
        _buildSectionHeader('HR Records', Icons.folder_special_outlined),
        const SizedBox(height: 12),
        _buildCategorizedHRRecords(),
        const SizedBox(height: 20),

        _buildQuickActionButtons(),
      ],
    );
  }

  Widget _buildCategorizedHRRecords() {
    final hasDisciplinary =
        widget.employee.disciplinaryActions != null &&
        widget.employee.disciplinaryActions!.isNotEmpty;
    final hasSalary =
        widget.employee.salaryIncrements != null &&
        widget.employee.salaryIncrements!.isNotEmpty;
    final hasExit =
        widget.employee.exitInterviews != null &&
        widget.employee.exitInterviews!.isNotEmpty;

    if (!hasDisciplinary && !hasSalary && !hasExit) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ViewStyle.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ViewStyle.borderColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: ViewStyle.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No HR records available',
              style: ViewStyle.bodyLarge.copyWith(
                color: ViewStyle.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use the buttons below to add records',
              style: ViewStyle.bodySmall.copyWith(
                color: ViewStyle.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Disciplinary Actions Category
        if (hasDisciplinary) ...[
          _buildCategoryCard(
            title: 'Disciplinary Actions',
            icon: Icons.report_problem_outlined,
            color: ViewStyle.errorColor,
            count: widget.employee.disciplinaryActions!.length,
            onTap: () => _showCategoryDetails(
              'Disciplinary Actions',
              Icons.report_problem_outlined,
              ViewStyle.errorColor,
              _buildDisciplinaryActions(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Salary Increments Category
        if (hasSalary) ...[
          _buildCategoryCard(
            title: 'Salary History',
            icon: Icons.trending_up,
            color: Colors.green,
            count: widget.employee.salaryIncrements!.length,
            onTap: () => _showCategoryDetails(
              'Salary History',
              Icons.trending_up,
              Colors.green,
              _buildSalaryIncrements(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Exit Interviews Category
        if (hasExit) ...[
          _buildCategoryCard(
            title: 'Exit Interviews',
            icon: Icons.exit_to_app,
            color: ViewStyle.accentColor,
            count: widget.employee.exitInterviews!.length,
            onTap: () => _showCategoryDetails(
              'Exit Interviews',
              Icons.exit_to_app,
              ViewStyle.accentColor,
              _buildExitInterviews(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ViewStyle.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ViewStyle.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? 'record' : 'records'}',
                    style: ViewStyle.bodySmall.copyWith(
                      color: ViewStyle.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View',
                    style: ViewStyle.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 14, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDetails(
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ViewStyle.isDesktop(context) ? 700 : double.infinity,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: ViewStyle.getDialogDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: ViewStyle.headingMedium.copyWith(color: color),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Disciplinary',
            Icons.report_problem_outlined,
            ViewStyle.errorColor,
            _openDisciplinaryDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Salary',
            Icons.trending_up,
            Colors.green,
            _openSalaryIncrementDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Exit',
            Icons.exit_to_app,
            ViewStyle.accentColor,
            _openExitInterviewDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: ViewStyle.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Add these new helper methods to _EmployeeDetailsDialogState class:

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ViewStyle.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: ViewStyle.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: ViewStyle.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ViewStyle.primaryColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactInfoCard(
                Icons.badge_outlined,
                'Employee ID',
                widget.employee.empId,
                ViewStyle.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactInfoCard(
                Icons.business_outlined,
                'Department',
                widget.employee.department,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.employee.company.isNotEmpty)
          _buildInfoCard(
            Icons.apartment,
            'Company',
            widget.employee.company,
            Colors.purple,
          ),
        const SizedBox(height: 12),
        if (widget.employee.phone.isNotEmpty)
          _buildInfoCard(
            Icons.phone_outlined,
            'Phone',
            widget.employee.phone,
            Colors.green,
          ),
      ],
    );
  }

  Widget _buildCompactInfoCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: ViewStyle.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ViewStyle.primaryColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ViewStyle.bodySmall.copyWith(
                    color: ViewStyle.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: ViewStyle.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Added missing helper to render a full-width info card used elsewhere in the dialog.
  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ViewStyle.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ViewStyle.primaryColor.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ViewStyle.bodySmall.copyWith(
                    color: ViewStyle.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: ViewStyle.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ViewStyle.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ViewStyle.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.person_pin,
            'Nick Name',
            widget.employee.nickName,
          ),
          const Divider(height: 24, color: ViewStyle.borderColor),
          _buildDetailRow(
            Icons.health_and_safety_outlined,
            'Health Issues',
            widget.employee.healthIssues,
          ),
          const Divider(height: 24, color: ViewStyle.borderColor),
          _buildDetailRow(
            Icons.health_and_safety_outlined,
            'Comments',
            widget.employee.comments,
          ),

          const Divider(height: 24, color: ViewStyle.borderColor),
          _buildDetailRow(
            Icons.health_and_safety_outlined,
            'Previous Workplace',
            widget.employee.previousWorkplace,
          ),

          const Divider(height: 24, color: ViewStyle.borderColor),
          _buildDetailRow(
            Icons.health_and_safety_outlined,
            'Address',
            widget.employee.address,
          ),

          const Divider(height: 24, color: ViewStyle.borderColor),
          _buildDetailRow(
            Icons.credit_card_outlined,
            'ID Number',
            widget.employee.idNumber,
          ),
          const Divider(height: 24, color: ViewStyle.borderColor),
          _buildDetailRow(
            Icons.contact_phone_outlined,
            'Emergency Contact',
            widget.employee.emergencyContact,
          ),
          const Divider(height: 24, color: ViewStyle.borderColor),
          _buildDetailRow(
            Icons.calendar_today,
            'Join Date',
            widget.employee.joinDate,
          ),

          const Divider(height: 24, color: ViewStyle.borderColor),
          _buildDetailRow(
            Icons.health_and_safety_outlined,
            'Previous Position in Sarathchandra Group',
            (widget.employee.previousGroupEmployment ?? '').toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ViewStyle.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: ViewStyle.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ViewStyle.bodySmall.copyWith(
                  color: ViewStyle.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: ViewStyle.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHours() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ViewStyle.primaryColor.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ViewStyle.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeInfo(
              'Check-in',
              widget.employee.checkInTime,
              Icons.login,
              Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: ViewStyle.borderColor,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: _buildTimeInfo(
              'Check-out',
              widget.employee.checkOutTime,
              Icons.logout,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ViewStyle.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ViewStyle.primaryColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: ViewStyle.bodySmall.copyWith(
                  color: ViewStyle.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time.isNotEmpty ? time : 'Not set',
            style: ViewStyle.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDocuments() {
    return DocumentListViewer(documents: widget.employee.personalDocuments!);
  }

  Widget _buildDisciplinaryActions() {
    return Column(
      children: widget.employee.disciplinaryActions!.map((action) {
        // Parse documents from JSON string
        List<Map<String, String>> documents = [];
        if (action['documents'] != null) {
          try {
            final decoded = jsonDecode(action['documents']!);
            documents = (decoded as List)
                .map((doc) => Map<String, String>.from(doc as Map))
                .toList();
          } catch (e) {
            print('Error parsing documents: $e');
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ViewStyle.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ViewStyle.errorColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ViewStyle.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: ViewStyle.errorColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    action['date'] ?? '',
                    style: ViewStyle.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ViewStyle.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ViewStyle.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action['reason'] ?? 'No reason provided',
                      style: ViewStyle.bodyMedium,
                    ),

                    // NEW: Display Documents
                    if (documents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: ViewStyle.borderColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: ViewStyle.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Supporting Documents (${documents.length})',
                            style: ViewStyle.bodySmall.copyWith(
                              color: ViewStyle.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...documents.map((doc) {
                        IconData fileIcon = Icons.description;
                        Color fileColor = Colors.blue;

                        if (doc['fileName'] != null) {
                          final extension = doc['fileName']!
                              .toLowerCase()
                              .split('.')
                              .last;
                          switch (extension) {
                            case 'pdf':
                              fileIcon = Icons.picture_as_pdf;
                              fileColor = Colors.red;
                              break;
                            case 'doc':
                            case 'docx':
                              fileIcon = Icons.description;
                              fileColor = Colors.blue;
                              break;
                            case 'jpg':
                            case 'jpeg':
                            case 'png':
                              fileIcon = Icons.image;
                              fileColor = Colors.green;
                              break;
                          }
                        }

                        return InkWell(
                          onTap: () async {
                            final url = doc['link'];
                            if (url != null && url.isNotEmpty) {
                              try {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cannot open this document',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error opening document: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: fileColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: fileColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    fileIcon,
                                    size: 18,
                                    color: fileColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc['name'] ?? 'Document',
                                        style: ViewStyle.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (doc['fileSize'] != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          doc['fileSize']!,
                                          style: ViewStyle.bodySmall.copyWith(
                                            color: ViewStyle.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new,
                                  size: 16,
                                  color: ViewStyle.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSalaryIncrements() {
    return Column(
      children: widget.employee.salaryIncrements!.map((increment) {
        final previous =
            double.tryParse(increment['previousSalary'] ?? '0') ?? 0;
        final current = double.tryParse(increment['currentSalary'] ?? '0') ?? 0;
        final increase = current - previous;
        final percentage = previous > 0 ? (increase / previous * 100) : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1),
                ViewStyle.primaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        increment['date'] ?? '',
                        style: ViewStyle.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${percentage.toStringAsFixed(1)}%',
                      style: ViewStyle.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ViewStyle.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Previous Salary',
                              style: ViewStyle.bodySmall.copyWith(
                                color: ViewStyle.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${increment['previousSalary'] ?? '0'}',
                              style: ViewStyle.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward, color: Colors.green),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Current Salary',
                              style: ViewStyle.bodySmall.copyWith(
                                color: ViewStyle.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${increment['currentSalary'] ?? '0'}',
                              style: ViewStyle.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (increment['approvedBy'] != null) ...[
                      const Divider(height: 20, color: ViewStyle.borderColor),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: ViewStyle.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Approved by: ${increment['approvedBy']}',
                            style: ViewStyle.bodySmall.copyWith(
                              color: ViewStyle.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExitInterviews() {
    return Column(
      children: widget.employee.exitInterviews!.map((interview) {
        // Parse documents from JSON string
        List<Map<String, String>> documents = [];
        if (interview['documents'] != null) {
          try {
            final decoded = jsonDecode(interview['documents']!);
            documents = (decoded as List)
                .map((doc) => Map<String, String>.from(doc as Map))
                .toList();
          } catch (e) {
            // Handle parsing error
            print('Error parsing documents: $e');
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ViewStyle.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ViewStyle.accentColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ViewStyle.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.exit_to_app,
                      color: ViewStyle.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exit Interview',
                        style: ViewStyle.bodySmall.copyWith(
                          color: ViewStyle.textSecondary,
                        ),
                      ),
                      Text(
                        interview['date'] ?? '',
                        style: ViewStyle.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ViewStyle.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: ViewStyle.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Conducted by: ${interview['conductedBy'] ?? 'N/A'}',
                          style: ViewStyle.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: ViewStyle.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Comments:',
                      style: ViewStyle.bodySmall.copyWith(
                        color: ViewStyle.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      interview['comments'] ?? 'No comments provided',
                      style: ViewStyle.bodyMedium,
                    ),

                    // NEW: Display Documents
                    if (documents.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: ViewStyle.borderColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            size: 16,
                            color: ViewStyle.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Exit Documents (${documents.length})',
                            style: ViewStyle.bodySmall.copyWith(
                              color: ViewStyle.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...documents.map((doc) {
                        IconData fileIcon = Icons.description;
                        Color fileColor = Colors.blue;

                        if (doc['fileName'] != null) {
                          final extension = doc['fileName']!
                              .toLowerCase()
                              .split('.')
                              .last;
                          switch (extension) {
                            case 'pdf':
                              fileIcon = Icons.picture_as_pdf;
                              fileColor = Colors.red;
                              break;
                            case 'doc':
                            case 'docx':
                              fileIcon = Icons.description;
                              fileColor = Colors.blue;
                              break;
                            case 'jpg':
                            case 'jpeg':
                            case 'png':
                              fileIcon = Icons.image;
                              fileColor = Colors.green;
                              break;
                          }
                        }

                        return InkWell(
                          onTap: () async {
                            final url = doc['link'];
                            if (url != null && url.isNotEmpty) {
                              try {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cannot open this document',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error opening document: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: fileColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: fileColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    fileIcon,
                                    size: 18,
                                    color: fileColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc['name'] ?? 'Document',
                                        style: ViewStyle.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (doc['fileSize'] != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          doc['fileSize']!,
                                          style: ViewStyle.bodySmall.copyWith(
                                            color: ViewStyle.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.open_in_new,
                                  size: 16,
                                  color: ViewStyle.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Full Name',
              hint: 'Enter employee name',
              prefixIcon: Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _companies.contains(_companyController.text.trim())
                ? _companyController.text.trim()
                : null,
            style: ViewStyle.bodyLarge1,
            decoration: ViewStyle.getInputDecoration(
              label: 'Company',
              hint: 'Select company',
              prefixIcon: Icons.apartment,
            ),
            items: _companies.map((company) {
              return DropdownMenuItem(value: company, child: Text(company));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _companyController.text = value ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a company';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _departmentController.text.isEmpty
                ? null
                : _departmentController.text,
            style: ViewStyle.bodyLarge1,
            decoration: ViewStyle.getInputDecoration(
              label: 'Department',
              hint: 'Select department',
              prefixIcon: Icons.business_outlined,
            ),
            items: _departments.map((dept) {
              return DropdownMenuItem(value: dept, child: Text(dept));
            }).toList(),
            onChanged: (value) {
              setState(() => _departmentController.text = value ?? '');
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a department';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _jobPositionController,
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Job Position',
              hint: 'Enter job position',
              prefixIcon: Icons.work_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Job position is required';
              }
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Time Pickers
          Text(
            'Working Hours',
            style: ViewStyle.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: ViewStyle.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeSelector(
                  label: 'Check-in Time',
                  time: _checkInTime,
                  icon: Icons.login,
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeSelector(
                  label: 'Check-out Time',
                  time: _checkOutTime,
                  icon: Icons.logout,
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _nickNameController, // Use controller
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Nick Name',
              hint: 'No nickname',
              prefixIcon: Icons.person_pin,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _healthIssuesController, // Use controller
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Health Issues',
              hint: 'No Health Issues',
              prefixIcon: Icons.person_pin,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _commentsController, // Use controller
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Comments',
              hint: 'No comments',
              prefixIcon: Icons.person_pin,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _previousWorkplaceController, // Use controller
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Previous Workplace',
              hint: 'No previous workplace',
              prefixIcon: Icons.person_pin,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addressController, // Use controller
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Address',
              hint: 'Enter address',
              prefixIcon: Icons.person_pin,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _idNumberController, // Use controller
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'ID Number',
              hint: 'Enter ID number',
              prefixIcon: Icons.credit_card_outlined,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emergencyContactController, // Use controller
            style: ViewStyle.bodyLarge,
            keyboardType: TextInputType.phone,
            decoration: ViewStyle.getInputDecoration(
              label: 'Emergency Contact',
              hint: 'Enter emergency contact',
              prefixIcon: Icons.contact_phone_outlined,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _joinDateController, // Use controller
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Join Date',
              hint: 'DD/MM/YYYY',
              prefixIcon: Icons.calendar_today,
            ),
          ),

          const SizedBox(height: 16),
          TextFormField(
            controller: _previousGroupEmploymentController, // Use controller
            style: ViewStyle.bodyLarge,
            decoration: ViewStyle.getInputDecoration(
              label: 'Position in Sarathchandra Group',
              hint: 'Enter position inSarathchandra Group',
              prefixIcon: Icons.person_pin,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: time != null
                ? ViewStyle.primaryColor.withOpacity(0.5)
                : ViewStyle.borderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: time != null
                      ? ViewStyle.primaryColor
                      : ViewStyle.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: ViewStyle.bodyMedium.copyWith(
                    color: ViewStyle.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time != null ? time.format(context) : 'Select time',
              style: ViewStyle.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: time != null
                    ? ViewStyle.primaryColor
                    : ViewStyle.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ViewStyle.primaryColor),
      );
    }

    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              style: ViewStyle.getSecondaryButtonStyle(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _updateEmployee,
              style: ViewStyle.getPrimaryButtonStyle(),
              child: const Text('Save Changes'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _deleteEmployee,
            style: ViewStyle.getDeleteButtonStyle(),
            child: const Icon(Icons.delete_outline, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Edit'),
            style: ViewStyle.getPrimaryButtonStyle(),
          ),
        ),
      ],
    );
  }
}
