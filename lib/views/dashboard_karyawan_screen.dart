import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/absensi_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/kehadiran_model.dart';
import '../models/karyawan_model.dart';
import 'riwayat_absensi_screen.dart';
import 'ajukan_cuti_screen.dart';
import 'data_karyawan_view.dart';
import 'login_screen.dart';

class DashboardKaryawanScreen extends StatefulWidget {
  const DashboardKaryawanScreen({super.key});

  @override
  State<DashboardKaryawanScreen> createState() =>
      _DashboardKaryawanScreenState();
}

class _DashboardKaryawanScreenState extends State<DashboardKaryawanScreen> {
  final AbsensiController _absensiController = AbsensiController();
  final AuthController _authController = AuthController();

  KaryawanModel? _karyawan;
  List<KehadiranModel> _riwayat = [];
  bool _isLoadingProfil = true;
  bool _isLoadingRiwayat = true;
  bool _isAbsenLoading = false;
  bool _sudahAbsen = false;

  @override
  void initState() {
    super.initState();
    _loadProfil();
    _loadRiwayat();
  }

  Future<void> _loadProfil() async {
    try {
      final data = await _absensiController.getProfilCurrentUser();
      if (data != null && mounted) {
        setState(() => _karyawan = KaryawanModel.fromMap(data));
      }
      final nip = await _absensiController.getNipCurrentUser();
      if (nip.isNotEmpty) {
        final sudah = await _absensiController.sudahAbsenHariIni(nip);
        if (mounted) setState(() => _sudahAbsen = sudah);
      }
    } catch (e) {
      debugPrint('Error load profil: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfil = false);
    }
  }

  Future<void> _loadRiwayat() async {
    try {
      final nip = await _absensiController.getNipCurrentUser();
      if (nip.isEmpty) return;
      final data = await _absensiController.getRiwayatAbsensi(
          nip: nip, limit: 5);
      if (mounted) setState(() => _riwayat = data);
    } catch (e) {
      debugPrint('Error load riwayat: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRiwayat = false);
    }
  }

  Future<void> _onAbsenSekarang() async {
    setState(() => _isAbsenLoading = true);
    try {
      final kehadiran = await _absensiController.absenSekarang();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Absensi berhasil! Status: ${kehadiran.status}'),
        backgroundColor: const Color(0xFF2E7D32),
      ));
      setState(() => _sudahAbsen = true);
      _loadRiwayat();
    } on AbsensiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.redAccent,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: $e'),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _isAbsenLoading = false);
    }
  }

  // ── Logout ──

  void _showLogoutMenu(BuildContext btnContext) {
    final RenderBox button = btnContext.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(btnContext)
        .overlay!
        .context
        .findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: btnContext,
      position: position,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      items: [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout_rounded,
                  color: Color(0xFFEF5350), size: 20),
              SizedBox(width: 10),
              Text(
                'Keluar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFFEF5350),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'logout') _konfirmasiLogout();
    });
  }

  Future<void> _konfirmasiLogout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar Aplikasi?',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16),
        ),
        content: const Text(
          'Kamu akan keluar dari akun ini.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal',
                style: TextStyle(
                    fontFamily: 'Poppins', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFFEF5350),
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      await _authController.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal logout: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // ── Format helper ──

  String _formatTanggal(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Hari ini';
    if (date == yesterday) return 'Kemarin';
    return DateFormat('d MMM', 'id_ID').format(dt);
  }

  String _formatWaktu(DateTime dt) =>
      DateFormat('HH:mm').format(dt) + ' WIB';

  bool get _canAbsen {
    if (_sudahAbsen) return false;
    if (_isAbsenLoading) return false;
    return AbsensiController.getStatusByJam(DateTime.now()) != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('dashboardKaryawan'),
      backgroundColor: const Color(0xFFEEF3F8),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2B7FD4),
          onRefresh: () async {
            await _loadProfil();
            await _loadRiwayat();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildProfileCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Fitur Aplikasi'),
                const SizedBox(height: 12),
                _buildFiturAplikasi(context),
                const SizedBox(height: 24),
                _buildRiwayatHeader(context),
                const SizedBox(height: 12),
                _buildRiwayatList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader() {
    Widget avatar;
    if (_karyawan != null && _karyawan!.fotoProfil.isNotEmpty) {
      try {
        final bytes = base64Decode(_karyawan!.fotoProfil);
        avatar = CircleAvatar(
            radius: 24, backgroundImage: MemoryImage(bytes));
      } catch (_) {
        avatar = _defaultAvatar();
      }
    } else {
      avatar = _defaultAvatar();
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selamat datang!',
                style:
                    TextStyle(fontSize: 12, color: Color(0xFF7A8FA6))),
            Text(
              _isLoadingProfil ? '...' : (_karyawan?.nama ?? '-'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2D45),
              ),
            ),
          ],
        ),
        const Spacer(),
        Builder(
          builder: (btnContext) => IconButton(
            onPressed: () => _showLogoutMenu(btnContext),
            icon: const Icon(Icons.menu, color: Color(0xFF2B7FD4)),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFD6E8F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child:
          const Icon(Icons.person, color: Color(0xFF2B7FD4), size: 30),
    );
  }

  // ── Profile card ──

  Widget _buildProfileCard() {
    final statusAbsen = AbsensiController.getStatusByJam(DateTime.now());
    final labelTombol = _sudahAbsen
        ? 'Sudah Absen Hari Ini'
        : _absensiController.getLabelTombol();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _karyawan?.role ?? 'Karyawan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2D45),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AKTIF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'NIP: ${_karyawan?.nip ?? '-'}',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF7A8FA6)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: Color(0xFF2B7FD4)),
                    SizedBox(width: 6),
                    Text(
                      'Shift Pagi • 08:00 - 17:00',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2B7FD4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'DIVISI',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7A8FA6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _karyawan?.divisi ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B7FD4),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _canAbsen ? _onAbsenSekarang : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _sudahAbsen
                    ? const Color(0xFF4CAF50)
                    : statusAbsen == null
                        ? Colors.grey.shade400
                        : const Color(0xFF2B7FD4),
                foregroundColor: Colors.white,
                disabledBackgroundColor: _sudahAbsen
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade400,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isAbsenLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(labelTombol,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A2D45),
      ),
    );
  }

  // ── Fitur Aplikasi — 2 fitur pakai Row agar lebar sama dengan card lain ──

  Widget _buildFiturAplikasi(BuildContext context) {
    final List<_FiturItem> features = [
      _FiturItem(
        icon: Icons.calendar_today_outlined,
        label: 'Pengajuan\nCuti',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AjukanCutiScreen())),
      ),
      _FiturItem(
        icon: Icons.people_outline,
        label: 'Data\nKaryawan',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DataKaryawanView())),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: features.map((f) {
          return InkWell(
            onTap: f.onTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(f.icon,
                        color: const Color(0xFF2B7FD4), size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    f.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1A2D45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Riwayat Header ──

  Widget _buildRiwayatHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Riwayat Absensi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A2D45),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const RiwayatAbsensiScreen()),
          ),
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF2B7FD4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Riwayat List ──

  Widget _buildRiwayatList() {
    if (_isLoadingRiwayat) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child:
              CircularProgressIndicator(color: Color(0xFF2B7FD4)),
        ),
      );
    }

    if (_riwayat.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Belum ada riwayat absensi',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF7A8FA6)),
          ),
        ),
      );
    }

    return Column(
      children: _riwayat.map((item) => _buildAbsensiCard(item)).toList(),
    );
  }

  Widget _buildAbsensiCard(KehadiranModel item) {
    Color badgeBg;
    Color badgeText;
    switch (item.status.toUpperCase()) {
      case 'HADIR':
        badgeBg = const Color(0xFFE8F4FD);
        badgeText = const Color(0xFF2B7FD4);
        break;
      case 'TERLAMBAT':
        badgeBg = const Color(0xFFFFF3E0);
        badgeText = const Color(0xFFE67E22);
        break;
      default:
        badgeBg = const Color(0xFFFFEBEE);
        badgeText = const Color(0xFFE53935);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.login_rounded,
                color: Color(0xFF2B7FD4), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Absensi Berhasil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2D45),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatTanggal(item.tanggalKehadiran)} • ${_formatWaktu(item.tanggalKehadiran)}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF2B7FD4)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.status.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: badgeText,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiturItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FiturItem(
      {required this.icon,
      required this.label,
      required this.onTap});
}