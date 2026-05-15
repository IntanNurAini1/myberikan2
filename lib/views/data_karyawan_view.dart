import 'dart:convert';

import 'package:flutter/material.dart';

import '../../controllers/karyawan_controller.dart';
import '../../models/karyawan_model.dart';
import 'tambah_karyawan_view.dart';
import 'edit_karyawan_view.dart';

class DataKaryawanView extends StatefulWidget {
  const DataKaryawanView({super.key});

  @override
  State<DataKaryawanView> createState() => _DataKaryawanViewState();
}

class _DataKaryawanViewState extends State<DataKaryawanView> {
  final KaryawanController _controller = KaryawanController();
  final TextEditingController _searchController = TextEditingController();

  List<KaryawanModel> _allKaryawan = [];
  List<KaryawanModel> _filteredKaryawan = [];
  List<String> _divisiList = ['Semua Divisi'];
  String _selectedDivisi = 'Semua Divisi';
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final karyawanList = await _controller.getKaryawanList();
      final divisiList = await _controller.getDivisiList();
      setState(() {
        _allKaryawan = karyawanList;
        _divisiList = divisiList;
        _filteredKaryawan = karyawanList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    List<KaryawanModel> result = List.from(_allKaryawan);

    if (_selectedDivisi != 'Semua Divisi') {
      result = result.where((k) => k.divisi == _selectedDivisi).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((k) =>
              k.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              k.nip.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() => _filteredKaryawan = result);
  }

  void _onDivisiChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedDivisi = value;
      _applyFilter();
    });
  }

  void _navigateToTambah() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TambahKaryawanView()),
    );
    if (result == true) _loadData();
  }

  void _navigateToEdit(KaryawanModel karyawan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditKaryawanView(karyawan: karyawan),
      ),
    );
    if (result == true) _loadData();
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
          'Data Karyawan',
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

            // ── Search bar + tombol tambah ──
            Row(
              children: [
                Expanded(
                  child: Container(
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
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau NIP karyawan...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _navigateToTambah,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ],
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
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.grey),
                  style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontFamily: 'Poppins'),
                  items: _divisiList.map((divisi) {
                    return DropdownMenuItem<String>(
                      value: divisi,
                      child: Text(divisi),
                    );
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
                          color: Color(0xFF2196F3)))
                  : _filteredKaryawan.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data karyawan.',
                            style: TextStyle(
                                color: Colors.grey[500],
                                fontFamily: 'Poppins'),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.separated(
                            itemCount: _filteredKaryawan.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final karyawan = _filteredKaryawan[index];
                              return _KaryawanCard(
                                key: ValueKey(karyawan.nip), // ← FIX
                                karyawan: karyawan,
                                controller: _controller,
                                onTap: () => _navigateToEdit(karyawan),
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

// ── Card karyawan dengan email async ──

class _KaryawanCard extends StatefulWidget {
  final KaryawanModel karyawan;
  final KaryawanController controller;
  final VoidCallback onTap;

  const _KaryawanCard({
    super.key,
    required this.karyawan,
    required this.controller,
    required this.onTap,
  });

  @override
  State<_KaryawanCard> createState() => _KaryawanCardState();
}

class _KaryawanCardState extends State<_KaryawanCard> {
  String _email = '-';

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email =
        await widget.controller.getEmailByNip(widget.karyawan.nip);
    if (mounted) setState(() => _email = email);
  }

  @override
  Widget build(BuildContext context) {
    final karyawan = widget.karyawan;

    // Decode foto Base64
    Widget avatarChild;
    if (karyawan.fotoProfil.isNotEmpty) {
      try {
        final bytes = base64Decode(karyawan.fotoProfil);
        avatarChild = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        avatarChild = const _DefaultAvatar();
      }
    } else {
      avatarChild = const _DefaultAvatar();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    karyawan.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    karyawan.role,
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
                      const Icon(Icons.email_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.badge_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        karyawan.nip,
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
          ],
        ),
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