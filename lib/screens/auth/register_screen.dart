import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _otpSent = false;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendOtp(_emailCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _otpSent = true);
      _startResendTimer();
      showSnack(context, 'OTP sent to ${_emailCtrl.text.trim()}');
    } else {
      showSnack(context, auth.error ?? 'Failed to send OTP', isError: true);
    }
  }

  Future<void> _register(String otp) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      otp,
      mobile: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/branch-selection');
    } else {
      showSnack(context, auth.error ?? 'Registration failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🍕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Join PizzaHap', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Create your account to start ordering', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                _label('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'John Doe',
                    prefixIcon: Icon(Icons.person_outline, color: Color(AppColors.primary)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                _label('Email Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: Color(AppColors.primary)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(v.trim())) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('Mobile Number (Optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '9876543210',
                    prefixIcon: Icon(Icons.phone_outlined, color: Color(AppColors.primary)),
                    prefixText: '+91  ',
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(v)) {
                      return 'Enter a valid 10-digit Indian mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: auth.loading ? null : _sendOtp,
                  child: auth.loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send OTP'),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.primary).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(AppColors.primary), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'We sent a 6-digit OTP to ${_emailCtrl.text}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Pinput(
                    length: 6,
                    defaultPinTheme: PinTheme(
                      width: 52, height: 56,
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 52, height: 56,
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(AppColors.primary), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onCompleted: auth.loading ? null : _register,
                  ),
                ),
                const SizedBox(height: 24),
                if (auth.loading)
                  const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
                else
                  Center(
                    child: _resendSeconds > 0
                      ? Text('Resend in ${_resendSeconds}s', style: TextStyle(color: Colors.grey.shade500))
                      : GestureDetector(
                          onTap: _sendOtp,
                          child: const Text('Resend OTP',
                            style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline)),
                        ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => setState(() => _otpSent = false),
                  child: const Text('Edit Details'),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Sign In',
                      style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14));
}
