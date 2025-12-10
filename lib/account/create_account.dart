import 'package:flutter/material.dart';
import '../style/account_style.dart';
import '../service/account_service.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountService = AccountService();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Admin';
  String? _selectedCompany;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _roles = ['Admin', 'Super Admin'];
  final List<String> _companies = [
    'Sarathchandra Home Center',
    'Company A',
    'Company B',
    'Company C',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate company for Admin role
    if (_selectedRole == 'Admin' && _selectedCompany == null) {
      AccountStyle.showSnackBar(
        context,
        'Please select a company for Admin role',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _accountService.createAccount(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        company: _selectedRole == 'Admin' ? _selectedCompany : null,
      );

      if (mounted) {
        AccountStyle.showSnackBar(context, 'Account created successfully!');

        // Clear form
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() {
          _selectedRole = 'Admin';
          _selectedCompany = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AccountStyle.showSnackBar(
          context,
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AccountStyle.isMobile(context);
    final isDesktop = AccountStyle.isDesktop(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AccountStyle.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? AccountStyle.spacingM : AccountStyle.spacingXL,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 500 : double.infinity,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(
                      height: isMobile
                          ? AccountStyle.spacingL
                          : AccountStyle.spacingXL,
                    ),
                    _buildForm(isMobile),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        // Icon with gradient background
        Container(
          padding: const EdgeInsets.all(AccountStyle.spacingL),
          decoration: BoxDecoration(
            gradient: AccountStyle.primaryGradient,
            borderRadius: BorderRadius.circular(AccountStyle.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AccountStyle.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AccountStyle.spacingL),

        Text(
          'Create Account',
          style: isMobile
              ? AccountStyle.headingLarge
              : AccountStyle.headingXLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AccountStyle.spacingS),

        Text(
          'Set up admin or super admin accounts',
          style: AccountStyle.bodyLarge.copyWith(
            color: AccountStyle.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? AccountStyle.spacingL : AccountStyle.spacingXL,
      ),
      decoration: AccountStyle.getCardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username
            TextFormField(
              controller: _usernameController,
              style: AccountStyle.bodyLarge,
              decoration: AccountStyle.getInputDecoration(
                label: 'Username',
                hint: 'Enter username',
                prefixIcon: Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AccountStyle.spacingM),

            // Email
            TextFormField(
              controller: _emailController,
              style: AccountStyle.bodyLarge,
              keyboardType: TextInputType.emailAddress,
              decoration: AccountStyle.getInputDecoration(
                label: 'Email',
                hint: 'Enter email address',
                prefixIcon: Icons.email_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AccountStyle.spacingM),

            // Password
            TextFormField(
              controller: _passwordController,
              style: AccountStyle.bodyLarge,
              obscureText: _obscurePassword,
              decoration: AccountStyle.getInputDecoration(
                label: 'Password',
                hint: 'Enter password',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AccountStyle.primaryColor,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AccountStyle.spacingM),

            // Role Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              style: AccountStyle.bodyLarge,
              decoration: AccountStyle.getInputDecoration(
                label: 'Role',
                hint: 'Select role',
                prefixIcon: Icons.admin_panel_settings_outlined,
              ),
              items: _roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      Icon(
                        role == 'Super Admin'
                            ? Icons.stars
                            : Icons.person_outline,
                        size: 18,
                        color: AccountStyle.primaryColor,
                      ),
                      const SizedBox(width: AccountStyle.spacingS),
                      Text(role),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                  if (_selectedRole == 'Super Admin') {
                    _selectedCompany = null;
                  }
                });
              },
            ),

            // Company Selection (only for Admin)
            if (_selectedRole == 'Admin') ...[
              const SizedBox(height: AccountStyle.spacingM),
              DropdownButtonFormField<String>(
                initialValue: _selectedCompany,
                style: AccountStyle.bodyLarge,
                decoration: AccountStyle.getInputDecoration(
                  label: 'Company *',
                  hint: 'Select company',
                  prefixIcon: Icons.business_outlined,
                ),
                items: _companies.map((company) {
                  return DropdownMenuItem(value: company, child: Text(company));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCompany = value);
                },
                validator: (value) {
                  if (_selectedRole == 'Admin' && value == null) {
                    return 'Company is required for Admin role';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: AccountStyle.spacingXL),

            // Create Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createAccount,
                style: AccountStyle.getPrimaryButtonStyle().copyWith(
                  backgroundColor: WidgetStateProperty.all(
                    _isLoading
                        ? AccountStyle.primaryColor.withOpacity(0.6)
                        : AccountStyle.primaryColor,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 20),
                          const SizedBox(width: AccountStyle.spacingS),
                          Text(
                            'Create Account',
                            style: AccountStyle.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: AccountStyle.spacingL),

            // Back to Login
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: AccountStyle.primaryColor,
                  ),
                  const SizedBox(width: AccountStyle.spacingS),
                  Text(
                    'Back to Login',
                    style: AccountStyle.bodyMedium.copyWith(
                      color: AccountStyle.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
