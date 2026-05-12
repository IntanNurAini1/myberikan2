import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _idKaryawanController = TextEditingController();
  final TextEditingController _googleController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _idKaryawanController.dispose();
    _googleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onDaftar() {
    final idKaryawan = _idKaryawanController.text.trim();
    final google = _googleController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (idKaryawan.isEmpty ||
        google.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field wajib diisi.')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kata sandi tidak cocok.')));
      return;
    }

    // TODO: tambahkan logika registrasi
  }

  void _onMasuk() {
    Navigator.of(context).pop();
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
              const SizedBox(height: 48),

              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                ),
              ),

              const SizedBox(height: 36),

              // ID Karyawan
              _buildLabel('ID Karyawan'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _idKaryawanController,
                hint: 'ID karyawan',
                obscure: false,
              ),

              const SizedBox(height: 20),

              // Akun Google
              _buildLabel('Akun Google'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _googleController,
                hint: 'Masukan akun google anda',
                obscure: false,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // Nama Pengguna
              _buildLabel('Nama Pengguna'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _usernameController,
                hint: 'Masukkan  Nama Pengguna',
                obscure: false,
              ),

              const SizedBox(height: 20),

              // Kata Sandi
              _buildLabel('Kata Sandi'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: 'Masukkan kata sandi',
                obscure: _obscurePassword,
                suffixIcon: _eyeIcon(
                  obscure: _obscurePassword,
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 20),

              // Konfirmasi Kata Sandi
              _buildLabel('Konfirmasi Kata Sandi'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Masukkan kata sandi',
                obscure: _obscureConfirmPassword,
                suffixIcon: _eyeIcon(
                  obscure: _obscureConfirmPassword,
                  onTap: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Tombol Daftar
              _buildButton(label: 'Daftar', onTap: _onDaftar),

              const SizedBox(height: 24),

              // Sudah punya akun?
              _buildBottomText(
                normal: 'Sudah punya akun? ',
                action: 'Masuk',
                onTap: _onMasuk,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
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

  Widget _eyeIcon({required bool obscure, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: const Color(0xFF9E9E9E),
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
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
