import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../controllers/absensi_controller.dart';
import '../models/kehadiran_model.dart';

class RiwayatAbsensiScreen extends StatefulWidget {
  const RiwayatAbsensiScreen({super.key});

  @override
  State<RiwayatAbsensiScreen> createState() => _RiwayatAbsensiScreenState();
}

class _RiwayatAbsensiScreenState extends State<RiwayatAbsensiScreen> {
  final AbsensiController _controller = AbsensiController();

  List<KehadiranModel> _riwayat = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final nip = await _controller.getNipCurrentUser();
      if (nip.isEmpty) throw Exception('NIP tidak ditemukan');

      final data = await _controller.getRiwayatAbsensi(nip: nip);
      setState(() => _riwayat = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat riwayat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEF3F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A2D45), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1A2D45),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B7FD4)))
          : _riwayat.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy_rounded,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada riwayat absensi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF7A8FA6),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF2B7FD4),
                  onRefresh: _loadRiwayat,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _riwayat.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _buildCard(_riwayat[index]),
                  ),
                ),
    );
  }

  Widget _buildCard(KehadiranModel item) {
    return Container(
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
          // Icon
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

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.status == 'HADIR' || item.status == 'TERLAMBAT'
                      ? 'Absensi Berhasil'
                      : 'Tidak Absen',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2D45),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.status == 'TIDAK HADIR'
                      ? _formatTanggal(item.tanggalKehadiran)
                      : '${_formatTanggal(item.tanggalKehadiran)} • ${_formatWaktu(item.tanggalKehadiran)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF2B7FD4),
                  ),
                ),
              ],
            ),
          ),

          // Badge status
          _buildBadge(item.status),
        ],
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color bg;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'HADIR':
        bg = const Color(0xFFE8F4FD);
        textColor = const Color(0xFF2B7FD4);
        break;
      case 'TERLAMBAT':
        bg = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE67E22);
        break;
      case 'TIDAK HADIR':
        bg = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFE53935);
        break;
      default:
        bg = const Color(0xFFF0F0F0);
        textColor = const Color(0xFF9E9E9E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}