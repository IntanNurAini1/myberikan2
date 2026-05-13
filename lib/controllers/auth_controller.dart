import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/karyawan_model.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────

  /// Mendaftarkan karyawan baru.
  ///
  /// Alur:
  /// 1. Cek dokumen karyawan di collection `karyawan` (doc id = nip).
  /// 2. Cek username belum dipakai di collection `users`.
  /// 3. Buat akun Firebase Auth dengan [emailPemulihan] + [password].
  /// 4. Simpan dokumen baru ke collection `users`.
  ///
  /// Melempar [AuthException] bila ada kesalahan yang bisa ditampilkan ke UI.
  Future<UserModel> register({
    required String nip,
    required String emailPemulihan,
    required String username,
    required String password,
  }) async {
    // 1. Cek karyawan ada di Firestore
    final karyawanDoc =
        await _firestore.collection('karyawan').doc(nip).get();

    if (!karyawanDoc.exists) {
      throw AuthException('ID Karyawan tidak ditemukan. Hubungi admin.');
    }

    final karyawan = KaryawanModel.fromMap(
      karyawanDoc.data() as Map<String, dynamic>,
    );

    // 2. Pastikan NIP belum punya akun
    final nipAlreadyUsed = await _firestore
        .collection('users')
        .where('nip', isEqualTo: nip)
        .limit(1)
        .get();

    if (nipAlreadyUsed.docs.isNotEmpty) {
      throw AuthException(
          'ID Karyawan ini sudah terdaftar. Silakan masuk.');
    }

    // 3. Pastikan username belum dipakai
    final usernameQuery = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      throw AuthException(
          'Nama pengguna sudah digunakan. Pilih nama lain.');
    }

    // 4. Buat akun Firebase Auth
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

    // 5. Simpan ke collection `users`
    final newUser = UserModel(
      uid: uid,
      nip: nip,
      username: username,
      emailPemulihan: emailPemulihan,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .set(newUser.toMap());

    // Kembalikan UserModel agar view bisa langsung dipakai
    return newUser;
  }

  // ─────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────

  /// Masuk menggunakan [username] + [password].
  ///
  /// Alur:
  /// 1. Cari dokumen `users` yang username-nya cocok.
  /// 2. Ambil [emailPemulihan] dari dokumen tersebut.
  /// 3. Login ke Firebase Auth dengan email + password.
  /// 4. Kembalikan [UserModel] aktif.
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    // 1. Cari user berdasarkan username
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

    // 2. Login ke Firebase Auth pakai emailPemulihan
    try {
      await _auth.signInWithEmailAndPassword(
        email: userModel.emailPemulihan,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authErrorMessage(e.code));
    }

    return userModel;
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

  /// Dipakai view lain kalau butuh data profil karyawan.
  Future<KaryawanModel?> getKaryawan(String nip) async {
    final doc = await _firestore.collection('karyawan').doc(nip).get();
    if (!doc.exists) return null;
    return KaryawanModel.fromMap(doc.data() as Map<String, dynamic>);
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
// Custom exception agar view tinggal catch satu tipe
// ─────────────────────────────────────────────

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}