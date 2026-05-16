import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/karyawan_model.dart';

// ─────────────────────────────────────────────
// STATUS
// ─────────────────────────────────────────────

enum StatusHariIni { hadir, tidakHadir, sedangCuti }

class KaryawanStatus {
  final KaryawanModel karyawan;
  final String email;
  final StatusHariIni status;

  const KaryawanStatus({
    required this.karyawan,
    required this.email,
    required this.status,
  });
}

// ─────────────────────────────────────────────
// VIEW
// ─────────────────────────────────────────────

class InfoKaryawanView extends StatefulWidget {
  const InfoKaryawanView({super.key});

  @override
  State<InfoKaryawanView> createState() => _InfoKaryawanViewState();
}

class _InfoKaryawanViewState extends State<InfoKaryawanView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<KaryawanStatus> _allData = [];
  List<KaryawanStatus> _filteredData = [];
  List<String> _divisiList = ['Semua Divisi'];
  String _selectedDivisi = 'Semua Divisi';
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilter();
    });
  }

  // ─────────────────────────────────────────────
  // LOAD DATA
  // ─────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // 1. Semua karyawan
      final karyawanSnap = await _firestore.collection('karyawan').get();
      final karyawanList = karyawanSnap.docs.map((doc) {
        final data = doc.data();
        data['nip'] = doc.id;
        return KaryawanModel.fromMap(data);
      }).toList();

      // Divisi unik
      final divisiSet = karyawanList
          .map((k) => k.divisi)
          .where((d) => d.isNotEmpty)
          .toSet();
      _divisiList = ['Semua Divisi', ...divisiSet.toList()..sort()];

      // 2. Kehadiran hari ini
      final kehadiranSnap = await _firestore
          .collection('kehadiran')
          .where(
            'tanggal_kehadiran',
            isGreaterThanOrEqualTo: Timestamp.fromDate(today),
          )
          .where(
            'tanggal_kehadiran',
            isLessThanOrEqualTo: Timestamp.fromDate(todayEnd),
          )
          .get();

      final nipHadirSet = kehadiranSnap.docs
          .map((doc) => doc.data()['nip'] as String? ?? '')
          .where((nip) => nip.isNotEmpty)
          .toSet();

      // 3. Cuti aktif hari ini
      final cutiSnap = await _firestore
          .collection('pengajuan')
          .where('status_persetujuan', isEqualTo: 'Disetujui')
          .where(
            'tanggal_mulai',
            isLessThanOrEqualTo: Timestamp.fromDate(todayEnd),
          )
          .get();

      final nipCutiSet = cutiSnap.docs
          .where((doc) {
            final akhir = (doc.data()['tanggal_akhir'] as Timestamp).toDate();
            return !akhir.isBefore(today);
          })
          .map((doc) => doc.data()['nip_pemohon'] as String? ?? '')
          .where((nip) => nip.isNotEmpty)
          .toSet();

      // 4. Email dari users
      final usersSnap = await _firestore.collection('users').get();
      final Map<String, String> nipToEmail = {};
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final nip = data['nip'] as String? ?? '';
        final email = data['email_pemulihan'] as String? ?? '';
        if (nip.isNotEmpty) nipToEmail[nip] = email;
      }

      // 5. Gabungkan status
      final List<KaryawanStatus> result = karyawanList.map((k) {
        StatusHariIni status;
        if (nipCutiSet.contains(k.nip)) {
          status = StatusHariIni.sedangCuti;
        } else if (nipHadirSet.contains(k.nip)) {
          status = StatusHariIni.hadir;
        } else {
          status = StatusHariIni.tidakHadir;
        }
        return KaryawanStatus(
          karyawan: k,
          email: nipToEmail[k.nip] ?? '-',
          status: status,
        );
      }).toList();

      // Urutkan: HADIR → CUTI → TIDAK HADIR, lalu nama A-Z
      result.sort((a, b) {
        int order(StatusHariIni s) {
          switch (s) {
            case StatusHariIni.hadir:
              return 0;
            case StatusHariIni.sedangCuti:
              return 1;
            case StatusHariIni.tidakHadir:
              return 2;
          }
        }

        final cmp = order(a.status).compareTo(order(b.status));
        if (cmp != 0) return cmp;
        return a.karyawan.nama.compareTo(b.karyawan.nama);
      });

      setState(() {
        _allData = result;
        _applyFilter();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    List<KaryawanStatus> result = List.from(_allData);

    if (_selectedDivisi != 'Semua Divisi') {
      result = result
          .where((k) => k.karyawan.divisi == _selectedDivisi)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (k) =>
                k.karyawan.nama.toLowerCase().contains(q) ||
                k.karyawan.nip.toLowerCase().contains(q),
          )
          .toList();
    }

    setState(() => _filteredData = result);
  }

  void _onDivisiChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedDivisi = value;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F0F7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Info Karyawan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Search bar ──
            Container(
              height: 48,
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
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIP karyawan...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontFamily: 'Poppins',
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

            const SizedBox(height: 12),

            // ── Dropdown filter divisi ──
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDivisi,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  items: _divisiList.map((d) {
                    return DropdownMenuItem<String>(value: d, child: Text(d));
                  }).toList(),
                  onChanged: _onDivisiChanged,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── List karyawan ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2196F3),
                      ),
                    )
                  : _filteredData.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada data karyawan.',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        itemCount: _filteredData.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _InfoKaryawanCard(
                          key: ValueKey(_filteredData[index].karyawan.nip),
                          item: _filteredData[index],
                        ),
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
// CARD — sama persis dengan DataKaryawanView
// + badge status teks di pojok kanan atas
// ─────────────────────────────────────────────

class _InfoKaryawanCard extends StatelessWidget {
  final KaryawanStatus item;

  const _InfoKaryawanCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final k = item.karyawan;

    // Badge — teks saja, tanpa icon
    late String badgeLabel;
    late Color badgeBg;

    switch (item.status) {
      case StatusHariIni.hadir:
        badgeLabel = 'HADIR';
        badgeBg = const Color(0xFF4CAF50);
        break;
      case StatusHariIni.sedangCuti:
        badgeLabel = 'CUTI';
        badgeBg = const Color(0xFF2196F3);
        break;
      case StatusHariIni.tidakHadir:
        badgeLabel = 'TIDAK HADIR';
        badgeBg = const Color(0xFFE53935);
        break;
    }

    // Avatar
    Widget avatarChild;
    if (k.fotoProfil.isNotEmpty) {
      try {
        avatarChild = Image.memory(
          base64Decode(k.fotoProfil),
          fit: BoxFit.cover,
        );
      } catch (_) {
        avatarChild = const _DefaultAvatar();
      }
    } else {
      avatarChild = const _DefaultAvatar();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar bulat ──
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFD6E8F6),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarChild,
          ),

          const SizedBox(width: 12),

          // ── Info karyawan ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  k.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  k.role,
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      k.nip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Badge status — teks saja ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.person, size: 32, color: Color(0xFF5B9BD5));
  }
}