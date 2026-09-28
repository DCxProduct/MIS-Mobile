import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_settings.dart';
import '../../core/network/api_client.dart';
import '../../translations/app_localizations.dart';
import '../../widgets/primary_button.dart';

/// No email means request an OTP; an email means confirm OTP and new password.
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key, this.email});
  final String? email;

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  bool get _reset => widget.email != null;

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    final auth = AppSettings.of(context).auth;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_reset) {
        await auth.resetPassword(
          email: widget.email!,
          otp: _otp.text,
          newPassword: _password.text,
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final email = _email.text.trim().toLowerCase();
        await auth.forgotPassword(email);
        if (!mounted) return;
        setState(() => _busy = false);
        final done = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PasswordRecoveryScreen(email: email),
          ),
        );
        if (mounted && done == true) Navigator.pop(context, true);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.text('authTryAgain'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.text(_reset ? 'resetPassword' : 'forgotPassword')),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    _reset ? Icons.lock_reset : Icons.mark_email_read_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.text(
                      _reset ? 'otpInstructions' : 'recoveryInstructions',
                    ),
                  ),
                  if (_reset) ...[
                    const SizedBox(height: 8),
                    Text(widget.email!),
                  ],
                  const SizedBox(height: 24),
                  if (!_reset)
                    TextFormField(
                      key: const ValueKey('recovery-email'),
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l10n.text('email'),
                      ),
                      validator: (value) =>
                          RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(value?.trim() ?? '')
                          ? null
                          : l10n.text('validEmail'),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  if (_reset) ...[
                    TextFormField(
                      key: const ValueKey('recovery-otp'),
                      controller: _otp,
                      enabled: !_busy,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      decoration: InputDecoration(
                        labelText: l10n.text('otpCode'),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? l10n.text('enterOtp')
                          : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      key: const ValueKey('recovery-password'),
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l10n.text('newPassword'),
                        suffixIcon: IconButton(
                          tooltip: l10n.text(
                            _obscure ? 'showPassword' : 'hidePassword',
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.isEmpty ?? true)
                          ? l10n.text('enterPassword')
                          : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      key: const ValueKey('recovery-confirm'),
                      controller: _confirmation,
                      enabled: !_busy,
                      obscureText: _obscure,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: l10n.text('confirmPassword'),
                      ),
                      validator: (value) =>
                          value != _password.text || (value?.isEmpty ?? true)
                          ? l10n.text('passwordMismatch')
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: l10n.text(_reset ? 'resetPassword' : 'sendOtp'),
                    isLoading: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
