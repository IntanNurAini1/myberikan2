import 'dart:convert';

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

  static bool _isUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  static Widget _buildImage({
    required String data,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget Function()? fallback,
  }) {
    if (data.isEmpty) return fallback?.call() ?? const SizedBox.shrink();

    if (_isUrl(data)) {
      return Image.network(
        data,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) =>
            fallback?.call() ??
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    try {
      final bytes = base64Decode(data);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) =>
            fallback?.call() ??
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } catch (_) {
      return fallback?.call() ??
          const Icon(Icons.broken_image, color: Colors.grey);
    }
  }

  static Widget _buildAvatar(KaryawanModel? k) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFFD6E8F6),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: k != null && k.fotoProfil.isNotEmpty
          ? _buildImage(
              data: k.fotoProfil,
              fit: BoxFit.cover,
              fallback: () => const _AvatarFallback(),
            )
          : const _AvatarFallback(),
    );
  }

  // ─────────────────────────────────────────────
  // ACTION: Verifikasi (Setujui)
  // ─────────────────────────────────────────────

  Future<void> _onVerifikasi() async {
    final confirm = await _showConfirmDialog(
      title: 'Setujui Cuti',
      message: 'Apakah kamu yakin ingin menyetujui pengajuan cuti ini?',
      confirmLabel: 'Setujui',
      confirmColor: const Color(0xFF2196F3),
    );
    if (confirm != true) return;

    final result = await widget.controller.setujuiCuti(
      docId: widget.docId,
      nipApprover: widget.nipApprover,
      pengajuan: widget.pengajuan,
      karyawan: widget.karyawan,
    );

    if (!mounted) return;

    if (result.sukses) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuti berhasil disetujui.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pengajuan Tidak Valid',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Text(
            result.pesanError ?? 'Gagal memproses. Coba lagi.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti'),
            ),
          ],
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
      message: 'Apakah kamu yakin ingin menolak pengajuan cuti ini?',
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
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _namaFile(String url) {
    if (url.isEmpty) return '-';
    if (_isUrl(url)) return url.split('/').last.split('?').first;
    return 'bukti_cuti.jpg';
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
          icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 28),
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
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAvatar(k),
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
                GestureDetector(
                  onTap: p.buktiLampiran.isNotEmpty
                      ? () => setState(() => _showBuktiPreview = true)
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: p.buktiLampiran.isNotEmpty
                              ? _buildImage(
                                  data: p.buktiLampiran,
                                  fit: BoxFit.cover,
                                  fallback: () => const Icon(
                                      Icons.insert_drive_file,
                                      color: Colors.grey),
                                )
                              : const Icon(Icons.insert_drive_file,
                                  color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _namaFile(p.buktiLampiran),
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.grey, size: 20),
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
                                'Setujui Cuti',
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

          // ── Overlay Preview Bukti ──
          if (_showBuktiPreview)
            _BuktiPreviewOverlay(
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
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        value,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Overlay Preview Bukti Cuti
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

  static bool _isUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  static Widget _buildImage({
    required String data,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget Function()? fallback,
  }) {
    if (data.isEmpty) return fallback?.call() ?? const SizedBox.shrink();

    if (_isUrl(data)) {
      return Image.network(
        data,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) =>
            fallback?.call() ??
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    try {
      final bytes = base64Decode(data);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) =>
            fallback?.call() ??
            const Icon(Icons.broken_image, color: Colors.grey),
      );
    } catch (_) {
      return fallback?.call() ??
          const Icon(Icons.broken_image, color: Colors.grey);
    }
  }

  static Widget _buildAvatar(KaryawanModel? k) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFFD6E8F6),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: k != null && k.fotoProfil.isNotEmpty
          ? _buildImage(
              data: k.fotoProfil,
              fit: BoxFit.cover,
              fallback: () => const _AvatarFallback(),
            )
          : const _AvatarFallback(),
    );
  }

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
                Row(
                  children: [
                    _buildAvatar(k),
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
                _readOnly(dateAwal),
                const SizedBox(height: 14),
                _label('Tanggal Akhir Cuti'),
                _readOnly(dateAkhir),
                const SizedBox(height: 14),
                _label('Alasan Cuti'),
                _readOnly(p.jenisPengajuan, minLines: 3),
                const SizedBox(height: 14),
                _label('Bukti Cuti'),
                const SizedBox(height: 8),
                if (p.buktiLampiran.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildImage(
                      data: p.buktiLampiran,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      fallback: () => Container(
                        height: 160,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('Tidak ada bukti lampiran',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: p.buktiLampiran.isNotEmpty
                            ? _buildImage(
                                data: p.buktiLampiran,
                                fit: BoxFit.cover,
                                fallback: () => const Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.grey),
                              )
                            : const Icon(Icons.insert_drive_file,
                                color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          namaFile,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          value,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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