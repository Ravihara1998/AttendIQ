import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../style/admin_style.dart';
import '../service/cloudinary_service.dart';
import '../service/firebase_service.dart';
import '../pages/employee_model.dart';
import 'superview.dart';
// import '../pages/empdaily.dart';
import 'supereasy.dart'; // Adjust the path based on your folder structure
import '../widgets/document_upload_dialog.dart';
import '../account/create_account.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuperadminPanel extends StatefulWidget {
  const SuperadminPanel({super.key});

  @override
  State<SuperadminPanel> createState() => _SuperadminPanelState();
}

class _SuperadminPanelState extends State<SuperadminPanel> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();
  final _imagePicker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _empIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _departmentController = TextEditingController();
  final _companyController = TextEditingController();
  final _jobPositionController = TextEditingController();
  final _phoneController = TextEditingController();

  // NEW controllers for requested fields
  final _emergencyController = TextEditingController();
  final _nickNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _joinDateController = TextEditingController();
  DateTime? _joinDate;
  // NEW Controllers for the 4 new fields
  final _healthIssuesController = TextEditingController();
  final _commentsController = TextEditingController();
  final _previousWorkplaceController = TextEditingController();

  // NEW: State for "Ever worked in Sarachandra Group"
  bool _everWorkedInGroup = false;
  List<Map<String, String>> _previousGroupEmployment = [];

  // State
  File? _selectedImage;
  XFile? _selectedXFile;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;

  List<Map<String, String>> _personalDocuments = [];

  // Departments list
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

  // Job Positions list
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
  void dispose() {
    _nameController.dispose();
    _empIdController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    _companyController.dispose();
    _jobPositionController.dispose();
    _phoneController.dispose();
    // NEW: Dispose new controllers
    _healthIssuesController.dispose();
    _commentsController.dispose();
    _previousWorkplaceController.dispose();

    // Dispose new controllers
    _emergencyController.dispose();
    _nickNameController.dispose();
    _idNumberController.dispose();
    _joinDateController.dispose();

    super.dispose();
  }

  // Validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name should only contain letters';
    }
    return null;
  }

  String? _validateaddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmpId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Employee ID is required';
    }
    if (!RegExp(r'^[A-Za-z0-9]{3,20}$').hasMatch(value)) {
      return 'Employee ID should be 3-20 alphanumeric characters';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
      return 'Phone number must be 10–15 digits';
    }

    return null;
  }

  // NEW validators
  String? _validateEmergency(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Emergency contact is required';
    }
    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
      return 'Enter a valid emergency number (10–15 digits)';
    }
    return null;
  }

  String? _validateNickName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nick name is required';
    }
    return null;
  }

  String? _validateIdNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ID number is required';
    }
    return null;
  }

  String? _validateDepartment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a department';
    }
    return null;
  }

  String? _validateCompany(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a company';
    }
    return null;
  }

  // String? _validateJobPosition(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return 'Please select a job position';
  //   }
  //   return null;
  // }

  String? _validateJoinDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Join date is required';
    }
    return null;
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Navigate to login page and remove all previous routes
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
        // Or if you're using a direct route:
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(builder: (context) => const LoginPage()),
        //   (route) => false,
        // );
      }
    } catch (e) {
      if (mounted) {
        AdminStyle.showSnackBar(
          context,
          'Error logging out: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _openDocumentUploadDialog() async {
    final result = await showDialog<List<Map<String, String>>>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          DocumentUploadDialog(initialDocuments: _personalDocuments),
    );

    if (result != null) {
      setState(() {
        _personalDocuments = result;
      });
    }
  }

  // NEW: Dialog for previous Sarachandra Group employment
  Future<void> _openPreviousEmploymentDialog() async {
    DateTime? selectedYear;
    final positionController = TextEditingController();
    final reasonController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formattedYear() {
              if (selectedYear == null) return 'Select year';
              return selectedYear!.year.toString();
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
                              Icons.work_history,
                              color: AdminStyle.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Previous Employment Details',
                              style: AdminStyle.bodyLargeBlack.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Year selector
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedYear ?? DateTime.now(),
                            firstDate: DateTime(1990),
                            lastDate: DateTime.now(),
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
                            setDialogState(() => selectedYear = picked);
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
                              color: selectedYear != null
                                  ? AdminStyle.primaryColor.withOpacity(0.6)
                                  : AdminStyle.borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: selectedYear != null
                                    ? AdminStyle.primaryColor
                                    : AdminStyle.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  formattedYear(),
                                  style: AdminStyle.bodyLarge.copyWith(
                                    color: selectedYear != null
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

                      // Position
                      TextField(
                        controller: positionController,
                        onChanged: (value) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Position held',
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

                      // Reason for leaving
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        onChanged: (value) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Reason for leaving',
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
                                  (selectedYear != null &&
                                      positionController.text
                                          .trim()
                                          .isNotEmpty &&
                                      reasonController.text.trim().isNotEmpty)
                                  ? () {
                                      Navigator.of(context).pop({
                                        'year': selectedYear!.year.toString(),
                                        'position': positionController.text
                                            .trim(),
                                        'reason': reasonController.text.trim(),
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
      setState(() {
        _previousGroupEmployment.add(result);
      });
    }
  }

  // Image picker
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
          _selectedXFile = pickedFile;
          if (!kIsWeb) {
            _selectedImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AdminStyle.showSnackBar(
          context,
          'Error picking image: $e',
          isError: true,
        );
      }
    }
  }

  // Time picker
  Future<void> _pickTime(bool isCheckIn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  // Join date picker (formats dd/MM/yyyy)
  Future<void> _pickJoinDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? DateTime.now(),
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
      setState(() {
        _joinDate = picked;
        final dd = picked.day.toString().padLeft(2, '0');
        final mm = picked.month.toString().padLeft(2, '0');
        final yyyy = picked.year.toString();
        _joinDateController.text = '$dd/$mm/$yyyy'; // dd/MM/yyyy
      });
    }
  }

  // Submit form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedXFile == null) {
      AdminStyle.showSnackBar(
        context,
        'Please select an employee image',
        isError: true,
      );
      return;
    }

    if (_checkInTime == null) {
      AdminStyle.showSnackBar(
        context,
        'Please select check-in time',
        isError: true,
      );
      return;
    }

    if (_checkOutTime == null) {
      AdminStyle.showSnackBar(
        context,
        'Please select check-out time',
        isError: true,
      );
      return;
    }

    if (_joinDateController.text.trim().isEmpty) {
      AdminStyle.showSnackBar(
        context,
        'Please select join date',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Check if employee ID already exists
      final exists = await _firebaseService.isEmployeeIdExists(
        _empIdController.text.trim(),
      );

      if (exists) {
        throw Exception('Employee ID already exists');
      }

      // Upload image to Cloudinary
      setState(() => _uploadProgress = 0.3);
      final imageUrl = await CloudinaryService.uploadImage(
        kIsWeb ? _selectedXFile! : _selectedImage!,
      );

      // Create employee object with new fields
      setState(() => _uploadProgress = 0.7);
      final employee = Employee(
        name: _nameController.text.trim(),
        empId: _empIdController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        department: _departmentController.text,
        userImageUrl: imageUrl,
        company: _companyController.text.trim(),
        jobPosition: _jobPositionController.text,
        emergencyContact: _emergencyController.text.trim(),
        nickName: _nickNameController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        joinDate: _joinDateController.text.trim(),
        checkInTime:
            '${_checkInTime!.hour.toString().padLeft(2, '0')}:${_checkInTime!.minute.toString().padLeft(2, '0')}',
        checkOutTime:
            '${_checkOutTime!.hour.toString().padLeft(2, '0')}:${_checkOutTime!.minute.toString().padLeft(2, '0')}',
        personalDocuments: _personalDocuments,

        // NEW: Add the 4 new fields
        healthIssues: _healthIssuesController.text.trim(),
        comments: _commentsController.text.trim(),
        previousWorkplace: _previousWorkplaceController.text.trim(),
        everWorkedInGroup: _everWorkedInGroup,
        previousGroupEmployment: _everWorkedInGroup
            ? _previousGroupEmployment
            : null,
      );

      // Save to Firebase
      await _firebaseService.addEmployee(employee);

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        AdminStyle.showSnackBar(context, 'Employee registered successfully!');
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        AdminStyle.showSnackBar(
          context,
          'Error: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _empIdController.clear();
    _addressController.clear();
    _departmentController.clear();
    _companyController.clear();
    _jobPositionController.clear();
    _phoneController.clear();
    _emergencyController.clear();
    _nickNameController.clear();
    _idNumberController.clear();
    _joinDateController.clear();
    _joinDate = null;
    // NEW: Clear new controllers
    _healthIssuesController.clear();
    _commentsController.clear();
    _previousWorkplaceController.clear();

    _personalDocuments = [];
    _previousGroupEmployment = [];
    _everWorkedInGroup = false;

    _personalDocuments = []; // <-- ADD THIS LINE

    setState(() {
      _selectedImage = null;
      _selectedXFile = null;
      _checkInTime = null;
      _checkOutTime = null;
    });
  }

  void _navigateToEmployeeView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Superview()),
    );
  }

  void _navigateToCreateAccountPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAccountPage()),
    );
  }

  // void _navigateToDailyCheckIns() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const EmpDailyPage()),
  //   );
  // }

  void _navigateToEasyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Supereasy()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AdminStyle.isDesktop(context);

    return Scaffold(
      backgroundColor: AdminStyle.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AdminStyle.primaryColor,
        title: Text('Super Admin Panel', style: AdminStyle.headingMedium),
        centerTitle: true,
        actions: [
          // IconButton(
          //   onPressed: _navigateToDailyCheckIns,
          //   icon: const Icon(Icons.assessment),
          //   tooltip: 'Daily Check-ins',
          // ),
          IconButton(
            onPressed: _navigateToCreateAccountPage,
            icon: const Icon(Icons.person_add),
            tooltip: 'Create Account',
          ),
          IconButton(
            onPressed: _navigateToEmployeeView,
            icon: const Icon(Icons.people_outline),
            tooltip: 'View Employees',
          ),
          IconButton(
            onPressed: _navigateToEasyPage,
            icon: const Icon(Icons.table_chart),
            tooltip: 'Attendance Report',
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AdminStyle.getResponsivePadding(context),
            child: Container(
              width: AdminStyle.getResponsiveWidth(context),
              constraints: const BoxConstraints(maxWidth: 700),
              decoration: AdminStyle.getCardDecoration(),
              padding: EdgeInsets.all(
                isDesktop ? AdminStyle.spacingXL : AdminStyle.spacingL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AdminStyle.spacingL),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildImagePicker(),
                        const SizedBox(height: AdminStyle.spacingL),

                        // In your build method, move the Salary Increment field from Personal Information
                        // to Organization Details section. Replace the relevant section with this:

                        // Inside the Form widget's Column children, after the Personal Information section:

                        // Section: Personal Information
                        _buildSectionHeader(
                          'Personal Information',
                          Icons.person,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        TextFormField(
                          controller: _nameController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Full Name',
                            hint: 'Enter employee name',
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: _validateName,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // REMOVED: Salary Increment field from here
                        TextFormField(
                          controller: _empIdController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Employee ID',
                            hint: 'e.g., EMP001',
                            prefixIcon: Icons.badge_outlined,
                          ),
                          validator: _validateEmpId,
                        ),
                        const SizedBox(height: AdminStyle.spacingL),

                        TextFormField(
                          controller: _phoneController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Phone Number',
                            hint: 'e.g., 0771234567',
                            prefixIcon: Icons.phone_outlined,
                          ),
                          validator: validatePhoneNumber,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        TextFormField(
                          controller: _addressController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Address',
                            hint: 'Enter address',
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: _validateaddress,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // NEW: Emergency Contact
                        TextFormField(
                          controller: _emergencyController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Emergency Contact No',
                            hint: 'e.g., 0771234567',
                            prefixIcon: Icons.contact_phone_outlined,
                          ),
                          validator: _validateEmergency,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // NEW: Nick Name
                        TextFormField(
                          controller: _nickNameController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Nick Name',
                            hint: 'Enter nick name',
                            prefixIcon: Icons.person_pin,
                          ),
                          validator: _validateNickName,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // NEW: ID Number
                        TextFormField(
                          controller: _idNumberController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'ID Number',
                            hint: 'Enter ID number',
                            prefixIcon: Icons.credit_card_outlined,
                          ),
                          validator: _validateIdNumber,
                        ),
                        const SizedBox(height: AdminStyle.spacingL),

                        // Section: Organization Details
                        _buildSectionHeader(
                          'Organization Details',
                          Icons.business,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // NEW: Join Date (readOnly + date picker)
                        TextFormField(
                          controller: _joinDateController,
                          readOnly: true,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Join Date',
                            hint: 'Select join date',
                            prefixIcon: Icons.calendar_today,
                          ),
                          validator: _validateJoinDate,
                          onTap: _pickJoinDate,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        DropdownButtonFormField<String>(
                          initialValue: _companyController.text.isEmpty
                              ? null
                              : _companyController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Company',
                            hint: 'Select company',
                            prefixIcon: Icons.apartment,
                          ),
                          dropdownColor: const Color.fromARGB(255, 19, 18, 18),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AdminStyle.primaryColor,
                          ),
                          items: _companies.map((company) {
                            return DropdownMenuItem(
                              value: company,
                              child: Text(
                                company,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _companyController.text = value ?? '';
                            });
                          },
                          validator: _validateCompany,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // Department Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _departmentController.text.isEmpty
                              ? null
                              : _departmentController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Department',
                            hint: 'Select department',
                            prefixIcon: Icons.business_outlined,
                          ),
                          dropdownColor: const Color.fromARGB(255, 19, 18, 18),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AdminStyle.primaryColor,
                          ),
                          items: _departments.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(
                                dept,
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 16,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _departmentController.text = value ?? '';
                            });
                          },
                          validator: _validateDepartment,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // Job Position
                        TextFormField(
                          controller: _jobPositionController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
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
                        const SizedBox(height: AdminStyle.spacingM),

                        // NEW: Health Issues
                        TextFormField(
                          controller: _healthIssuesController,
                          style: AdminStyle.bodyLarge,
                          maxLines: 2,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Health Issues',
                            hint: 'Enter any health issues (optional)',
                            prefixIcon: Icons.health_and_safety_outlined,
                          ),
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // NEW: Comments
                        TextFormField(
                          controller: _commentsController,
                          style: AdminStyle.bodyLarge,
                          maxLines: 3,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Comments',
                            hint: 'Enter any additional comments (optional)',
                            prefixIcon: Icons.comment_outlined,
                          ),
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // NEW: Previous Workplace
                        TextFormField(
                          controller: _previousWorkplaceController,
                          style: AdminStyle.bodyLarge,
                          decoration: AdminStyle.getInputDecoration(
                            label: 'Previous Workplace',
                            hint: 'Enter previous workplace (optional)',
                            prefixIcon: Icons.work_outline,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: AdminStyle.spacingM),

                        // NEW: Ever worked in Sarachandra Group
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _everWorkedInGroup
                                  ? AdminStyle.primaryColor.withOpacity(0.5)
                                  : AdminStyle.borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.business_center_outlined,
                                    size: 20,
                                    color: _everWorkedInGroup
                                        ? AdminStyle.primaryColor
                                        : AdminStyle.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Ever worked in Sarachandra Group?',
                                      style: AdminStyle.bodyLargeBlack.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _everWorkedInGroup,
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _everWorkedInGroup = value;
                                              if (!value) {
                                                _previousGroupEmployment = [];
                                              }
                                            });
                                          },
                                    activeThumbColor: AdminStyle.primaryColor,
                                  ),
                                ],
                              ),
                              if (_everWorkedInGroup) ...[
                                const SizedBox(height: 12),
                                const Divider(
                                  height: 1,
                                  color: AdminStyle.borderColor,
                                ),
                                const SizedBox(height: 12),
                                if (_previousGroupEmployment.isNotEmpty)
                                  ..._previousGroupEmployment.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final employment = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AdminStyle.primaryColor
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AdminStyle.primaryColor
                                              .withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${employment['position']} (${employment['year']})',
                                                  style: AdminStyle.bodyMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  employment['reason'] ?? '',
                                                  style: AdminStyle.bodyMedium
                                                      .copyWith(
                                                        color: AdminStyle
                                                            .textSecondary,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                            ),
                                            color: AdminStyle.errorColor,
                                            onPressed: () {
                                              setState(() {
                                                _previousGroupEmployment
                                                    .removeAt(index);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                OutlinedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _openPreviousEmploymentDialog,
                                  icon: const Icon(Icons.add, size: 20),
                                  label: Text(
                                    _previousGroupEmployment.isEmpty
                                        ? 'Add Employment Details'
                                        : 'Add Another',
                                  ),
                                  style: AdminStyle.getSecondaryButtonStyle(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AdminStyle.spacingL),

                        const SizedBox(height: AdminStyle.spacingL),

                        GestureDetector(
                          onTap: _isLoading ? null : _openDocumentUploadDialog,
                          child: Container(
                            padding: EdgeInsets.all(isDesktop ? 18 : 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _personalDocuments.isNotEmpty
                                    ? AdminStyle.primaryColor.withOpacity(0.5)
                                    : AdminStyle.borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 20,
                                  color: _personalDocuments.isNotEmpty
                                      ? AdminStyle.primaryColor
                                      : AdminStyle.textSecondary,
                                ),
                                SizedBox(width: isDesktop ? 16 : 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Personal Documents',
                                        style: AdminStyle.bodyMedium.copyWith(
                                          color: AdminStyle.textSecondary,
                                          fontSize: isDesktop ? 13 : 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _personalDocuments.isEmpty
                                            ? 'Tap to add documents'
                                            : '${_personalDocuments.length} document(s) added',
                                        style: AdminStyle.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: _personalDocuments.isNotEmpty
                                              ? AdminStyle.primaryColor
                                              : AdminStyle.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _personalDocuments.isNotEmpty
                                      ? Icons.check_circle
                                      : Icons.upload_file,
                                  color: _personalDocuments.isNotEmpty
                                      ? Colors.green
                                      : AdminStyle.primaryColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AdminStyle.spacingL),

                        // Section: Working Hours
                        _buildSectionHeader('Working Hours', Icons.access_time),
                        const SizedBox(height: AdminStyle.spacingM),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeSelector(
                                label: 'Check-in',
                                time: _checkInTime,
                                icon: Icons.login,
                                onTap: () => _pickTime(true),
                              ),
                            ),
                            const SizedBox(width: AdminStyle.spacingM),
                            Expanded(
                              child: _buildTimeSelector(
                                label: 'Check-out',
                                time: _checkOutTime,
                                icon: Icons.logout,
                                onTap: () => _pickTime(false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AdminStyle.spacingL),

                        if (_isLoading) ...[
                          LinearProgressIndicator(
                            value: _uploadProgress,
                            backgroundColor: AdminStyle.borderColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AdminStyle.primaryColor,
                            ),
                            minHeight: 8,
                          ),
                          const SizedBox(height: AdminStyle.spacingM),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _resetForm,
                                style: AdminStyle.getSecondaryButtonStyle(),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4.0),
                                  child: Icon(
                                    Icons.refresh,
                                    color: AdminStyle.primaryColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AdminStyle.spacingS),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: AdminStyle.getPrimaryButtonStyle(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Register',
                                          style: AdminStyle.buttonText,
                                        ),
                                ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AdminStyle.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.group_add, size: 40, color: Colors.white),
        ),
        const SizedBox(height: AdminStyle.spacingM),
        Text(
          'Employee Registration',
          style: AdminStyle.headingMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AdminStyle.spacingXS),
        Text(
          'Add new employee to the system',
          style: AdminStyle.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AdminStyle.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AdminStyle.primaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AdminStyle.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AdminStyle.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AdminStyle.primaryColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: time != null
                ? AdminStyle.primaryColor.withOpacity(0.5)
                : AdminStyle.borderColor,
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
                      ? AdminStyle.primaryColor
                      : AdminStyle.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AdminStyle.bodyMedium.copyWith(
                    color: AdminStyle.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              time != null ? time.format(context) : 'Select time',
              style: AdminStyle.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: time != null
                    ? AdminStyle.primaryColor
                    : AdminStyle.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Removed top Personal Documents widget (kept image upload only)
        GestureDetector(
          onTap: _isLoading ? null : _pickImage,
          child: Container(
            height: 200,
            decoration: AdminStyle.getImageContainerDecoration(),
            child: _selectedXFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb
                            ? Image.network(
                                _selectedXFile!.path,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return FutureBuilder<List<int>>(
                                    future: _selectedXFile!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          Uint8List.fromList(snapshot.data!),
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );
                                },
                              )
                            : Image.file(_selectedImage!, fit: BoxFit.cover),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _isLoading ? null : _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AdminStyle.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: AdminStyle.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AdminStyle.spacingS),
                      Text(
                        'Click to upload photo',
                        style: AdminStyle.bodyLarge.copyWith(
                          color: AdminStyle.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('PNG, JPG up to 10MB', style: AdminStyle.bodyMedium),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
