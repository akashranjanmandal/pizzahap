import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../../providers/providers.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                color: const Color(AppColors.primary).withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -70,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: const Color(AppColors.accent).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: const Color(AppColors.primary).withOpacity(0.3),
                        blurRadius: 16, offset: const Offset(0, 6),
                      )],
                    ),
                    child: const Center(child: Text('🍕', style: TextStyle(fontSize: 38))),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PizzaHap',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(AppColors.textPrimary)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hot, fresh & delicious',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 28),
                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                        color: const Color(AppColors.primary).withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Customer')
                                          ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _UserLoginTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// USER LOGIN TAB
// ─────────────────────────────────────────────────────────────────────

class _UserLoginTab extends StatefulWidget {
  const _UserLoginTab();
  @override
  State<_UserLoginTab> createState() => _UserLoginTabState();
}

class _UserLoginTabState extends State<_UserLoginTab> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _otpSent = false;
  bool _resending = false;
  int _resendSeconds = 0;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

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

  Future<void> _resendOtp() async {
    setState(() => _resending = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendOtp(_emailCtrl.text.trim());
    setState(() => _resending = false);
    if (!mounted) return;
    if (ok) {
      _startResendTimer();
      showSnack(context, 'OTP resent!');
    } else {
      showSnack(context, auth.error ?? 'Failed to resend OTP', isError: true);
    }
  }

  Future<void> _verifyOtp(String otp) async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), otp);
    if (!mounted) return;
    if (ok) {
      // Go to branch selection first
      Navigator.pushReplacementNamed(context, '/branch-selection');
    } else {
      showSnack(context, auth.error ?? 'Invalid OTP', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _otpSent ? 'Enter OTP' : 'Welcome back!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              _otpSent
                ? 'We sent a 6-digit code to\n${_emailCtrl.text}'
                : 'Sign in to order your favourite pizzas 🍕',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),

            if (!_otpSent) ...[
              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _sendOtp,
                  child: auth.loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send OTP'),
                ),
              ),
            ] else ...[
              Center(
                child: Pinput(
                  length: 6,
                  defaultPinTheme: PinTheme(
                    width: 50, height: 54,
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 50, height: 54,
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(AppColors.primary), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onCompleted: auth.loading ? null : _verifyOtp,
                ),
              ),
              const SizedBox(height: 20),
              if (auth.loading)
                const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
              else ...[
                Center(
                  child: _resendSeconds > 0
                    ? Text('Resend OTP in ${_resendSeconds}s', style: TextStyle(color: Colors.grey.shade500, fontSize: 13))
                    : GestureDetector(
                        onTap: _resending ? null : _resendOtp,
                        child: const Text('Resend OTP',
                          style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w700, fontSize: 13, decoration: TextDecoration.underline)),
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: const Text('Change Email'),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("New here? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Create account',
                    style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w700, fontSize: 13, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



