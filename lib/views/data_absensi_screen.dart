import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../controllers/kehadiran_controller.dart';

class DataAbsensiScreen extends StatefulWidget {
  const DataAbsensiScreen({super.key});

  @override
  State<DataAbsensiScreen> createState() => _DataAbsensiScreenState();
}

class _DataAbsensiScreenState extends State<DataAbsensiScreen> {
  final _controller = KehadiranController();
  final _searchController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<KehadiranDisplay> _allData = [];
  List<KehadiranDisplay> _filteredData = [];
  bool _isLoading = false;
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Load data dari Firestore ──

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _controller.getKehadiranByTanggal(_selectedDate);
      setState(() {
        _allData = data;
        _applySearch();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data kehadiran.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    _filteredData = _controller.filterByQuery(_allData, _searchQuery);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _applySearch();
    });
  }

  // ── Pilih tanggal via DatePicker ──

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A80C4),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _searchController.clear();
        _searchQuery = '';
      });
      _loadData();
    }
  }

  // ── Format helpers ──

  String get _formattedDate => DateFormat('dd/MM/yyyy').format(_selectedDate);

  String _formatWaktu(DateTime dt) => DateFormat('HH:mm').format(dt) + ' WIB';

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String _labelHari(DateTime dt) =>
      _isToday ? 'Hari ini' : DateFormat('dd MMM yyyy', 'id_ID').format(dt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEEF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAEEF4),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A2E),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Data Absensi',
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

          // ── Date filter chip ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildDateChip(),
          ),

          const SizedBox(height: 16),

          // ── List ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A80C4)),
                  )
                : _filteredData.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFF4A80C4),
                    onRefresh: _loadData,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      itemCount: _filteredData.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
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

  // ── Widgets ──

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFB0B0B0),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFB0B0B0),
                    size: 20,
                  ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formattedDate,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF4A80C4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(KehadiranDisplay item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDDE6F5),
              image: item.karyawan.fotoProfil.isNotEmpty
                  ? DecorationImage(
                      image: MemoryImage(
                        base64Decode(item.karyawan.fotoProfil),
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.karyawan.fotoProfil.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF4A80C4),
                    size: 28,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Nama + waktu
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
                const SizedBox(height: 2),
                Text(
                  '${_labelHari(item.kehadiran.tanggalKehadiran)} • ${_formatWaktu(item.kehadiran.tanggalKehadiran)}',
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
          _buildStatusBadge(item.kehadiran.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color textColor;
    String label;

    switch (status.toUpperCase()) {
      case 'HADIR':
        bg = const Color(0xFFE8F4FD);
        textColor = const Color(0xFF4A80C4);
        label = 'HADIR';
        break;
      case 'TERLAMBAT':
        bg = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE67E22);
        label = 'TERLAMBAT';
        break;
      case 'TIDAK HADIR':
      case 'ABSEN':
        bg = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFE53935);
        label = 'TIDAK HADIR';
        break;
      default:
        bg = const Color(0xFFF0F0F0);
        textColor = const Color(0xFF9E9E9E);
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada hasil untuk "$_searchQuery"'
                : 'Tidak ada data absensi\npada tanggal ini',
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
