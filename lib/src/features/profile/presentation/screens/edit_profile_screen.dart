import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/src/providers/auth_provider.dart';
import 'package:customer_app/src/constants/app_sizes.dart';
import 'package:customer_app/src/constants/app_strings.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Focus nodes for better interaction
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _mobileFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _mobileController.text = user.mobile;
    }

    _firstNameController.addListener(_checkForChanges);
    _lastNameController.addListener(_checkForChanges);
    _mobileController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      final hasChanges =
          _firstNameController.text != user.firstName ||
          _lastNameController.text != user.lastName ||
          _mobileController.text != user.mobile;

      if (hasChanges != _hasChanges) {
        setState(() => _hasChanges = hasChanges);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      Map<String, String> dataToUpdate = {};
      if (_firstNameController.text != authProvider.user?.firstName) {
        dataToUpdate['first_name'] = _firstNameController.text;
      }
      if (_lastNameController.text != authProvider.user?.lastName) {
        dataToUpdate['last_name'] = _lastNameController.text;
      }
      if (_mobileController.text != authProvider.user?.mobile) {
        dataToUpdate['mobile'] = _mobileController.text;
      }

      if (dataToUpdate.isNotEmpty) {
        final success = await authProvider.updateProfile(dataToUpdate);
        if (!mounted) return;

        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: AppSizes.p12),
                  const Text("Profile updated successfully"),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                  const SizedBox(width: AppSizes.p12),
                  const Text(AppStrings.updateFailed),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radius8),
              ),
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _mobileFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppStrings.editProfile,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.p12),

                // Section Title with decorative element
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Text(
                      "Personal Information",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.p8),

                Text(
                  "Update your personal details below",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppSizes.p32),

                // First Name Field
                _buildModernTextField(
                  theme: theme,
                  controller: _firstNameController,
                  focusNode: _firstNameFocus,
                  label: AppStrings.firstName,
                  hint: "Enter your first name",
                  icon: Icons.person_outline_rounded,
                  nextFocus: _lastNameFocus,
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.enterFirstName
                      : null,
                ),

                const SizedBox(height: AppSizes.p20),

                // Last Name Field
                _buildModernTextField(
                  theme: theme,
                  controller: _lastNameController,
                  focusNode: _lastNameFocus,
                  label: AppStrings.lastName,
                  hint: "Enter your last name",
                  icon: Icons.badge_outlined,
                  nextFocus: _mobileFocus,
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppStrings.enterLastName
                      : null,
                ),

                const SizedBox(height: AppSizes.p20),

                // Mobile Field
                _buildModernTextField(
                  theme: theme,
                  controller: _mobileController,
                  focusNode: _mobileFocus,
                  label: AppStrings.mobile,
                  hint: "03XXXXXXXXX",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.enterMobile;
                    }
                    if (value.length != 11) {
                      return 'Mobile number must be exactly 11 digits';
                    }
                    if (!value.startsWith('03')) {
                      return 'Mobile number must start with 03';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.p40),

                // Save Button with gradient
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                    gradient: _hasChanges && !_isLoading
                        ? LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.85),
                            ],
                          )
                        : null,
                    color: !_hasChanges || _isLoading
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.2))
                        : null,
                    boxShadow: _hasChanges && !_isLoading
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading || !_hasChanges ? null : _updateProfile,
                      borderRadius: BorderRadius.circular(AppSizes.radius16),
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 22,
                                    color: _hasChanges
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.4,
                                                )
                                              : Colors.grey.withValues(
                                                  alpha: 0.5,
                                                )),
                                  ),
                                  const SizedBox(width: AppSizes.p12),
                                  Text(
                                    AppStrings.save,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                      color: _hasChanges
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.4,
                                                  )
                                                : Colors.grey.withValues(
                                                    alpha: 0.5,
                                                  )),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                // Help Text
                if (!_hasChanges)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.p16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p16,
                          vertical: AppSizes.p12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.amber.withValues(alpha: 0.1)
                              : Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppSizes.radius8),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: AppSizes.p8),
                            Text(
                              "Make changes to enable save button",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.amber.shade200
                                    : Colors.amber.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
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
    );
  }

  Widget _buildModernTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? nextFocus,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF374151),
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
              ),
            ),

            // Text Field Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radius16),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                textInputAction: nextFocus != null
                    ? TextInputAction.next
                    : TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (nextFocus != null) {
                    FocusScope.of(context).requestFocus(nextFocus);
                  }
                },
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isFocused
                          ? theme.colorScheme.primary
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : const Color(0xFF6B7280)),
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 2,
                    ),
                  ),
                  errorStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: validator,
              ),
            ),
          ],
        );
      },
    );
  }
}
