import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_settings.dart';
import '../../translations/app_localizations.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/primary_button.dart';
import '../loading/loading_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  static const _allowedAccounts = {
    'ministry@gmail.com',
    'privatesector@gmail.com',
    'cdc@gmail.com',
    'cefp@gmail.com',
    'secretariat@gmail.com',
    'cdcgpsf@gmail.com',
  };

  static const _requiredPassword = '12345678';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).text('invalidCredentials');
      });
      return;
    }

    AppSettings.of(context).setUserEmail(email);
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LoadingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: AppLogo(width: 190)),
                const SizedBox(height: 82),
                _FieldLabel(l10n.text('email')),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(context, l10n.text('email')),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return l10n.text('enterEmail');
                    }
                    if (!text.contains('@')) {
                      return l10n.text('validEmail');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _FieldLabel(l10n.text('password')),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: _inputDecoration(context, l10n.text('password'))
                      .copyWith(
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? l10n.text('showPassword')
                              : l10n.text('hidePassword'),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) {
                      return l10n.text('enterPassword');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                PrimaryButton(
                  label: l10n.text('signAccount'),
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      l10n.text('forgotPassword'),
                      style: const TextStyle(
                        color: Colors.red,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.red,
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

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF283143) : AppColors.fieldBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: AppColors.accent(context), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        color: colors.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
