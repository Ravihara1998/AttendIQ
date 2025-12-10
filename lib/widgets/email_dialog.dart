import 'package:flutter/material.dart';
import '../style/easystyle.dart';
import '../service/emailjs_service.dart';
import '../pages/checkin_model.dart';

class EmailDialog extends StatefulWidget {
  final List<CheckIn> checkIns;
  final String dateRange;
  final String companyName;
  final Map<String, double> employeeTotalHours; // NEW

  const EmailDialog({
    super.key,
    required this.checkIns,
    required this.dateRange,
    required this.companyName,
    required this.employeeTotalHours, // NEW
  });

  @override
  State<EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<EmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await EmailJSService.sendAttendanceReport(
        toEmail: _emailController.text.trim(),
        checkIns: widget.checkIns,
        dateRange: widget.dateRange,
        companyName: widget.companyName,
        employeeTotalHours: widget.employeeTotalHours,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email sent successfully to ${_emailController.text.trim()}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Failed to send email. Please try again.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EasyStyle.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: EasyStyle.cardColor,
          borderRadius: BorderRadius.circular(EasyStyle.radiusL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(EasyStyle.radiusM),
                    ),
                    child: const Icon(
                      Icons.email,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: EasyStyle.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send Report via Email',
                          style: EasyStyle.headingMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.checkIns.length} records',
                          style: EasyStyle.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(EasyStyle.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Report Info
                    Container(
                      padding: const EdgeInsets.all(EasyStyle.spacingM),
                      decoration: BoxDecoration(
                        color: EasyStyle.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(EasyStyle.radiusM),
                        border: Border.all(
                          color: EasyStyle.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.business,
                            'Company',
                            widget.companyName,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Period',
                            widget.dateRange,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.table_chart,
                            'Records',
                            '${widget.checkIns.length} entries',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: EasyStyle.spacingL),

                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      style: EasyStyle.bodyLarge.copyWith(
                        color: EasyStyle.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Recipient Email',
                        labelStyle: EasyStyle.bodyMedium.copyWith(
                          color: EasyStyle.textSecondary,
                        ),
                        hintText: 'example@email.com',
                        hintStyle: EasyStyle.bodyMedium,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: EasyStyle.primaryColor,
                        ),
                        filled: true,
                        fillColor: EasyStyle.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EasyStyle.radiusM,
                          ),
                          borderSide: BorderSide(color: EasyStyle.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EasyStyle.radiusM,
                          ),
                          borderSide: BorderSide(color: EasyStyle.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EasyStyle.radiusM,
                          ),
                          borderSide: const BorderSide(
                            color: EasyStyle.primaryColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EasyStyle.radiusM,
                          ),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            EasyStyle.radiusM,
                          ),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email address';
                        }
                        if (!EmailJSService.isValidEmail(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: EasyStyle.spacingL),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: EasyStyle.spacingM,
                              ),
                              side: BorderSide(
                                color: EasyStyle.primaryColor.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  EasyStyle.radiusM,
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: EasyStyle.bodyLarge.copyWith(
                                color: EasyStyle.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: EasyStyle.spacingM),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: EasyStyle.primaryGradient,
                              borderRadius: BorderRadius.circular(
                                EasyStyle.radiusM,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: EasyStyle.spacingM,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    EasyStyle.radiusM,
                                  ),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.send,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Send Email',
                                          style: EasyStyle.bodyLarge.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: EasyStyle.primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: EasyStyle.bodySmall.copyWith(
            color: EasyStyle.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: EasyStyle.bodySmall.copyWith(
              color: EasyStyle.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
