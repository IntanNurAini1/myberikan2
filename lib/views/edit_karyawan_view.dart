import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/karyawan_controller.dart';
import '../../models/karyawan_model.dart';

class EditKaryawanView extends StatefulWidget {
  final KaryawanModel karyawan;

  const EditKaryawanView({
    super.key,
    required this.karyawan,
  });

  @override
  State<EditKaryawanView> createState() => _EditKaryawanViewState();
}

class _EditKaryawanViewState extends State<EditKaryawanView> {
  final KaryawanController _controller = KaryawanController();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _namaController;
  late final TextEditingController _jabatanController;
  late final TextEditingController _jatahCutiController;

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

  late String _selectedDivisi;
  bool _isLoading = false;
  String _email = '-';

  File? _fotoFile;
  String? _fotoBase64Baru;

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(text: widget.karyawan.nama);
    _jabatanController = TextEditingController(text: widget.karyawan.role);
    _jatahCutiController = TextEditingController(
      text: widget.karyawan.jatahCutiTahunan.toString(),
    );

    if (_divisiOptions.contains(widget.karyawan.divisi)) {
      _selectedDivisi = widget.karyawan.divisi;
    } else {
      _selectedDivisi = _divisiOptions.first;
      if (widget.karyawan.divisi.isNotEmpty) {
        _divisiOptions.insert(0, widget.karyawan.divisi);
        _selectedDivisi = widget.karyawan.divisi;
      }
    }

    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await _controller.getEmailByNip(widget.karyawan.nip);
    if (mounted) setState(() => _email = email);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _jabatanController.dispose();
    _jatahCutiController.dispose();
    super.dispose();
  }

  // ── Pilih foto baru ──

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
      setState(() {
        _fotoFile = file;
        _fotoBase64Baru = base64Encode(bytes);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto.')),
        );
      }
    }
  }

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
              'Ganti Foto',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: Color(0xFF4A80C4)),
              title: const Text('Galeri',
                  style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: Color(0xFF4A80C4)),
              title: const Text('Kamera',
                  style: TextStyle(fontFamily: 'Poppins')),
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

  // ── Simpan perubahan ──

  Future<void> _simpanPerubahan() async {
    setState(() => _isLoading = true);
    try {
      await _controller.updateKaryawan(
        nip: widget.karyawan.nip,
        nama: _namaController.text.trim(),
        jabatan: _jabatanController.text.trim(),
        divisi: _selectedDivisi,
        jatahCutiTahunan:
            int.tryParse(_jatahCutiController.text.trim()) ?? 0,
        fotoProfil: _fotoBase64Baru,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data karyawan berhasil diperbarui.'),
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

  // ── Konfirmasi & Hapus karyawan ──

  Future<void> _konfirmasiHapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Karyawan?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Data "${widget.karyawan.nama}" akan dihapus permanen dan tidak dapat dikembalikan.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Batal',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _isLoading = true);
    try {
      await _controller.deleteKaryawan(widget.karyawan.nip);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Karyawan berhasil dihapus.'),
            backgroundColor: Color(0xFFEF5350),
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

  // ── Tampilan avatar ──

  Widget _buildAvatar() {
    ImageProvider? imageProvider;

    if (_fotoFile != null) {
      imageProvider = FileImage(_fotoFile!);
    } else if (widget.karyawan.fotoProfil.isNotEmpty) {
      try {
        imageProvider =
            MemoryImage(base64Decode(widget.karyawan.fotoProfil));
      } catch (_) {
        imageProvider = null;
      }
    }

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 90,
            height: 90,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Color(0xFFD6E8F6),
              shape: BoxShape.circle,
            ),
            child: imageProvider != null
                ? Image(image: imageProvider, fit: BoxFit.cover)
                : const Icon(Icons.person, size: 48,
                    color: Color(0xFF5B9BD5)),
          ),
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
              child: const Icon(Icons.edit, size: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
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
          'Edit Data Karyawan',
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

            // Avatar
            _buildAvatar(),
            const SizedBox(height: 6),
            Text(
              _fotoFile != null ? 'Ketuk untuk ganti foto' : 'Ketuk untuk ubah foto',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.karyawan.nama,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),

            const SizedBox(height: 24),

            // ID Karyawan (read-only)
            _buildLabel('ID Karyawan'),
            _buildReadOnlyField(widget.karyawan.nip),

            const SizedBox(height: 16),

            // Nama
            _buildLabel('Nama'),
            _buildTextField(controller: _namaController, hint: 'Masukan Nama'),

            const SizedBox(height: 16),

            // Jabatan
            _buildLabel('Jabatan'),
            _buildTextField(
                controller: _jabatanController, hint: 'Masukan Jabatan'),

            const SizedBox(height: 16),

            // Divisi
            _buildLabel('Divisi'),
            _buildDropdown(),

            const SizedBox(height: 16),

            // Jatah Cuti
            _buildLabel('Jatah Cuti Tahunan'),
            _buildTextField(
              controller: _jatahCutiController,
              hint: 'Masukan Jatah Cuti Tahunan',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Gmail (read-only)
            _buildLabel('Gmail'),
            _buildReadOnlyField(_email),

            const SizedBox(height: 32),

            // ── Tombol Hapus & Simpan ──
            Row(
              children: [
                // Tombol Hapus
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _konfirmasiHapus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF5350),
                        disabledBackgroundColor:
                            const Color(0xFFEF5350).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Tombol Simpan
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanPerubahan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        disabledBackgroundColor:
                            const Color(0xFF2196F3).withValues(alpha: 0.5),
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
                              'Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                ),
              ],
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
              color: Colors.grey[400], fontSize: 14, fontFamily: 'Poppins'),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        value,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontFamily: 'Poppins',
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
              fontSize: 14, color: Colors.black87, fontFamily: 'Poppins'),
          items: _divisiOptions
              .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedDivisi = val);
          },
        ),
      ),
    );
  }
}