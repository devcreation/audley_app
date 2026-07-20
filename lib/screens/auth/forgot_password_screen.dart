import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/api_client.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = ApiClient();
  int _step = 0; // 0: email, 1: OTP, 2: new password
  bool _loading = false;
  String _email = '';
  String _resetToken = '';

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    _email = _emailCtrl.text.trim();
    final result = await _api.forgotPassword(_email);
    setState(() => _loading = false);

    if (result['success'] == true) {
      setState(() => _step = 1);
      _showMsg(result['message'] ?? 'OTP sent', false);
    } else {
      _showMsg(result['message'] ?? 'Failed', true);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final result = await _api.verifyOtp(_email, _otpCtrl.text.trim());
    setState(() => _loading = false);

    if (result['success'] == true) {
      _resetToken = result['reset_token'] ?? '';
      setState(() => _step = 2);
    } else {
      _showMsg(result['message'] ?? 'Invalid OTP', true);
    }
  }

  Future<void> _resetPassword() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      _showMsg('Passwords do not match', true);
      return;
    }
    if (_passCtrl.text.length < 8) {
      _showMsg('Password must be at least 8 characters', true);
      return;
    }
    setState(() => _loading = true);
    final result = await _api.resetPassword(_resetToken, _passCtrl.text);
    setState(() => _loading = false);

    if (result['success'] == true) {
      _showMsg('Password reset successful!', false);
      if (mounted) Navigator.pop(context);
    } else {
      _showMsg(result['message'] ?? 'Reset failed', true);
    }
  }

  void _showMsg(String msg, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppTheme.teal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              Row(
                children: List.generate(3, (i) {
                  final labels = ['Email', 'OTP', 'New Password'];
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? AppTheme.teal.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: i == _step ? AppTheme.teal : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              i == _step ? FontWeight.w600 : FontWeight.w400,
                          color: i <= _step ? AppTheme.teal : AppTheme.textLight,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              if (_step == 0) ...[
                const Text(
                  'Enter your registered email address and we\'ll send you a one-time password.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMid),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                _buildButton('SEND OTP', _sendOtp),
              ],

              if (_step == 1) ...[
                Text('We sent a 6-digit OTP to $_email',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textMid)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    prefixIcon: Icon(Icons.pin_outlined, size: 20),
                    counterText: '',
                  ),
                  style: const TextStyle(
                      fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildButton('VERIFY OTP', _verifyOtp),
              ],

              if (_step == 2) ...[
                const Text('Create your new password.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMid)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                    helperText: '8+ chars, upper, lower, number, special',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                _buildButton('RESET PASSWORD', _resetPassword),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}
