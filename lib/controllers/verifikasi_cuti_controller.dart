// ================================
// verifikasi_cuti_controller.dart
// ================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/pengajuan_model.dart';
import '../models/karyawan_model.dart';

class VerifikasiCutiController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool isSubmitting = false;

  List<Map<String, dynamic>> pengajuanMenunggu = [];
  final Map<String, KaryawanModel> _karyawanCache = {};

  // ─────────────────────────────────────────────
  // FETCH SEMUA PENGAJUAN "Sedang Diproses"
  // ─────────────────────────────────────────────

  Future<void> fetchPengajuanMenunggu() async {
    try {
      isLoading = true;
      notifyListeners();

      final currentUid = _auth.currentUser?.uid;

      String? nipApprover;
      if (currentUid != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUid).get();
        nipApprover = userDoc.data()?['nip'];
      }

      final result = await _firestore
          .collection('pengajuan')
          .where('status_persetujuan', isEqualTo: 'Sedang Diproses')
          .orderBy('tanggal_pengajuan', descending: true)
          .get();

      final List<Map<String, dynamic>> temp = [];

      for (final doc in result.docs) {
        final data = doc.data();
        final nip = data['nip_pemohon'] ?? '';

        KaryawanModel? karyawan = _karyawanCache[nip];
        if (karyawan == null && nip.isNotEmpty) {
          final karyawanDoc =
              await _firestore.collection('karyawan').doc(nip).get();
          if (karyawanDoc.exists) {
            final karyawanData = karyawanDoc.data()!;
            karyawanData['nip'] = karyawanDoc.id; // inject doc ID sebagai nip
            karyawan = KaryawanModel.fromMap(karyawanData);
            debugPrint('DEBUG fetch karyawan: nip="${karyawan.nip}", jatah=${karyawan.jatahCutiTahunan}');
            _karyawanCache[nip] = karyawan;
          }
        }

        temp.add({
          'docId': doc.id,
          'pengajuan': PengajuanModel.fromMap(data),
          'karyawan': karyawan,
          'nipApprover': nipApprover ?? '',
        });
      }

      pengajuanMenunggu = temp;
      notifyListeners();
    } catch (e) {
      debugPrint('ERROR FETCH VERIFIKASI CUTI: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // SEARCH FILTER (client-side)
  // ─────────────────────────────────────────────

  List<Map<String, dynamic>> filterByNama(String keyword) {
    if (keyword.isEmpty) return pengajuanMenunggu;
    return pengajuanMenunggu.where((item) {
      final karyawan = item['karyawan'] as KaryawanModel?;
      return karyawan?.nama
              .toLowerCase()
              .contains(keyword.toLowerCase()) ??
          false;
    }).toList();
  }

  // ─────────────────────────────────────────────
  // HITUNG DURASI CUTI (inklusif)
  // ─────────────────────────────────────────────

  int hitungDurasi(DateTime mulai, DateTime akhir) {
    final m = DateTime(mulai.year, mulai.month, mulai.day);
    final a = DateTime(akhir.year, akhir.month, akhir.day);
    return a.difference(m).inDays + 1;
  }

  // ─────────────────────────────────────────────
  // VALIDASI SEBELUM SETUJUI
  // ─────────────────────────────────────────────

  String? validasiCuti({
    required PengajuanModel pengajuan,
    required KaryawanModel? karyawan,
  }) {
    if (karyawan == null) {
      return 'Data karyawan tidak ditemukan di sistem.';
    }

    final durasi = hitungDurasi(
      pengajuan.tanggalMulai,
      pengajuan.tanggalAkhir,
    );

    if (durasi <= 0) {
      return 'Tanggal cuti tidak valid — tanggal akhir lebih awal dari tanggal mulai.';
    }

    final jatah = karyawan.jatahCutiTahunan;

    if (durasi > jatah) {
      return 'Pengajuan tidak dapat disetujui karena durasi cuti yang diminta '
          '($durasi hari) melebihi sisa jatah cuti tahunan '
          '${karyawan.nama} ($jatah hari).';
    }

    return null; // valid
  }

  // ─────────────────────────────────────────────
  // UPDATE STATUS: Setujui Cuti
  // ─────────────────────────────────────────────

  Future<SetujuiResult> setujuiCuti({
    required String docId,
    required String nipApprover,
    required PengajuanModel pengajuan,
    required KaryawanModel? karyawan,
  }) async {
    debugPrint('DEBUG setujuiCuti: karyawan.nip="${karyawan?.nip}", jatah=${karyawan?.jatahCutiTahunan}');

    final errorMsg = validasiCuti(pengajuan: pengajuan, karyawan: karyawan);
    if (errorMsg != null) {
      return SetujuiResult(sukses: false, pesanError: errorMsg);
    }

    try {
      isSubmitting = true;
      notifyListeners();

      final durasi = hitungDurasi(
        pengajuan.tanggalMulai,
        pengajuan.tanggalAkhir,
      );

      // Ambil nip langsung dari pengajuan sebagai fallback
      final nipKaryawan = karyawan!.nip.isNotEmpty
          ? karyawan.nip
          : pengajuan.nipPemohon;

      debugPrint('DEBUG batch update karyawan doc: "$nipKaryawan"');

      final batch = _firestore.batch();

      final pengajuanRef = _firestore.collection('pengajuan').doc(docId);
      batch.update(pengajuanRef, {
        'status_persetujuan': 'Disetujui',
        'nip_approver': nipApprover,
      });

      final karyawanRef =
          _firestore.collection('karyawan').doc(nipKaryawan);
      batch.update(karyawanRef, {
        'jatah_cuti_tahunan': karyawan.jatahCutiTahunan - durasi,
      });

      await batch.commit();

      _karyawanCache.remove(nipKaryawan);

      await fetchPengajuanMenunggu();
      return SetujuiResult(sukses: true);
    } catch (e) {
      debugPrint('ERROR SETUJUI CUTI: $e');
      return SetujuiResult(
        sukses: false,
        pesanError: 'Terjadi kesalahan saat memproses. Coba lagi.',
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE STATUS: Tolak Cuti
  // ─────────────────────────────────────────────

  Future<bool> tolakCuti({
    required String docId,
    required String nipApprover,
  }) async {
    try {
      isSubmitting = true;
      notifyListeners();

      await _firestore.collection('pengajuan').doc(docId).update({
        'status_persetujuan': 'Ditolak',
        'nip_approver': nipApprover,
      });

      await fetchPengajuanMenunggu();
      return true;
    } catch (e) {
      debugPrint('ERROR TOLAK CUTI: $e');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  Future<void> init() async {
    await fetchPengajuanMenunggu();
  }
}

// ─────────────────────────────────────────────
// RESULT WRAPPER
// ─────────────────────────────────────────────

class SetujuiResult {
  final bool sukses;
  final String? pesanError;

  const SetujuiResult({required this.sukses, this.pesanError});
}