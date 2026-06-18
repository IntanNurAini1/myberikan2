import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/auth_controller.dart';
import 'dashboard_hr.dart';
import 'dashboard_karyawan_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = AuthController();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onMasuk() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnack('Nama pengguna dan kata sandi wajib diisi.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _controller.login(
        username: username,
        password: password,
      );

      if (!mounted) return;

      // role dari field 'role' di collection karyawan
      final role = (result['role'] as String? ?? '').toUpperCase();

      // Cek apakah role termasuk HR
      final isHR = role.contains('HR');

      if (isHR) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardHrScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const DashboardKaryawanScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onLupaKataSandi() {
    // TODO: navigasi ke halaman lupa kata sandi
  }

  void _onDaftar() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEEF4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                ),
              ),

              const SizedBox(height: 52),

              _buildLabel('Nama Pengguna'),
              const SizedBox(height: 8),
              _buildTextField(
                fieldKey: const Key('usernameField'),
                controller: _usernameController,
                hint: 'Masukkan Nama Pengguna',
                obscure: false,
              ),

              const SizedBox(height: 20),

              _buildLabel('Kata Sandi'),
              const SizedBox(height: 8),
              _buildTextField(
                fieldKey: const Key('passwordField'),
                controller: _passwordController,
                hint: 'Masukkan kata sandi',
                obscure: _obscurePassword,
                suffixIcon: _eyeIcon(
                  obscure: _obscurePassword,
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: _onLupaKataSandi,
                child: const Text(
                  'Lupa kata sandi?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color(0xFF4A80C4),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              _buildButton(
                label: _isLoading ? 'Masuk...' : 'Masuk',
                onTap: _isLoading ? null : _onMasuk,
              ),

              const SizedBox(height: 24),

              _buildBottomText(
                normal: 'Belum punya akun? ',
                action: 'Daftar',
                onTap: _onDaftar,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1A1A2E),
        ),
      );

  Widget _buildTextField({
    Key? fieldKey,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        key: fieldKey,
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFFB0B0B0),
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _eyeIcon(
          {required bool obscure, required VoidCallback onTap}) =>
      IconButton(
        icon: Icon(
          obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: const Color(0xFF9E9E9E),
          size: 20,
        ),
        onPressed: onTap,
      );

  Widget _buildButton(
      {required String label, required VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const Key('loginButton'),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A80C4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomText({
    required String normal,
    required String action,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            normal,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Color(0xFF1A1A2E),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF4A80C4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}