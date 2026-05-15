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

  // List pengajuan yang statusnya "Sedang Diproses"
  List<Map<String, dynamic>> pengajuanMenunggu = [];

  // Cache data karyawan agar tidak fetch berulang
  final Map<String, KaryawanModel> _karyawanCache = {};

  // ─────────────────────────────────────────────
  // FETCH SEMUA PENGAJUAN "Sedang Diproses"
  // ─────────────────────────────────────────────

  Future<void> fetchPengajuanMenunggu() async {
    try {
      isLoading = true;
      notifyListeners();

      final currentUid = _auth.currentUser?.uid;

      // Ambil nip approver (user yang sedang login)
      String? nipApprover;
      if (currentUid != null) {
        final userDoc =
            await _firestore.collection('users').doc(currentUid).get();
        nipApprover = userDoc.data()?['nip'];
      }

      // Query pengajuan dengan status Sedang Diproses
      final result = await _firestore
          .collection('pengajuan')
          .where('status_persetujuan', isEqualTo: 'Sedang Diproses')
          .orderBy('tanggal_pengajuan', descending: true)
          .get();

      // Gabungkan dengan data karyawan
      final List<Map<String, dynamic>> temp = [];

      for (final doc in result.docs) {
        final data = doc.data();
        final nip = data['nip_pemohon'] ?? '';

        // Ambil data karyawan (gunakan cache)
        KaryawanModel? karyawan = _karyawanCache[nip];
        if (karyawan == null) {
          final karyawanDoc =
              await _firestore.collection('karyawan').doc(nip).get();
          if (karyawanDoc.exists) {
            karyawan =
                KaryawanModel.fromMap(karyawanDoc.data()!);
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
  // UPDATE STATUS: Setujui Cuti
  // ─────────────────────────────────────────────

  Future<bool> setujuiCuti({
    required String docId,
    required String nipApprover,
  }) async {
    try {
      isSubmitting = true;
      notifyListeners();

      await _firestore.collection('pengajuan').doc(docId).update({
        'status_persetujuan': 'Disetujui',
        'nip_approver': nipApprover,
      });

      await fetchPengajuanMenunggu();
      return true;
    } catch (e) {
      debugPrint('ERROR SETUJUI CUTI: $e');
      return false;
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