import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/utils/i18n.dart';
import 'package:social_media_app/utils/validation.dart';
import 'package:social_media_app/view_models/auth/register_view_model.dart';
import 'package:social_media_app/widgets/indicators.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    RegisterViewModel viewModel = Provider.of<RegisterViewModel>(context);

    return ValueListenableBuilder<String>(
      valueListenable: I18n.langNotifier,
      builder: (context, currentLang, _) {
        return LoadingOverlay(
          progressIndicator: circularProgress(context),
          isLoading: viewModel.loading,
          child: Scaffold(
            backgroundColor: const Color(0xFFF0F4F8),
            key: viewModel.scaffoldKey,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        // Back to Login Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_back, size: 16, color: Color(0xFF1E293B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    I18n.t('back_home'),
                                    style: const TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // Dark Registration Card
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF232733),
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.20),
                                blurRadius: 24.0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Language Selector
                              _buildLanguageSelector(),
                              const SizedBox(height: 18.0),

                              // White Logo
                              Image.asset(
                                'assets/images/logo_white.png',
                                height: 56.0,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 20.0),

                              // Registration Form
                              _buildForm(context, viewModel),
                              const SizedBox(height: 20.0),

                              // Link: Back to login
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  I18n.t('has_account'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLangButton('pt', '🇧🇷 PT'),
        const SizedBox(width: 8),
        _buildLangButton('en', '🇺🇸 EN'),
        const SizedBox(width: 8),
        _buildLangButton('es', '🇪🇸 ES'),
      ],
    );
  }

  Widget _buildLangButton(String code, String label) {
    bool isSelected = I18n.currentLang == code;
    return InkWell(
      onTap: () => I18n.setLang(code),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF7A00) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7A00) : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, RegisterViewModel viewModel) {
    return Form(
      key: viewModel.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // Name / Username
          _buildField(
            controller: null,
            focusNode: viewModel.usernameFN,
            nextFocusNode: viewModel.emailFN,
            icon: Icons.person_outline,
            hint: I18n.t('username'),
            validator: Validations.validateName,
            onSaved: (val) => viewModel.setName(val),
          ),
          const SizedBox(height: 12.0),

          // Email
          _buildField(
            controller: null,
            focusNode: viewModel.emailFN,
            nextFocusNode: viewModel.countryFN,
            icon: Icons.email_outlined,
            hint: I18n.t('email'),
            keyboardType: TextInputType.emailAddress,
            validator: Validations.validateEmail,
            onSaved: (val) => viewModel.setEmail(val),
          ),
          const SizedBox(height: 12.0),

          // Country / City
          _buildField(
            controller: null,
            focusNode: viewModel.countryFN,
            nextFocusNode: viewModel.passFN,
            icon: Icons.location_on_outlined,
            hint: I18n.t('city'),
            validator: Validations.validateName,
            onSaved: (val) => viewModel.setCountry(val),
          ),
          const SizedBox(height: 12.0),

          // Password
          _buildField(
            controller: null,
            focusNode: viewModel.passFN,
            nextFocusNode: viewModel.cPassFN,
            icon: Icons.lock_outline,
            hint: I18n.t('password'),
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: Validations.validatePassword,
            onSaved: (val) => viewModel.setPassword(val),
          ),
          const SizedBox(height: 12.0),

          // Confirm Password
          _buildField(
            controller: null,
            focusNode: viewModel.cPassFN,
            icon: Icons.lock_outline,
            hint: I18n.t('confirm_password'),
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => viewModel.register(context),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: Validations.validatePassword,
            onSaved: (val) => viewModel.setConfirmPass(val),
          ),
          const SizedBox(height: 18.0),

          // Submit Button
          Container(
            height: 46.0,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: const Color(0xFFFF7A00),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: () => viewModel.register(context),
              child: Text(
                I18n.t('register_btn'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    TextEditingController? controller,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    required IconData icon,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13.5),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFFFF7A00), size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }
}
