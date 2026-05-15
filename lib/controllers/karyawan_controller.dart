import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/karyawan_model.dart';
import '../models/user_model.dart';

class KaryawanController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // HELPER: inject doc.id sebagai nip ke dalam data
  // Karena NIP = document ID, bukan field di dalam dokumen
  // ─────────────────────────────────────────────

  KaryawanModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['nip'] = doc.id;
    return KaryawanModel.fromMap(data);
  }

  // ─────────────────────────────────────────────
  // VALIDASI DATA KARYAWAN
  // ─────────────────────────────────────────────

  void _validateKaryawan({
    required String nama,
    required String jabatan,
    required String divisi,
    required int jatahCutiTahunan,
  }) {
    if (nama.trim().isEmpty) {
      throw KaryawanException('Nama tidak boleh kosong.');
    }
    if (jabatan.trim().isEmpty) {
      throw KaryawanException('Jabatan tidak boleh kosong.');
    }
    if (divisi.trim().isEmpty || divisi == 'Pilih Divisi') {
      throw KaryawanException('Silakan pilih divisi.');
    }
    if (jatahCutiTahunan < 0) {
      throw KaryawanException('Jatah cuti tidak boleh negatif.');
    }
  }

  // ─────────────────────────────────────────────
  // GET EMAIL PEMULIHAN BY NIP
  // ─────────────────────────────────────────────

  Future<String> getEmailByNip(String nip) async {
    try {
      debugPrint('DEBUG getEmailByNip: mencari nip = "$nip" (len=${nip.length})');

      final snapshot = await _firestore
          .collection('users')
          .where('nip', isEqualTo: nip)
          .limit(1)
          .get();

      debugPrint('DEBUG getEmailByNip: docs found = ${snapshot.docs.length}');

      if (snapshot.docs.isEmpty) return '-';

      final user = UserModel.fromMap(snapshot.docs.first.data());
      debugPrint('DEBUG getEmailByNip: email = ${user.emailPemulihan}');

      return user.emailPemulihan.isEmpty ? '-' : user.emailPemulihan;
    } catch (e) {
      debugPrint('DEBUG getEmailByNip: error = $e');
      return '-';
    }
  }

  // ─────────────────────────────────────────────
  // GET ALL KARYAWAN (Stream real-time)
  // ─────────────────────────────────────────────

  Stream<List<KaryawanModel>> getKaryawanStream() {
    return _firestore
        .collection('karyawan')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _fromDoc(doc)).toList());
  }

  // ─────────────────────────────────────────────
  // GET LIST KARYAWAN (Future, filter divisi)
  // ─────────────────────────────────────────────

  Future<List<KaryawanModel>> getKaryawanList({String? divisi}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('karyawan');

    if (divisi != null && divisi.isNotEmpty && divisi != 'Semua Divisi') {
      query = query.where('divisi', isEqualTo: divisi);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['nip'] = doc.id;
      return KaryawanModel.fromMap(data);
    }).toList();
  }

  // ─────────────────────────────────────────────
  // GET KARYAWAN BY NIP (doc id = nip)
  // ─────────────────────────────────────────────

  Future<KaryawanModel?> getKaryawanByNip(String nip) async {
    final doc = await _firestore.collection('karyawan').doc(nip).get();
    if (!doc.exists) return null;
    return _fromDoc(doc);
  }

  // ─────────────────────────────────────────────
  // SEARCH KARYAWAN BY NAMA atau NIP (lokal)
  // ─────────────────────────────────────────────

  Future<List<KaryawanModel>> searchKaryawan(String keyword) async {
    if (keyword.trim().isEmpty) return getKaryawanList();

    final snapshot = await _firestore.collection('karyawan').get();
    final all = snapshot.docs.map((doc) {
      final data = doc.data();
      data['nip'] = doc.id;
      return KaryawanModel.fromMap(data);
    }).toList();

    final q = keyword.trim().toLowerCase();
    return all.where((k) {
      return k.nama.toLowerCase().contains(q) ||
          k.nip.toLowerCase().contains(q);
    }).toList();
  }

  // ─────────────────────────────────────────────
  // GET LIST DIVISI (unik)
  // ─────────────────────────────────────────────

  Future<List<String>> getDivisiList() async {
    final snapshot = await _firestore.collection('karyawan').get();
    final divisiSet = snapshot.docs
        .map((doc) => (doc.data()['divisi'] ?? '') as String)
        .where((d) => d.isNotEmpty)
        .toSet();
    return ['Semua Divisi', ...divisiSet.toList()..sort()];
  }

  // ─────────────────────────────────────────────
  // ADD KARYAWAN BARU
  // doc id = nip
  // ─────────────────────────────────────────────

  Future<void> addKaryawan({
    required String nip,
    required String nama,
    required String jabatan,
    required String divisi,
    required int jatahCutiTahunan,
    String fotoProfil = '',
  }) async {
    if (nip.trim().isEmpty) {
      throw KaryawanException('ID Karyawan tidak boleh kosong.');
    }
    _validateKaryawan(
      nama: nama,
      jabatan: jabatan,
      divisi: divisi,
      jatahCutiTahunan: jatahCutiTahunan,
    );

    final existing = await _firestore.collection('karyawan').doc(nip).get();
    if (existing.exists) {
      throw KaryawanException('ID Karyawan sudah terdaftar.');
    }

    final newKaryawan = KaryawanModel(
      nip: nip,
      nama: nama,
      divisi: divisi,
      role: jabatan,
      jatahCutiTahunan: jatahCutiTahunan,
      fotoProfil: fotoProfil,
    );

    await _firestore.collection('karyawan').doc(nip).set(newKaryawan.toMap());
  }

  // ─────────────────────────────────────────────
  // UPDATE KARYAWAN
  // NIP tidak bisa diubah (doc id)
  // ─────────────────────────────────────────────

  Future<void> updateKaryawan({
    required String nip,
    required String nama,
    required String jabatan,
    required String divisi,
    required int jatahCutiTahunan,
    String? fotoProfil,
  }) async {
    _validateKaryawan(
      nama: nama,
      jabatan: jabatan,
      divisi: divisi,
      jatahCutiTahunan: jatahCutiTahunan,
    );

    final existing = await _firestore.collection('karyawan').doc(nip).get();
    if (!existing.exists) {
      throw KaryawanException('Data karyawan tidak ditemukan.');
    }

    final Map<String, dynamic> updates = {
      'nama': nama,
      'role': jabatan,
      'divisi': divisi,
      'jatah_cuti_tahunan': jatahCutiTahunan,
    };

    if (fotoProfil != null && fotoProfil.isNotEmpty) {
      updates['foto_profil'] = fotoProfil;
    }

    await _firestore.collection('karyawan').doc(nip).update(updates);
  }

  // ─────────────────────────────────────────────
  // DELETE KARYAWAN
  // Alur:
  // 1. Cari dokumen user di collection users by nip
  // 2. Ambil uid dari dokumen user
  // 3. Login sementara pakai emailPemulihan untuk bisa delete Firebase Auth
  //    → TIDAK bisa dari client tanpa re-auth
  //    → Solusi: hapus Firestore saja, Firebase Auth di-handle Cloud Functions
  //    → Untuk sekarang: hapus collection karyawan + users,
  //      tandai uid untuk dihapus via flag atau log
  // ─────────────────────────────────────────────

  Future<void> deleteKaryawan(String nip) async {
    // 1. Pastikan dokumen karyawan ada
    final karyawanDoc =
        await _firestore.collection('karyawan').doc(nip).get();
    if (!karyawanDoc.exists) {
      throw KaryawanException('Data karyawan tidak ditemukan.');
    }

    // 2. Cari dokumen user terkait
    final userSnapshot = await _firestore
        .collection('users')
        .where('nip', isEqualTo: nip)
        .limit(1)
        .get();

    String? uid;
    if (userSnapshot.docs.isNotEmpty) {
      final userData = userSnapshot.docs.first.data();
      uid = userData['uid'] as String?;
    }

    // 3. Hapus dokumen karyawan
    await _firestore.collection('karyawan').doc(nip).delete();

    // 4. Hapus dokumen user di collection users
    for (final doc in userSnapshot.docs) {
      await doc.reference.delete();
    }

    // 5. Hapus akun Firebase Auth
    // Firebase Auth hanya bisa dihapus oleh user itu sendiri (deleteUser)
    // atau Admin SDK. Dari client, kita bisa hapus kalau uid cocok dengan
    // user yang sedang login (misal admin menghapus akunnya sendiri — jarang).
    // Solusi terbaik: gunakan Cloud Functions dengan Admin SDK.
    // Untuk fallback client-side: cek apakah current user = uid yang dihapus.
    if (uid != null) {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        // Kasus langka: admin hapus akunnya sendiri
        await currentUser.delete();
      } else {
        // Catat uid yang perlu dihapus di collection 'deleted_users'
        // Cloud Functions akan watch collection ini dan hapus dari Auth
        await _firestore.collection('deleted_users').doc(uid).set({
          'uid': uid,
          'nip': nip,
          'deleted_at': FieldValue.serverTimestamp(),
        });
        debugPrint(
            'INFO: uid $uid ditandai untuk dihapus dari Firebase Auth via Cloud Functions');
      }
    }
  }
}

// ─────────────────────────────────────────────
// CUSTOM EXCEPTION
// ─────────────────────────────────────────────

class KaryawanException implements Exception {
  final String message;
  const KaryawanException(this.message);

  @override
  String toString() => message;
}