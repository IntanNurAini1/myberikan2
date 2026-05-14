import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/kehadiran_model.dart';
import '../models/karyawan_model.dart';

/// Gabungan data kehadiran + info karyawan untuk ditampilkan di list.
class KehadiranDisplay {
  final KehadiranModel kehadiran;
  final KaryawanModel karyawan;

  const KehadiranDisplay({
    required this.kehadiran,
    required this.karyawan,
  });
}

class KehadiranController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // AMBIL DATA KEHADIRAN BERDASARKAN TANGGAL
  // ─────────────────────────────────────────────

  /// Mengambil semua kehadiran pada [tanggal] tertentu,
  /// lalu join dengan data karyawan dari collection `karyawan`.
  ///
  /// Filter tanggal: mengambil record dari jam 00:00:00 s/d 23:59:59
  /// pada hari yang dipilih.
  Future<List<KehadiranDisplay>> getKehadiranByTanggal(
      DateTime tanggal) async {
    final startOfDay =
        DateTime(tanggal.year, tanggal.month, tanggal.day, 0, 0, 0);
    final endOfDay =
        DateTime(tanggal.year, tanggal.month, tanggal.day, 23, 59, 59);

    // 1. Query collection kehadiran berdasarkan rentang tanggal
    final snapshot = await _firestore
        .collection('kehadiran')
        .where(
          'tanggal_kehadiran',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'tanggal_kehadiran',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
        )
        .orderBy('tanggal_kehadiran', descending: false)
        .get();

    if (snapshot.docs.isEmpty) return [];

    // 2. Kumpulkan semua NIP unik untuk batch fetch karyawan
    final nipSet = snapshot.docs
        .map((d) => (d.data()['nip'] ?? '') as String)
        .where((nip) => nip.isNotEmpty)
        .toSet();

    // 3. Fetch data karyawan (doc id = nip)
    final Map<String, KaryawanModel> karyawanMap = {};
    for (final nip in nipSet) {
      final karyawanDoc =
          await _firestore.collection('karyawan').doc(nip).get();
      if (karyawanDoc.exists) {
        karyawanMap[nip] = KaryawanModel.fromMap(
          karyawanDoc.data() as Map<String, dynamic>,
        );
      }
    }

    // 4. Gabungkan kehadiran + karyawan
    final List<KehadiranDisplay> result = [];
    for (final doc in snapshot.docs) {
      final kehadiran = KehadiranModel.fromMap(doc.data());
      final karyawan = karyawanMap[kehadiran.nip];
      if (karyawan != null) {
        result.add(KehadiranDisplay(
          kehadiran: kehadiran,
          karyawan: karyawan,
        ));
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────
  // FILTER PENCARIAN (lokal, setelah data diambil)
  // ─────────────────────────────────────────────

  /// Filter [list] berdasarkan [query] (nama atau NIP).
  /// Pencarian case-insensitive.
  List<KehadiranDisplay> filterByQuery(
    List<KehadiranDisplay> list,
    String query,
  ) {
    if (query.trim().isEmpty) return list;
    final q = query.trim().toLowerCase();
    return list.where((item) {
      final namaMatch = item.karyawan.nama.toLowerCase().contains(q);
      final nipMatch = item.kehadiran.nip.toLowerCase().contains(q);
      return namaMatch || nipMatch;
    }).toList();
  }
}