// ================================
// detail_verifikasi_cuti_view.dart  ← Halaman 2: Detail + Halaman 3: Preview Bukti
// ================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/verifikasi_cuti_controller.dart';
import '../../models/karyawan_model.dart';
import '../../models/pengajuan_model.dart';

class DetailVerifikasiCutiView extends StatefulWidget {
  final PengajuanModel pengajuan;
  final KaryawanModel? karyawan;
  final String docId;
  final String nipApprover;
  final VerifikasiCutiController controller;

  const DetailVerifikasiCutiView({
    super.key,
    required this.pengajuan,
    required this.karyawan,
    required this.docId,
    required this.nipApprover,
    required this.controller,
  });

  @override
  State<DetailVerifikasiCutiView> createState() =>
      _DetailVerifikasiCutiViewState();
}

class _DetailVerifikasiCutiViewState
    extends State<DetailVerifikasiCutiView> {
  bool _showBuktiPreview = false;

  // ─────────────────────────────────────────────
  // ACTION: Verifikasi (Setujui)
  // ─────────────────────────────────────────────

  Future<void> _onVerifikasi() async {
    final confirm = await _showConfirmDialog(
      title: 'Setujui Cuti',
      message:
          'Apakah kamu yakin ingin menyetujui pengajuan cuti ini?',
      confirmLabel: 'Setujui',
      confirmColor: const Color(0xFF2196F3),
    );
    if (confirm != true) return;

    final ok = await widget.controller.setujuiCuti(
      docId: widget.docId,
      nipApprover: widget.nipApprover,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuti berhasil disetujui.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memproses. Coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // ACTION: Tolak
  // ─────────────────────────────────────────────

  Future<void> _onTolak() async {
    final confirm = await _showConfirmDialog(
      title: 'Tolak Cuti',
      message:
          'Apakah kamu yakin ingin menolak pengajuan cuti ini?',
      confirmLabel: 'Tolak',
      confirmColor: Colors.redAccent,
    );
    if (confirm != true) return;

    final ok = await widget.controller.tolakCuti(
      docId: widget.docId,
      nipApprover: widget.nipApprover,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuti berhasil ditolak.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memproses. Coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Nama file dari URL/path
  // ─────────────────────────────────────────────

  String _namaFile(String url) {
    if (url.isEmpty) return '-';
    return url.split('/').last.split('?').first;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pengajuan;
    final k = widget.karyawan;
    final dateAwal = DateFormat('dd/MM/yyyy').format(p.tanggalMulai);
    final dateAkhir = DateFormat('dd/MM/yyyy').format(p.tanggalAkhir);
    final isSubmitting = widget.controller.isSubmitting;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEF3F8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: Colors.black87, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verifikasi Cuti',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ── Konten utama ──
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Header: Avatar + nama
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6E8F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: k != null && k.fotoProfil.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                k.fotoProfil,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _AvatarFallback(),
                              ),
                            )
                          : const _AvatarFallback(),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      k?.nama ?? p.nipPemohon,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLabel('ID Karyawan'),
                _buildReadOnly(p.nipPemohon),
                const SizedBox(height: 14),
                _buildLabel('Jabatan'),
                _buildReadOnly(k?.role ?? '-'),
                const SizedBox(height: 14),
                _buildLabel('Tanggal Awal Cuti'),
                _buildReadOnly(dateAwal),
                const SizedBox(height: 14),
                _buildLabel('Tanggal Akhir Cuti'),
                _buildReadOnly(dateAkhir),
                const SizedBox(height: 14),
                _buildLabel('Alasan Cuti'),
                _buildReadOnly(p.jenisPengajuan, minLines: 4),
                const SizedBox(height: 14),
                _buildLabel('Bukti Cuti'),
                const SizedBox(height: 6),
                // Bukti lampiran — bisa dipencet
                GestureDetector(
                  onTap: p.buktiLampiran.isNotEmpty
                      ? () => setState(() => _showBuktiPreview = true)
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFDDDDDD),
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: p.buktiLampiran.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    p.buktiLampiran,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.insert_drive_file,
                                            color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.insert_drive_file,
                                  color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _namaFile(p.buktiLampiran),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tombol bawah ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFFEEF3F8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Tombol Tolak Cuti
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _onTolak,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Tolak Cuti',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Verifikasi Cuti (Setujui)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _onVerifikasi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Verifikasi Cuti',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Overlay Preview Bukti (Halaman 3) ──
          if (_showBuktiPreview) _BuktiPreviewOverlay(
            pengajuan: widget.pengajuan,
            karyawan: widget.karyawan,
            onClose: () => setState(() => _showBuktiPreview = false),
            onTolak: () {
              setState(() => _showBuktiPreview = false);
              _onTolak();
            },
            onVerifikasi: () {
              setState(() => _showBuktiPreview = false);
              _onVerifikasi();
            },
            isSubmitting: isSubmitting,
            namaFile: _namaFile(widget.pengajuan.buktiLampiran),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildReadOnly(String value, {int minLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minLines > 1 ? 90 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Overlay "Veri Img" — preview bukti cuti (Halaman 3)
// ─────────────────────────────────────────────

class _BuktiPreviewOverlay extends StatelessWidget {
  final PengajuanModel pengajuan;
  final KaryawanModel? karyawan;
  final VoidCallback onClose;
  final VoidCallback onTolak;
  final VoidCallback onVerifikasi;
  final bool isSubmitting;
  final String namaFile;

  const _BuktiPreviewOverlay({
    required this.pengajuan,
    required this.karyawan,
    required this.onClose,
    required this.onTolak,
    required this.onVerifikasi,
    required this.isSubmitting,
    required this.namaFile,
  });

  @override
  Widget build(BuildContext context) {
    final p = pengajuan;
    final k = karyawan;
    final dateAwal = DateFormat('dd/MM/yyyy').format(p.tanggalMulai);
    final dateAkhir = DateFormat('dd/MM/yyyy').format(p.tanggalAkhir);

    return Container(
      color: const Color(0xFFEEF3F8),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + nama + tombol close
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6E8F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: k != null && k.fotoProfil.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                k.fotoProfil,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _AvatarFallback(),
                              ),
                            )
                          : const _AvatarFallback(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        k?.nama ?? p.nipPemohon,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _label('ID Karyawan'),
                _readOnly(p.nipPemohon),
                const SizedBox(height: 14),
                _label('Jabatan'),
                _readOnly(k?.role ?? '-'),
                const SizedBox(height: 14),
                _label('Tanggal Awal Cuti'),
                // Tampilkan preview gambar di sini seperti di gambar
                if (p.buktiLampiran.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      p.buktiLampiran,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _readOnly(p.jenisPengajuan, minLines: 3),
                const SizedBox(height: 14),
                _label('Bukti Cuti'),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: p.buktiLampiran.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  p.buktiLampiran,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.insert_drive_file,
                                      color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.insert_drive_file,
                                color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          namaFile,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tombol bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: const Color(0xFFEEF3F8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : onTolak,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Tolak Cuti',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : onVerifikasi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Terima Cuti',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
        ),
      );

  Widget _readOnly(String value, {int minLines = 1}) => Container(
        margin: const EdgeInsets.only(top: 6),
        width: double.infinity,
        constraints: BoxConstraints(minHeight: minLines > 1 ? 80 : 0),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      );
}

// ─────────────────────────────────────────────
// Avatar fallback
// ─────────────────────────────────────────────

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person, size: 32, color: Color(0xFF5B9BD5));
  }
}