import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../style/account_style.dart';
import '../service/account_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountService = AccountService();

  // Secure storage for sensitive data
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load saved credentials if remember me was checked
  Future<void> _loadSavedCredentials() async {
    try {
      // Check remember me preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;

      if (rememberMe) {
        // Load encrypted credentials from secure storage
        final savedEmail = await _secureStorage.read(key: 'saved_email');
        final savedPassword = await _secureStorage.read(key: 'saved_password');

        if (savedEmail != null && savedPassword != null) {
          setState(() {
            _rememberMe = rememberMe;
            _emailController.text = savedEmail;
            _passwordController.text = savedPassword;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
      // If there's an error, clear potentially corrupted data
      await _clearSavedCredentials();
    }
  }

  // Save credentials securely if remember me is checked
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_rememberMe) {
        // Save remember me preference
        await prefs.setBool('remember_me', true);

        // Save credentials to secure storage (encrypted)
        await _secureStorage.write(
          key: 'saved_email',
          value: _emailController.text.trim(),
        );
        await _secureStorage.write(
          key: 'saved_password',
          value: _passwordController.text,
        );
      } else {
        // Clear all saved credentials
        await _clearSavedCredentials();
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  // Clear all saved credentials
  Future<void> _clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
      await _secureStorage.delete(key: 'saved_email');
      await _secureStorage.delete(key: 'saved_password');
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save credentials before attempting login
      await _saveCredentials();

      final account = await _accountService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Navigate based on role
        if (account.role == 'Super Admin') {
          Navigator.pushReplacementNamed(context, '/superadmin');
        } else {
          // Company-based routing configuration
          final companyRoutes = _getCompanyRoutes();
          final companyName = account.company?.toLowerCase().trim() ?? '';

          // Check if company is registered and get its route
          if (companyRoutes.containsKey(companyName)) {
            Navigator.pushReplacementNamed(
              context,
              companyRoutes[companyName]!,
            );
          } else {
            AccountStyle.showSnackBar(
              context,
              'Company not registered. Please contact support.',
              isError: true,
            );
          }
        }
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

  // Company routing configuration - easily add more companies here
  Map<String, String> _getCompanyRoutes() {
    return {
      'sarathchandra home center': '/admin',
      // Add more companies here in the future:
      // 'company name 2': '/admin-company2',
      // 'company name 3': '/admin-company3',
      // 'abc corporation': '/admin-abc',
    };
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
                    _buildLoginForm(isMobile),
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
        // Logo/Icon with animated gradient
        Container(
          padding: const EdgeInsets.all(AccountStyle.spacingXL),
          decoration: BoxDecoration(
            gradient: AccountStyle.primaryGradient,
            borderRadius: BorderRadius.circular(AccountStyle.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AccountStyle.primaryColor.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_person_rounded,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AccountStyle.spacingL),

        Text(
          'Welcome Back',
          style: isMobile
              ? AccountStyle.headingLarge
              : AccountStyle.headingXLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AccountStyle.spacingS),

        Text(
          'Sign in to your account to continue',
          style: AccountStyle.bodyLarge.copyWith(
            color: AccountStyle.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isMobile) {
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
            // Email Field
            TextFormField(
              controller: _emailController,
              style: AccountStyle.bodyLarge,
              keyboardType: TextInputType.emailAddress,
              decoration: AccountStyle.getInputDecoration(
                label: 'Email',
                hint: 'Enter your email',
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

            // Password Field
            TextFormField(
              controller: _passwordController,
              style: AccountStyle.bodyLarge,
              obscureText: _obscurePassword,
              decoration: AccountStyle.getInputDecoration(
                label: 'Password',
                hint: 'Enter your password',
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
                return null;
              },
            ),
            const SizedBox(height: AccountStyle.spacingL),

            // Remember Me & Forgot Password Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: AccountStyle.spacingS),
                    Text(
                      'Remember me',
                      style: AccountStyle.bodySmall.copyWith(
                        color: AccountStyle.textSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Handle forgot password
                  },
                  child: Text(
                    'Forgot Password?',
                    style: AccountStyle.bodySmall.copyWith(
                      color: AccountStyle.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AccountStyle.spacingXL),

            // Login Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
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
                          const Icon(Icons.login, size: 20),
                          const SizedBox(width: AccountStyle.spacingS),
                          Text(
                            'Sign In',
                            style: AccountStyle.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: AccountStyle.spacingXL),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: AccountStyle.borderColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AccountStyle.spacingM,
                  ),
                  child: Text(
                    'OR',
                    style: AccountStyle.bodySmall.copyWith(
                      color: AccountStyle.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: AccountStyle.borderColor),
                ),
              ],
            ),
            const SizedBox(height: AccountStyle.spacingXL),

            // Create Account Button
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create-account');
                },
                style: AccountStyle.getSecondaryButtonStyle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_outlined, size: 20),
                    const SizedBox(width: AccountStyle.spacingS),
                    Text(
                      'Create New Account',
                      style: AccountStyle.bodyLarge.copyWith(
                        color: AccountStyle.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AccountStyle.spacingL),

            // Footer Text
            Center(
              child: Text(
                '© 2024 Your Company. All rights reserved.',
                style: AccountStyle.bodySmall.copyWith(
                  color: AccountStyle.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
