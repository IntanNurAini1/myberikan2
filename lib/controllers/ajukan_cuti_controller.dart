// ================================
// riwayat_pengajuan_controller.dart
// ================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RiwayatPengajuanController extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool isSubmitting = false;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? karyawanData;

  List<Map<String, dynamic>> pengajuanList = [];

  // =========================
  // FETCH USER + KARYAWAN
  // =========================

  Future<void> fetchUserData() async {
    try {
      isLoading = true;
      notifyListeners();

      final uid = auth.currentUser!.uid;

      // ambil data user
      final userDoc = await firestore.collection('users').doc(uid).get();

      userData = userDoc.data();

      // ambil nip dari users
      final nip = userData?['nip'];

      // ambil data karyawan berdasarkan nip
      final karyawanDoc = await firestore.collection('karyawan').doc(nip).get();

      karyawanData = karyawanDoc.data();

      notifyListeners();
    } catch (e) {
      debugPrint("ERROR FETCH USER DATA : $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // FETCH RIWAYAT PENGAJUAN
  // =========================

  Future<void> fetchPengajuan() async {
    try {
      isLoading = true;
      notifyListeners();

      final nip = userData?['nip'];

      final result = await firestore
          .collection('pengajuan')
          .where('nip_pemohon', isEqualTo: nip)
          .orderBy('tanggal_pengajuan', descending: true)
          .get();

      pengajuanList = result.docs.map((e) => e.data()).toList();

      notifyListeners();
    } catch (e) {
      debugPrint("ERROR FETCH PENGAJUAN : $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // INIT
  // =========================

  Future<void> init() async {
    await fetchUserData();
    await fetchPengajuan();
  }

  // =========================
  // SISA CUTI
  // =========================

  int get sisaCuti {
    final total = karyawanData?['jatah_cuti_tahunan'] ?? 12;

    int dipakai = 0;

    for (var item in pengajuanList) {
      if (item['status_persetujuan'] == 'Disetujui') {
        final start = (item['tanggal_mulai'] as Timestamp).toDate();

        final end = (item['tanggal_akhir'] as Timestamp).toDate();

        dipakai += end.difference(start).inDays + 1;
      }
    }

    return total - dipakai;
  }

  // =========================
  // SUBMIT PENGAJUAN
  // =========================

  Future<void> submitPengajuan({
    required String jenisPengajuan,
    required DateTime tanggalMulai,
    required DateTime tanggalAkhir,
    required String buktiLampiran,
  }) async {
    try {
      isSubmitting = true;
      notifyListeners();

      final nip = userData?['nip'];

      await firestore.collection('pengajuan').add({
        'id_pengajuan': DateTime.now().millisecondsSinceEpoch.toString(),

        'nip_pemohon': nip,

        'nip_approver': '',

        'jenis_pengajuan': jenisPengajuan,

        'tanggal_mulai': tanggalMulai,

        'tanggal_akhir': tanggalAkhir,

        'bukti_lampiran': buktiLampiran,

        'status_persetujuan': 'Sedang Diproses',

        'tanggal_pengajuan': DateTime.now(),
      });

      await fetchPengajuan();

      notifyListeners();
    } catch (e) {
      debugPrint("ERROR SUBMIT PENGAJUAN : $e");
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // =========================
  // DELETE PENGAJUAN
  // =========================

  Future<void> deletePengajuan(String idPengajuan) async {
    try {
      await firestore.collection('pengajuan').doc(idPengajuan).delete();

      await fetchPengajuan();

      notifyListeners();
    } catch (e) {
      debugPrint("ERROR DELETE PENGAJUAN : $e");
    }
  }
}
