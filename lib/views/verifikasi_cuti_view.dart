// ================================
// verifikasi_cuti_view.dart  ← Halaman 1: List pengajuan
// ================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/verifikasi_cuti_controller.dart';
import '../../models/karyawan_model.dart';
import '../../models/pengajuan_model.dart';
import 'detail_verifikasi_cuti_view.dart';

class VerifikasiCutiView extends StatefulWidget {
  const VerifikasiCutiView({super.key});

  @override
  State<VerifikasiCutiView> createState() => _VerifikasiCutiViewState();
}


class _VerifikasiCutiViewState extends State<VerifikasiCutiView> {
  final VerifikasiCutiController _controller = VerifikasiCutiController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.init();
    _controller.addListener(_refresh);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _controller.filterByNama(_searchQuery);

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // ── Search bar ──
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama karyawan...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── List ──
            Expanded(
              child: _controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2196F3),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada pengajuan yang menunggu.',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _controller.fetchPengajuanMenunggu,
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final pengajuan =
                                  item['pengajuan'] as PengajuanModel;
                              final karyawan =
                                  item['karyawan'] as KaryawanModel?;
                              final docId = item['docId'] as String;
                              final nipApprover =
                                  item['nipApprover'] as String;

                              return _PengajuanListTile(
                                pengajuan: pengajuan,
                                karyawan: karyawan,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetailVerifikasiCutiView(
                                        pengajuan: pengajuan,
                                        karyawan: karyawan,
                                        docId: docId,
                                        nipApprover: nipApprover,
                                        controller: _controller,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    await _controller.fetchPengajuanMenunggu();
                                  }
                                },
                              );
                            },
                          ),
                        ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tile item list
// ─────────────────────────────────────────────

class _PengajuanListTile extends StatelessWidget {
  final PengajuanModel pengajuan;
  final KaryawanModel? karyawan;
  final VoidCallback onTap;

  const _PengajuanListTile({
    required this.pengajuan,
    required this.karyawan,
    required this.onTap,
  });

  static Widget _buildAvatar(KaryawanModel? k) {
    if (k != null && k.fotoProfil.isNotEmpty) {
      try {
        final bytes = base64Decode(k.fotoProfil);
        return Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFFD6E8F6),
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(bytes, fit: BoxFit.cover),
        );
      } catch (_) {}
    }
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFFD6E8F6),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 26, color: Color(0xFF5B9BD5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(pengajuan.tanggalPengajuan);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            _buildAvatar(karyawan),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    karyawan?.nama ?? pengajuan.nipPemohon,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    karyawan?.role ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: Color(0xFF2196F3)),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Badge status + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Menunggu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE67E22),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}