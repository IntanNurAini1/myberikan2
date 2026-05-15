import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/karyawan_controller.dart';

class TambahKaryawanView extends StatefulWidget {
  const TambahKaryawanView({super.key});

  @override
  State<TambahKaryawanView> createState() => _TambahKaryawanViewState();
}

class _TambahKaryawanViewState extends State<TambahKaryawanView> {
  final KaryawanController _controller = KaryawanController();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _jabatanController = TextEditingController();
  final TextEditingController _jatahCutiController = TextEditingController();

  final List<String> _divisiOptions = [
    'Pilih Divisi',
    'Divisi Produksi',
    'Divisi Quality Control (QC)',
    'Divisi Riset & Pengembangan (R&D)',
    'Divisi Operasional',
    'Divisi Marketing & Penjualan',
    'Divisi Keuangan',
    'Divisi Human Resource (HR)',
    'Divisi Pengadaan & Supply Chain',
    'Divisi Teknologi/IT',
    'Divisi Pemberdayaan Nelayan & Kemitraan',
    'Divisi General Affairs',
  ];

  String _selectedDivisi = 'Pilih Divisi';
  bool _isLoading = false;

  // Foto
  File? _fotoFile;
  String? _fotoBase64;

  @override
  void dispose() {
    _namaController.dispose();
    _nipController.dispose();
    _jabatanController.dispose();
    _jatahCutiController.dispose();
    super.dispose();
  }

  // ── Pilih foto dari galeri atau kamera ──

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);

      setState(() {
        _fotoFile = file;
        _fotoBase64 = base64Str;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto.')),
        );
      }
    }
  }

  // ── Bottom sheet pilih sumber foto ──

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Foto',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF4A80C4),
              ),
              title: const Text(
                'Galeri',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF4A80C4),
              ),
              title: const Text(
                'Kamera',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Simpan karyawan ──

  Future<void> _tambahKaryawan() async {
    setState(() => _isLoading = true);
    try {
      await _controller.addKaryawan(
        nip: _nipController.text.trim(),
        nama: _namaController.text.trim(),
        jabatan: _jabatanController.text.trim(),
        divisi: _selectedDivisi,
        jatahCutiTahunan: int.tryParse(_jatahCutiController.text.trim()) ?? 0,
        fotoProfil: _fotoBase64 ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Karyawan berhasil ditambahkan.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on KaryawanException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Tambah Karyawan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Avatar bulat dengan tombol edit ──
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Foto atau placeholder — bulat
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6E8F6),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _fotoFile != null
                        ? Image.file(_fotoFile!, fit: BoxFit.cover)
                        : const Icon(
                            Icons.person,
                            size: 48,
                            color: Color(0xFF5B9BD5),
                          ),
                  ),

                  // Tombol edit
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Label kecil di bawah avatar
            const SizedBox(height: 6),
            Text(
              _fotoFile != null
                  ? 'Ketuk untuk ganti foto'
                  : 'Ketuk untuk tambah foto',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF9E9E9E),
              ),
            ),

            const SizedBox(height: 20),

            _buildLabel('Nama'),
            _buildTextField(
              controller: _namaController,
              hint: 'Masukan Nama',
            ),

            const SizedBox(height: 16),
            _buildLabel('ID Karyawan'),
            _buildTextField(
              controller: _nipController,
              hint: 'Masukan NIP Karyawan',
            ),

            const SizedBox(height: 16),
            _buildLabel('Jabatan'),
            _buildTextField(
              controller: _jabatanController,
              hint: 'Masukan Jabatan',
            ),

            const SizedBox(height: 16),
            _buildLabel('Divisi'),
            _buildDropdown(),

            const SizedBox(height: 16),
            _buildLabel('Jatah Cuti Tahunan'),
            _buildTextField(
              controller: _jatahCutiController,
              hint: 'Masukan Jatah Cuti Tahunan',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            _buildLabel('Gmail'),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '— diisi otomatis saat karyawan register —',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                  fontFamily: 'Poppins',
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _tambahKaryawan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Tambah Data Karyawan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDivisi,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontFamily: 'Poppins',
          ),
          items: _divisiOptions.map((d) {
            return DropdownMenuItem<String>(value: d, child: Text(d));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedDivisi = val);
          },
        ),
      ),
    );
  }
}