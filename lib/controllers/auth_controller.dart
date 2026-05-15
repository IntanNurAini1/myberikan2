// auth_controller.dart — UPDATED
// Sudah include fungsi-fungsi KARYAWAN (lihat bagian KARYAWAN CRUD di bawah)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/karyawan_model.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // VALIDASI PASSWORD
  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[@!]).{8,}$');
    return regex.hasMatch(password);
  }

  // VALIDASI GMAIL
  bool _isValidGmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    return regex.hasMatch(email);
  }

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────

  Future<UserModel> register({
    required String nip,
    required String emailPemulihan,
    required String username,
    required String password,
  }) async {
    if (!_isValidGmail(emailPemulihan)) {
      throw AuthException('Gunakan akun Google yang valid (@gmail.com).');
    }

    if (!_isValidPassword(password)) {
      throw AuthException(
        'Kata sandi minimal 8 karakter, mengandung huruf kapital, angka, dan simbol spesial(@!).',
      );
    }

    final karyawanDoc = await _firestore.collection('karyawan').doc(nip).get();
    if (!karyawanDoc.exists) {
      throw AuthException('ID Karyawan tidak ditemukan.');
    }

    final nipAlreadyUsed = await _firestore
        .collection('users')
        .where('nip', isEqualTo: nip)
        .limit(1)
        .get();

    if (nipAlreadyUsed.docs.isNotEmpty) {
      throw AuthException('ID Karyawan ini sudah terdaftar. Silakan masuk.');
    }

    final usernameQuery = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      throw AuthException('Nama pengguna sudah digunakan. Pilih nama lain.');
    }

    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: emailPemulihan,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authErrorMessage(e.code));
    }

    final uid = credential.user!.uid;
    final newUser = UserModel(
      uid: uid,
      nip: nip,
      username: username,
      emailPemulihan: emailPemulihan,
    );

    await _firestore.collection('users').doc(uid).set(newUser.toMap());
    return newUser;
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw AuthException('Nama pengguna tidak ditemukan.');
    }

    final userDoc = query.docs.first;
    final userModel = UserModel.fromMap(userDoc.data());

    try {
      await _auth.signInWithEmailAndPassword(
        email: userModel.emailPemulihan,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authErrorMessage(e.code));
    }

    final karyawanDoc =
        await _firestore.collection('karyawan').doc(userModel.nip).get();

    if (!karyawanDoc.exists) {
      throw AuthException('Data karyawan tidak ditemukan.');
    }

    final karyawanData = karyawanDoc.data()!;
    return {
      'user': userModel,
      'role': karyawanData['role'],
    };
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────
  // HELPER: ambil data karyawan dari NIP
  // ─────────────────────────────────────────────

  Future<KaryawanModel?> getKaryawan(String nip) async {
    final doc = await _firestore.collection('karyawan').doc(nip).get();
    if (!doc.exists) return null;
    return KaryawanModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────
  // KARYAWAN CRUD
  // ─────────────────────────────────────────────

  /// Mendapatkan semua karyawan, opsional filter divisi.
  Future<List<KaryawanModel>> getKaryawanList({String? divisi}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('karyawan');

    if (divisi != null &&
        divisi.isNotEmpty &&
        divisi != 'Semua Divisi') {
      query = query.where('divisi', isEqualTo: divisi);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => KaryawanModel.fromMap(doc.data()))
        .toList();
  }

  /// Stream karyawan real-time.
  Stream<List<KaryawanModel>> getKaryawanStream() {
    return _firestore.collection('karyawan').snapshots().map(
          (snap) => snap.docs
              .map((doc) => KaryawanModel.fromMap(doc.data()))
              .toList(),
        );
  }

  /// Daftar divisi unik dari semua karyawan.
  Future<List<String>> getDivisiList() async {
    final snapshot = await _firestore.collection('karyawan').get();
    final divisiSet = snapshot.docs
        .map((doc) => (doc.data()['divisi'] ?? '') as String)
        .where((d) => d.isNotEmpty)
        .toSet();
    return ['Semua Divisi', ...divisiSet.toList()..sort()];
  }

  /// Tambah karyawan baru ke Firestore.
  Future<void> addKaryawan({
    required String nip,
    required String nama,
    required String jabatan,
    required String divisi,
    required int jatahCutiTahunan,
    String fotoProfil = '',
  }) async {
    if (nip.isEmpty) throw AuthException('ID Karyawan tidak boleh kosong.');
    if (nama.isEmpty) throw AuthException('Nama tidak boleh kosong.');
    if (jabatan.isEmpty) throw AuthException('Jabatan tidak boleh kosong.');
    if (divisi.isEmpty || divisi == 'Pilih Divisi') {
      throw AuthException('Silakan pilih divisi.');
    }
    if (jatahCutiTahunan < 0) {
      throw AuthException('Jatah cuti tidak boleh negatif.');
    }

    final existing = await _firestore.collection('karyawan').doc(nip).get();
    if (existing.exists) {
      throw AuthException('ID Karyawan sudah terdaftar.');
    }

    final newKaryawan = KaryawanModel(
      nip: nip,
      nama: nama,
      divisi: divisi,
      role: jabatan,
      jatahCutiTahunan: jatahCutiTahunan,
      fotoProfil: fotoProfil,
    );

    await _firestore
        .collection('karyawan')
        .doc(nip)
        .set(newKaryawan.toMap());
  }

  /// Update data karyawan yang sudah ada (NIP tidak bisa diubah).
  Future<void> updateKaryawan({
    required String nip,
    required String nama,
    required String jabatan,
    required String divisi,
    required int jatahCutiTahunan,
    String? fotoProfil,
  }) async {
    if (nama.isEmpty) throw AuthException('Nama tidak boleh kosong.');
    if (jabatan.isEmpty) throw AuthException('Jabatan tidak boleh kosong.');
    if (divisi.isEmpty || divisi == 'Pilih Divisi') {
      throw AuthException('Silakan pilih divisi.');
    }
    if (jatahCutiTahunan < 0) {
      throw AuthException('Jatah cuti tidak boleh negatif.');
    }

    final Map<String, dynamic> updates = {
      'nama': nama,
      'role': jabatan,
      'divisi': divisi,
      'jatah_cuti_tahunan': jatahCutiTahunan,
    };

    if (fotoProfil != null) {
      updates['foto_profil'] = fotoProfil;
    }

    await _firestore.collection('karyawan').doc(nip).update(updates);
  }

  /// Hapus karyawan berdasarkan NIP.
  Future<void> deleteKaryawan(String nip) async {
    await _firestore.collection('karyawan').doc(nip).delete();
  }

  // ─────────────────────────────────────────────
  // PRIVATE: terjemahkan kode error Firebase Auth
  // ─────────────────────────────────────────────

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Akun Google ini sudah terdaftar.';
      case 'invalid-email':
        return 'Format akun Google tidak valid.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah. Minimal 6 karakter.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Nama pengguna atau kata sandi salah.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}

// ─────────────────────────────────────────────
// Custom exception
// ─────────────────────────────────────────────

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}