import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/karyawan_model.dart';
import '../models/pengajuan_model.dart';

// ─────────────────────────────────────────────
// MODEL GABUNGAN
// ─────────────────────────────────────────────

class CutiDisplay {
  final PengajuanModel pengajuan;
  final KaryawanModel karyawan;

  const CutiDisplay({required this.pengajuan, required this.karyawan});
}

// ─────────────────────────────────────────────
// VIEW
// ─────────────────────────────────────────────

class DataCutiScreen extends StatefulWidget {
  const DataCutiScreen({super.key});

  @override
  State<DataCutiScreen> createState() => _DataCutiScreenState();
}

class _DataCutiScreenState extends State<DataCutiScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  // Filter bulan & tahun → default bulan ini
  late int _selectedMonth;
  late int _selectedYear;

  List<CutiDisplay> _allData = [];
  List<CutiDisplay> _filteredData = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Cache karyawan agar tidak fetch berulang
  final Map<String, KaryawanModel> _karyawanCache = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // LOAD DATA
  // Ambil pengajuan status "Disetujui" yang tanggal
  // mulai atau akhirnya berada di bulan & tahun terpilih
  // ─────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Rentang awal & akhir bulan terpilih
      final startOfMonth =
          DateTime(_selectedYear, _selectedMonth, 1, 0, 0, 0);
      final endOfMonth =
          DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

      // Query: status Disetujui + tanggal_mulai dalam bulan ini
      // (pengajuan yang mulainya di bulan ini)
      final snapshotMulai = await _firestore
          .collection('pengajuan')
          .where('status_persetujuan', isEqualTo: 'Disetujui')
          .where('tanggal_mulai',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('tanggal_mulai',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      // Query: status Disetujui + tanggal_akhir dalam bulan ini
      // (pengajuan yang berakhir di bulan ini tapi mulai sebelumnya)
      final snapshotAkhir = await _firestore
          .collection('pengajuan')
          .where('status_persetujuan', isEqualTo: 'Disetujui')
          .where('tanggal_akhir',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('tanggal_akhir',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      // Gabung & deduplikasi berdasarkan id_pengajuan
      final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> docsMap =
          {};
      for (final doc in [
        ...snapshotMulai.docs,
        ...snapshotAkhir.docs
      ]) {
        docsMap[doc.id] = doc;
      }

      // Fetch karyawan & build list
      final List<CutiDisplay> result = [];
      for (final doc in docsMap.values) {
        final pengajuan = PengajuanModel.fromMap(doc.data());
        final nip = pengajuan.nipPemohon;

        KaryawanModel? karyawan = _karyawanCache[nip];
        if (karyawan == null && nip.isNotEmpty) {
          final karyawanDoc =
              await _firestore.collection('karyawan').doc(nip).get();
          if (karyawanDoc.exists) {
            final data = karyawanDoc.data()!;
            data['nip'] = karyawanDoc.id;
            karyawan = KaryawanModel.fromMap(data);
            _karyawanCache[nip] = karyawan;
          }
        }

        if (karyawan != null) {
          result.add(CutiDisplay(pengajuan: pengajuan, karyawan: karyawan));
        }
      }

      // Urutkan berdasarkan tanggal mulai
      result.sort((a, b) =>
          a.pengajuan.tanggalMulai.compareTo(b.pengajuan.tanggalMulai));

      setState(() {
        _allData = result;
        _applySearch();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data cuti: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredData = List.from(_allData);
      return;
    }
    final q = _searchQuery.trim().toLowerCase();
    _filteredData = _allData.where((item) {
      return item.karyawan.nama.toLowerCase().contains(q) ||
          item.karyawan.nip.toLowerCase().contains(q);
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applySearch();
    });
  }

  // ─────────────────────────────────────────────
  // PILIH BULAN & TAHUN via dialog
  // ─────────────────────────────────────────────

  Future<void> _pickBulanTahun() async {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;

    final List<String> namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - 4 + i);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Pilih Bulan & Tahun',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pilih tahun
              DropdownButtonFormField<int>(
                value: tempYear,
                decoration: InputDecoration(
                  labelText: 'Tahun',
                  labelStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: years
                    .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text('$y',
                            style: const TextStyle(fontFamily: 'Poppins'))))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => tempYear = v ?? tempYear),
              ),
              const SizedBox(height: 12),
              // Pilih bulan
              DropdownButtonFormField<int>(
                value: tempMonth,
                decoration: InputDecoration(
                  labelText: 'Bulan',
                  labelStyle:
                      const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(namaBulan[i],
                        style: const TextStyle(fontFamily: 'Poppins')),
                  ),
                ),
                onChanged: (v) =>
                    setDialogState(() => tempMonth = v ?? tempMonth),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal',
                  style: TextStyle(
                      fontFamily: 'Poppins', color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('ok'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A80C4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Terapkan',
                  style: TextStyle(
                      fontFamily: 'Poppins', color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((val) {
      if (val == 'ok') {
        setState(() {
          _selectedMonth = tempMonth;
          _selectedYear = tempYear;
          _searchController.clear();
          _searchQuery = '';
        });
        _loadData();
      }
    });
  }

  // ─────────────────────────────────────────────
  // STATUS CUTI
  // ─────────────────────────────────────────────

  /// Tentukan status tampil: TERJADWAL atau SEDANG BERLANGSUNG
  String _statusCuti(PengajuanModel p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mulai =
        DateTime(p.tanggalMulai.year, p.tanggalMulai.month, p.tanggalMulai.day);
    final akhir =
        DateTime(p.tanggalAkhir.year, p.tanggalAkhir.month, p.tanggalAkhir.day);

    if (today.isBefore(mulai)) return 'TERJADWAL';
    if (today.isAfter(akhir)) return 'SELESAI';
    return 'SEDANG BERLANGSUNG';
  }

  // ─────────────────────────────────────────────
  // FORMAT
  // ─────────────────────────────────────────────

  String _formatTanggal(DateTime dt) =>
      DateFormat('d MMM yyyy', 'id_ID').format(dt);

  String get _labelBulanTahun {
    final namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${namaBulan[_selectedMonth - 1]}/$_selectedYear';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEEF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAEEF4),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Data Cuti',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSearchBar(),
          ),

          const SizedBox(height: 12),

          // ── Filter bulan/tahun chip ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildBulanChip(),
          ),

          const SizedBox(height: 16),

          // ── List ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4A80C4)))
                : _filteredData.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: const Color(0xFF4A80C4),
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          itemCount: _filteredData.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) =>
                              _buildCard(_filteredData[index]),
                        ),
                      ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          hintText: 'Cari NIP atau nama karyawan....',
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFFB0B0B0),
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFFB0B0B0), size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Color(0xFFB0B0B0), size: 20),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBulanChip() {
    return GestureDetector(
      onTap: _pickBulanTahun,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _labelBulanTahun,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_month_rounded,
                color: Color(0xFF4A80C4), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(CutiDisplay item) {
    final status = _statusCuti(item.pengajuan);

    // Badge warna
    Color badgeBg;
    Color badgeText;
    switch (status) {
      case 'SEDANG BERLANGSUNG':
        badgeBg = const Color(0xFFE3F2FD);
        badgeText = const Color(0xFF1565C0);
        break;
      case 'SELESAI':
        badgeBg = const Color(0xFFF0F0F0);
        badgeText = const Color(0xFF9E9E9E);
        break;
      default: // TERJADWAL
        badgeBg = const Color(0xFFFFF8E1);
        badgeText = const Color(0xFFF57F17);
    }

    // Avatar
    Widget avatarChild;
    if (item.karyawan.fotoProfil.isNotEmpty) {
      try {
        avatarChild = Image.memory(
          base64Decode(item.karyawan.fotoProfil),
          fit: BoxFit.cover,
        );
      } catch (_) {
        avatarChild = const Icon(Icons.person_rounded,
            color: Color(0xFF4A80C4), size: 28);
      }
    } else {
      avatarChild = const Icon(Icons.person_rounded,
          color: Color(0xFF4A80C4), size: 28);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar bulat
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFDDE6F5),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarChild,
          ),

          const SizedBox(width: 12),

          // Info karyawan + tanggal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.karyawan.nama,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatTanggal(item.pengajuan.tanggalMulai)} - ${_formatTanggal(item.pengajuan.tanggalAkhir)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF4A80C4),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Badge status
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: badgeText,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada hasil untuk "$_searchQuery"'
                : 'Tidak ada data cuti\npada bulan ini',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFFB0B0B0),
            ),
          ),
        ],
      ),
    );
  }
}