import 'package:flutter/material.dart';
import '../style/employee_style.dart';
import '../service/firebase_service.dart';
import '../service/checkin_service.dart';
import '../pages/employee_model.dart';
import '../pages/checkin_model.dart';
import 'camera_page.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage>
    with SingleTickerProviderStateMixin {
  final _empIdController = TextEditingController();
  final _firebaseService = FirebaseService();
  final _checkInService = CheckInService();
  final _focusNode = FocusNode();

  Employee? _employee;
  CheckIn? _currentCheckIn; // Current clocked-in session
  bool _isLoading = false;
  bool _showDetails = false;
  bool _showSuggestions = false;
  List<Employee> _allEmployees = [];
  List<Employee> _filteredEmployees = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: EmployeeStyle.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _loadAllEmployees();
    _empIdController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _empIdController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllEmployees() async {
    try {
      _firebaseService.getEmployees().listen((employees) {
        if (mounted) {
          setState(() {
            _allEmployees = employees;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }

  void _onSearchChanged() {
    final query = _empIdController.text.trim().toUpperCase();

    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _filteredEmployees = [];
        _showDetails = false;
        _employee = null;
        _currentCheckIn = null;
      });
      return;
    }

    final filtered = _allEmployees.where((emp) {
      return emp.empId.toUpperCase().contains(query) ||
          emp.name.toUpperCase().contains(query);
    }).toList();

    final exactMatch = _allEmployees.firstWhere(
      (emp) => emp.empId.toUpperCase() == query,
      orElse: () => Employee(
        empId: '',
        name: '',
        phone: '',
        address: '',
        department: '',
        userImageUrl: '',
        // added required fields to match the Employee constructor
        nickName: '',
        emergencyContact: '',
        idNumber: '',
        joinDate: DateTime.now().toIso8601String(),
      ),
    );

    if (exactMatch.empId.isNotEmpty) {
      setState(() {
        _employee = exactMatch;
        _filteredEmployees = [];
        _showSuggestions = false;
        _showDetails = true;
      });
      _focusNode.unfocus();
      _animationController.forward(from: 0);
      _checkCurrentClockInStatus();
    } else {
      setState(() {
        _filteredEmployees = filtered;
        _showSuggestions = filtered.isNotEmpty;
        _showDetails = false;
        _employee = null;
        _currentCheckIn = null;
      });
    }
  }

  Future<void> _selectEmployee(Employee employee) async {
    setState(() {
      _employee = employee;
      _empIdController.text = employee.empId;
      _showSuggestions = false;
      _showDetails = true;
    });
    _focusNode.unfocus();
    _animationController.forward(from: 0);
    await _checkCurrentClockInStatus();
  }

  Future<void> _checkCurrentClockInStatus() async {
    if (_employee == null) return;

    setState(() => _isLoading = true);
    try {
      final checkIn = await _checkInService.getCurrentClockedInStatus(
        _employee!.empId,
      );
      setState(() {
        _currentCheckIn = checkIn;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking clock-in status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClockInOut() async {
    if (_employee == null) return;

    if (_currentCheckIn != null && _currentCheckIn!.isClockedIn) {
      // Clock OUT
      await _handleClockOut();
    } else {
      // Clock IN - proceed to camera
      await _proceedToCamera();
    }
  }

  Future<void> _handleOtherBreak() async {
    if (_employee == null || _currentCheckIn == null) return;

    final activeOtherBreak = _currentCheckIn!.getActiveOtherBreak();

    if (activeOtherBreak != null) {
      // End the active other break
      setState(() => _isLoading = true);
      try {
        await _checkInService.endOtherBreak(
          _currentCheckIn!.id!,
          _currentCheckIn!,
        );

        if (mounted) {
          EmployeeStyle.showSnackBar(context, 'Break ended');

          // Redirect to search screen
          setState(() {
            _employee = null;
            _currentCheckIn = null;
            _showDetails = false;
            _empIdController.clear();
            _showSuggestions = false;
            _isLoading = false;
          });
          _animationController.reset();
        }
      } catch (e) {
        if (mounted) {
          EmployeeStyle.showSnackBar(context, 'Error: $e', isError: true);
          setState(() => _isLoading = false);
        }
      }
    } else {
      // Show dialog to enter reason
      _showOtherBreakDialog();
    }
  }

  void _showOtherBreakDialog() {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: EmployeeStyle.getCardDecoration(),
              padding: const EdgeInsets.all(EmployeeStyle.spacingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: EmployeeStyle.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.event_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: EmployeeStyle.spacingM),
                      Expanded(
                        child: Text(
                          'Break Reason',
                          style: EmployeeStyle.headingMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: EmployeeStyle.textSecondary,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: EmployeeStyle.spacingL),

                  Text(
                    'Please enter the reason for this break:',
                    style: EmployeeStyle.bodyMedium,
                  ),
                  const SizedBox(height: EmployeeStyle.spacingM),

                  TextFormField(
                    controller: reasonController,
                    style: EmployeeStyle.bodyLarge,
                    maxLines: 3,
                    enabled: !isSubmitting,
                    decoration: EmployeeStyle.getInputDecoration(
                      label: 'Reason',
                      hint: 'e.g., Personal, Emergency, Meeting...',
                      prefixIcon: Icons.edit_note,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                  ),
                  const SizedBox(height: EmployeeStyle.spacingL),

                  Container(
                    decoration: EmployeeStyle.getPrimaryButtonDecoration(),
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final reason = reasonController.text.trim();

                              if (reason.isEmpty) {
                                EmployeeStyle.showSnackBar(
                                  context,
                                  'Please enter a reason',
                                  isError: true,
                                );
                                return;
                              }

                              // Set loading state in dialog
                              setDialogState(() {
                                isSubmitting = true;
                              });

                              try {
                                await _checkInService.startOtherBreak(
                                  _currentCheckIn!.id!,
                                  _currentCheckIn!,
                                  reason,
                                );

                                // Close dialog first
                                if (mounted) {
                                  Navigator.pop(dialogContext);
                                }

                                // Then show success message and redirect
                                if (mounted) {
                                  EmployeeStyle.showSnackBar(
                                    context,
                                    'Break started: $reason',
                                  );

                                  // Redirect to search screen
                                  setState(() {
                                    _employee = null;
                                    _currentCheckIn = null;
                                    _showDetails = false;
                                    _empIdController.clear();
                                    _showSuggestions = false;
                                    _isLoading = false;
                                  });
                                  _animationController.reset();
                                }
                              } catch (e) {
                                // Close dialog on error
                                if (mounted) {
                                  Navigator.pop(dialogContext);
                                }

                                if (mounted) {
                                  EmployeeStyle.showSnackBar(
                                    context,
                                    'Error: $e',
                                    isError: true,
                                  );
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      style: EmployeeStyle.getPrimaryButtonStyle(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Done', style: EmployeeStyle.buttonText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleMealBreak() async {
    if (_employee == null || _currentCheckIn == null) return;

    setState(() => _isLoading = true);

    try {
      final activeMealBreak = _currentCheckIn!.getActiveMealBreak();

      if (activeMealBreak != null) {
        // End the active meal break
        await _checkInService.endMealBreak(
          _currentCheckIn!.id!,
          _currentCheckIn!,
        );

        if (mounted) {
          EmployeeStyle.showSnackBar(context, 'Meal break ended');
        }
      } else {
        // Start a new meal break
        await _checkInService.startMealBreak(
          _currentCheckIn!.id!,
          _currentCheckIn!,
        );

        if (mounted) {
          EmployeeStyle.showSnackBar(context, 'Meal break started');
        }
      }

      // Redirect to search screen
      setState(() {
        _employee = null;
        _currentCheckIn = null;
        _showDetails = false;
        _empIdController.clear();
        _showSuggestions = false;
        _isLoading = false;
      });
      _animationController.reset();
    } catch (e) {
      if (mounted) {
        EmployeeStyle.showSnackBar(context, 'Error: $e', isError: true);
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClockOut() async {
    if (_currentCheckIn == null) return;

    setState(() => _isLoading = true);

    try {
      // Direct clock-out without confirmation
      await _checkInService.clockOut(_currentCheckIn!.id!);

      if (mounted) {
        EmployeeStyle.showSnackBar(
          context,
          'Successfully clocked out "${_employee!.name}"',
        );

        // Reset the form
        setState(() {
          _employee = null;
          _currentCheckIn = null;
          _showDetails = false;
          _empIdController.clear();
          _showSuggestions = false;
          _isLoading = false;
        });
        _animationController.reset();
      }
    } catch (e) {
      if (mounted) {
        EmployeeStyle.showSnackBar(
          context,
          'Error clocking out: $e',
          isError: true,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _proceedToCamera() async {
    if (_employee == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraPage(employee: _employee!)),
    );

    if (result != null && result is Map && result['success'] == true) {
      // Clock-in was successful, show success message
      final employeeName = result['employeeName'] ?? _employee!.name;

      if (mounted) {
        // Reset to search interface
        setState(() {
          _employee = null;
          _currentCheckIn = null;
          _showDetails = false;
          _empIdController.clear();
          _showSuggestions = false;
        });
        _animationController.reset();

        // Show success message on search interface
        EmployeeStyle.showSnackBar(
          context,
          'Successfully clocked in "$employeeName"',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmployeeStyle.backgroundColor,
      body: GestureDetector(
        onTap: () {
          _focusNode.unfocus();
          setState(() {
            _showSuggestions = false;
          });
        },
        child: Container(
          decoration: const BoxDecoration(gradient: EmployeeStyle.darkGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EmployeeStyle.getResponsivePadding(context),
                child: Container(
                  width: EmployeeStyle.getResponsiveWidth(context),
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      if (!_showDetails) ...[
                        const SizedBox(height: EmployeeStyle.spacingXL),
                        _buildSearchCard(),
                      ],
                      if (_showDetails && _employee != null) ...[
                        const SizedBox(height: EmployeeStyle.spacingM),
                        _buildEmployeeDetails(),
                      ],
                    ],
                  ),
                ),
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
        if (!_showDetails)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: EmployeeStyle.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: EmployeeStyle.primaryColor.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.fingerprint, size: 50, color: Colors.white),
          ),

        if (!_showDetails) const SizedBox(height: EmployeeStyle.spacingM),

        Text(
          'Employee Check-In',
          style: EmployeeStyle.headingLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: EmployeeStyle.spacingXS),

        Text(
          _showDetails
              ? 'Welcome: ${_employee!.name}!'
              : 'Search by Employee ID or Name',
          style: EmployeeStyle.bodyMedium.copyWith(
            fontWeight: _showDetails ? FontWeight.bold : FontWeight.normal,
            fontSize: _showDetails ? 16 : 14,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        if (_showDetails && _employee != null) ...[
          const SizedBox(height: EmployeeStyle.spacingS),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    final isClockedIn = _currentCheckIn != null && _currentCheckIn!.isClockedIn;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: isClockedIn
                ? EmployeeStyle.getStatusBadgeDecoration(false)
                : EmployeeStyle.getPrimaryButtonDecoration(),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleClockInOut,
              style: EmployeeStyle.getPrimaryButtonStyle().copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 21.0, horizontal: 24),
                ),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isClockedIn ? Icons.logout : Icons.camera_alt,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isClockedIn ? 'CLOCK-OUT' : 'CLOCK-IN',
                          style: EmployeeStyle.buttonText.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EmployeeStyle.primaryColor, width: 2),
            ),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _employee = null;
                        _currentCheckIn = null;
                        _showDetails = false;
                        _empIdController.clear();
                        _showSuggestions = false;
                      });
                      _animationController.reset();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: EmployeeStyle.primaryColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  vertical: 19.0,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Cancel',
                style: EmployeeStyle.buttonText.copyWith(
                  color: EmployeeStyle.primaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: EdgeInsets.all(
        EmployeeStyle.isDesktop(context)
            ? EmployeeStyle.spacingL
            : EmployeeStyle.spacingM,
      ),
      decoration: EmployeeStyle.getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: EmployeeStyle.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Search Employee', style: EmployeeStyle.headingSmall),
            ],
          ),
          const SizedBox(height: EmployeeStyle.spacingM),

          Stack(
            children: [
              TextFormField(
                controller: _empIdController,
                focusNode: _focusNode,
                style: EmployeeStyle.bodyLarge,
                keyboardType: TextInputType.number,
                decoration: EmployeeStyle.getInputDecoration(
                  label: 'Employee ID or Name',
                  hint: 'Start typing to search...',
                  prefixIcon: Icons.badge_outlined,
                  suffixIcon: _empIdController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: EmployeeStyle.textSecondary,
                          ),
                          onPressed: () {
                            _empIdController.clear();
                            setState(() {
                              _showSuggestions = false;
                              _showDetails = false;
                              _employee = null;
                              _currentCheckIn = null;
                            });
                          },
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.characters,
                onTap: () {
                  if (_filteredEmployees.isNotEmpty) {
                    setState(() {
                      _showSuggestions = true;
                    });
                  }
                },
              ),

              if (_showSuggestions && _filteredEmployees.isNotEmpty)
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    color: EmployeeStyle.cardColor,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      decoration: BoxDecoration(
                        color: EmployeeStyle.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: EmployeeStyle.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final emp = _filteredEmployees[index];
                          return InkWell(
                            onTap: () => _selectEmployee(emp),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: EmployeeStyle.borderColor
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: EmployeeStyle.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        emp.userImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) {
                                          return Container(
                                            color: EmployeeStyle.primaryColor
                                                .withOpacity(0.2),
                                            child: const Icon(
                                              Icons.person,
                                              color: EmployeeStyle.primaryColor,
                                              size: 20,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          emp.name,
                                          style: EmployeeStyle.bodyLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              emp.empId,
                                              style: EmployeeStyle.bodyMedium
                                                  .copyWith(
                                                    color: EmployeeStyle
                                                        .primaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: EmployeeStyle
                                                    .primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                emp.department,
                                                style: EmployeeStyle.bodyMedium
                                                    .copyWith(
                                                      fontSize: 11,
                                                      color: EmployeeStyle
                                                          .primaryColor,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: EmployeeStyle.primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (!_showSuggestions &&
              !_showDetails &&
              _empIdController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: EmployeeStyle.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Start typing to see suggestions',
                      style: EmployeeStyle.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          if (_empIdController.text.isNotEmpty &&
              _filteredEmployees.isEmpty &&
              !_showDetails)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EmployeeStyle.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: EmployeeStyle.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: EmployeeStyle.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No employee found with this ID or name',
                        style: EmployeeStyle.bodyMedium.copyWith(
                          color: EmployeeStyle.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDetails() {
    final isClockedIn = _currentCheckIn != null && _currentCheckIn!.isClockedIn;
    final activeMealBreak = _currentCheckIn?.getActiveMealBreak();
    final isOnMealBreak = activeMealBreak != null;
    final activeOtherBreak = _currentCheckIn?.getActiveOtherBreak();
    final isOnOtherBreak = activeOtherBreak != null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: EmployeeStyle.getProfileCardDecoration(),
          padding: EdgeInsets.all(
            EmployeeStyle.isDesktop(context)
                ? EmployeeStyle.spacingL
                : EmployeeStyle.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Three Buttons in Parallel: Meal Break, Other Break, and Status
              Row(
                children: [
                  // Meal Break Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isOnMealBreak
                            ? EmployeeStyle.successGradient
                            : LinearGradient(
                                colors: [
                                  EmployeeStyle.warningColor,
                                  EmployeeStyle.warningColor.withOpacity(0.8),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isOnMealBreak
                                        ? EmployeeStyle.successColor
                                        : EmployeeStyle.warningColor)
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed:
                            (!isClockedIn || _isLoading || isOnOtherBreak)
                            ? null
                            : _handleMealBreak,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOnMealBreak
                                  ? Icons.check_circle
                                  : Icons.restaurant,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnMealBreak ? 'End Meal' : 'Meal',
                              style: EmployeeStyle.buttonText.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Other Break Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isOnOtherBreak
                            ? EmployeeStyle.successGradient
                            : LinearGradient(
                                colors: [
                                  Colors.orange,
                                  Colors.orange.withOpacity(0.8),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isOnOtherBreak
                                        ? EmployeeStyle.successColor
                                        : Colors.orange)
                                    .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: (!isClockedIn || _isLoading || isOnMealBreak)
                            ? null
                            : _handleOtherBreak,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          disabledBackgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isOnOtherBreak
                                  ? Icons.check_circle
                                  : Icons.event_note,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnOtherBreak ? 'End Break' : 'Other',
                              style: EmployeeStyle.buttonText.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isClockedIn
                          ? (isOnMealBreak || isOnOtherBreak
                                ? LinearGradient(
                                    colors: [
                                      EmployeeStyle.warningColor,
                                      EmployeeStyle.warningColor.withOpacity(
                                        0.8,
                                      ),
                                    ],
                                  )
                                : EmployeeStyle.successGradient)
                          : EmployeeStyle.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isClockedIn
                                      ? (isOnMealBreak || isOnOtherBreak
                                            ? EmployeeStyle.warningColor
                                            : EmployeeStyle.successColor)
                                      : EmployeeStyle.primaryColor)
                                  .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isOnMealBreak || isOnOtherBreak
                          ? Icons.pause_circle
                          : (isClockedIn
                                ? Icons.access_time
                                : Icons.check_circle),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EmployeeStyle.spacingM),

              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: EmployeeStyle.getImageContainerDecoration(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      _employee!.userImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: EmployeeStyle.primaryColor,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: EmployeeStyle.cardColor,
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: EmployeeStyle.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: EmployeeStyle.spacingM),

              Container(
                padding: const EdgeInsets.all(EmployeeStyle.spacingS),
                decoration: BoxDecoration(
                  color: EmployeeStyle.backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: EmployeeStyle.borderColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    if (isClockedIn && _currentCheckIn != null) ...[
                      EmployeeStyle.buildInfoRow(
                        Icons.schedule,
                        'Clocked In At',
                        '${_currentCheckIn!.checkInTime.hour.toString().padLeft(2, '0')}:${_currentCheckIn!.checkInTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                    if (_currentCheckIn != null &&
                        _currentCheckIn!.mealBreaks.isNotEmpty) ...[
                      Divider(color: EmployeeStyle.borderColor, height: 16),
                      EmployeeStyle.buildInfoRow(
                        Icons.restaurant,
                        'Meal Breaks',
                        '${_currentCheckIn!.mealBreaks.length} taken',
                      ),
                    ],
                    if (_currentCheckIn != null &&
                        _currentCheckIn!.otherBreaks.isNotEmpty) ...[
                      Divider(color: EmployeeStyle.borderColor, height: 16),
                      EmployeeStyle.buildInfoRow(
                        Icons.event_note,
                        'Other Breaks',
                        '${_currentCheckIn!.otherBreaks.length} taken',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
