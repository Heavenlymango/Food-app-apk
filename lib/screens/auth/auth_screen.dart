import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../app.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _useOtp = false; // login: password vs email OTP toggle

  // Login
  final _loginFormKey = GlobalKey<FormState>();
  final _loginIdCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _obscureLogin = true;

  // Register
  final _regFormKey = GlobalKey<FormState>();
  final _regIdCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  bool _obscureReg = true;

  @override
  void dispose() {
    _loginIdCtrl.dispose();
    _loginPassCtrl.dispose();
    _regIdCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.login(_loginIdCtrl.text.trim(), _loginPassCtrl.text);
    if (auth.error != null && mounted) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  Future<void> _register() async {
    if (!_regFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.register(
      studentId: _regIdCtrl.text.trim(),
      name: _regNameCtrl.text.trim(),
      schoolEmail: _regEmailCtrl.text.trim(),
      password: _regPassCtrl.text,
    );
    if (auth.error != null && mounted) {
      _showError(auth.error!);
      auth.clearError();
    }
    // On success AppNavigator handles redirect automatically
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: kBeige,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/campus_food_logo.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) => Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                          color: kBeige, shape: BoxShape.circle),
                      child: const Icon(Icons.restaurant_menu,
                          size: 48, color: kOrange),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'CAMPUS ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kGreen,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'FOOD',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kOrange,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'ORDERING SYSTEM',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Register or Login to continue',
                    style:
                        TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Tab switcher
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _TabPill(
                          label: 'Login',
                          selected: _isLogin,
                          onTap: () =>
                              setState(() => _isLogin = true),
                        ),
                        _TabPill(
                          label: 'Student Register',
                          selected: !_isLogin,
                          onTap: () =>
                              setState(() => _isLogin = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLogin)
                    _buildLogin(auth)
                  else
                    _buildRegister(auth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── LOGIN ───────────────────────────────────────

  Widget _buildLogin(AuthProvider auth) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: kOrange, size: 20),
              const SizedBox(width: 6),
              const Text('Login',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // Password / OTP toggle
          Row(
            children: [
              _ToggleButton(
                label: 'Password',
                selected: !_useOtp,
                onTap: () => setState(() => _useOtp = false),
              ),
              const SizedBox(width: 8),
              _ToggleButton(
                label: 'Email OTP',
                selected: _useOtp,
                onTap: () => setState(() => _useOtp = true),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Student ID / Seller ID field
          const Text('Student ID or Seller ID',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _loginIdCtrl,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: 'e.g. 20230001  or  A1',
            ),
            validator: (v) => v == null || v.isEmpty
                ? 'Enter your ID'
                : null,
          ),
          const SizedBox(height: 14),

          if (!_useOtp) ...[
            // Password login
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Password',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap),
                  child: Text('Forgot Password?',
                      style:
                          TextStyle(color: kOrange, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _loginPassCtrl,
              obscureText: _obscureLogin,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureLogin
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18,
                      color: Colors.grey),
                  onPressed: () => setState(
                      () => _obscureLogin = !_obscureLogin),
                ),
              ),
              validator: (v) => v == null || v.isEmpty
                  ? 'Enter your password'
                  : null,
            ),
          ] else ...[
            // OTP info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kBeige,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: kOrange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: kOrange, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'An OTP will be sent to your registered school email.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _useOtp ? 'Send OTP' : 'Login',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Sellers: use shop ID (e.g. A1, B2) · password: campus123',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── REGISTER ────────────────────────────────────

  Widget _buildRegister(AuthProvider auth) {
    return Form(
      key: _regFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined,
                  color: kOrange, size: 22),
              const SizedBox(width: 8),
              const Text('Student Registration',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // Student ID
          const Text('Student ID',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _regIdCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. 20230001'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly
            ],
            validator: (v) => v == null || v.isEmpty
                ? 'Enter your student ID'
                : null,
          ),
          const SizedBox(height: 14),

          // Full Name
          const Text('Full Name',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _regNameCtrl,
            decoration:
                const InputDecoration(hintText: 'Your full name'),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                v == null || v.isEmpty ? 'Enter your name' : null,
          ),
          const SizedBox(height: 14),

          // School Email
          RichText(
            text: const TextSpan(
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
              children: [
                TextSpan(text: 'School Email '),
                TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _regEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'yourname@rupp.edu.kh',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your school email';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Used for account verification & password reset',
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 14),

          // Password
          const Text('Password',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _regPassCtrl,
            obscureText: _obscureReg,
            decoration: InputDecoration(
              hintText: 'Min 6 characters',
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureReg
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 18,
                    color: Colors.grey),
                onPressed: () =>
                    setState(() => _obscureReg = !_obscureReg),
              ),
            ),
            validator: (v) => v == null || v.length < 6
                ? 'Min 6 characters'
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Your account will be active immediately. Admin may review later.',
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Create Account',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── SHARED WIDGETS ──────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? kOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? kOrange : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}
