import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/auth/register/register.dart';
import 'package:social_media_app/utils/download_helper.dart';
import 'package:social_media_app/utils/i18n.dart';
import 'package:social_media_app/utils/validation.dart';
import 'package:social_media_app/view_models/auth/login_view_model.dart';
import 'package:social_media_app/widgets/indicators.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    LoginViewModel viewModel = Provider.of<LoginViewModel>(context);

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 860;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Bar with Back Link
                            _buildTopBar(context),
                            const SizedBox(height: 24.0),

                            // Main Content (Split on Desktop, Stack on Mobile)
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left side: Welcome greeting, illustration, bullet points
                                  Expanded(
                                    flex: 6,
                                    child: _buildLeftWelcomePane(context),
                                  ),
                                  const SizedBox(width: 48.0),
                                  // Right side: Dark card with logo, language selector, form
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 420),
                                    child: _buildDarkCard(context, viewModel),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildLeftWelcomePane(context, compact: true),
                                  const SizedBox(height: 24.0),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 420),
                                    child: _buildDarkCard(context, viewModel),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return InkWell(
      onTap: () {
        // Safe return
      },
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
    );
  }

  Widget _buildLeftWelcomePane(BuildContext context, {bool compact = false}) {
    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          I18n.t('greeting'),
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          I18n.t('welcome_sub'),
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20.0),
        Center(
          child: Image.asset(
            'assets/images/login.png',
            height: compact ? 160.0 : 250.0,
            fit: BoxFit.contain,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 24.0),
          _buildBulletItem(I18n.t('bullet_1')),
          const SizedBox(height: 10.0),
          _buildBulletItem(I18n.t('bullet_2')),
          const SizedBox(height: 10.0),
          _buildBulletItem(I18n.t('bullet_3')),
        ],
      ],
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 14,
            color: Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkCard(BuildContext context, LoginViewModel viewModel) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Language Selector Bar
          _buildLanguageSelector(),
          const SizedBox(height: 20.0),

          // Official White Logo
          Image.asset(
            'assets/images/logo_white.png',
            height: 52.0,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8.0),
          const Text(
            '𝗜𝓩𝓮𝓷𝔂',
            style: TextStyle(
              fontFamily: 'NotoSansMath',
              fontSize: 24.0,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24.0),

          // Form fields (Email, Password, Access Button)
          _buildForm(context, viewModel),
          const SizedBox(height: 16.0),

          // Links: Forgot Password & Register
          GestureDetector(
            onTap: () => viewModel.forgotPassword(context),
            child: Text(
              I18n.t('forgot_pass'),
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => Register()),
              );
            },
            child: Text(
              I18n.t('no_account'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF34D399),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  I18n.t('or_continue'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Colors.white24, thickness: 1)),
            ],
          ),
          const SizedBox(height: 18.0),

          // Google Login Button
          Container(
            height: 44.0,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Login com Google em integração. Acesse com seu e-mail e senha.'),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.g_mobiledata, color: Color(0xFF4285F4), size: 28),
                  const SizedBox(width: 8.0),
                  Text(
                    I18n.t('google_continue'),
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // APK Download Link
          InkWell(
            onTap: downloadApk,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.android, color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 6.0),
                  Text(
                    I18n.t('download_apk'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
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

  Widget _buildForm(BuildContext context, LoginViewModel viewModel) {
    return Form(
      key: viewModel.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // Email input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextFormField(
              enabled: !viewModel.loading,
              focusNode: viewModel.emailFN,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.person, color: Color(0xFFFF7A00), size: 20),
                hintText: I18n.t('email'),
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
              validator: Validations.validateEmail,
              onSaved: (String? val) {
                viewModel.setEmail(val);
              },
            ),
          ),
          const SizedBox(height: 14.0),

          // Password input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: TextFormField(
              enabled: !viewModel.loading,
              focusNode: viewModel.passFN,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => viewModel.login(context),
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.lock, color: Color(0xFFFF7A00), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                hintText: I18n.t('password'),
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
              validator: Validations.validatePassword,
              onSaved: (String? val) {
                viewModel.setPassword(val);
              },
            ),
          ),
          const SizedBox(height: 18.0),

          // Orange Submit Button
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
              onPressed: () => viewModel.login(context),
              child: Text(
                I18n.t('login_btn'),
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
}
