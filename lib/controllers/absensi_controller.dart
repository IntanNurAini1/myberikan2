import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/kehadiran_model.dart';

// ─────────────────────────────────────────────
// KONSTANTA AREA KANTOR
// ─────────────────────────────────────────────
const double _areaLat = -6.9789;
const double _areaLng = 107.6338;
const double _radiusMeter = 200000000;

class AbsensiController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────
  // STATUS ABSEN BERDASARKAN JAM
  // 05:00 - 08:00 → HADIR
  // 08:01 - 10:00 → TERLAMBAT
  // Selain itu  → null (tidak bisa absen)
  // ─────────────────────────────────────────────

  /// Kembalikan status absen berdasarkan waktu sekarang.
  /// null = di luar jam absen (tombol nonaktif).
static String? getStatusByJam(DateTime now) {
  final jam = now.hour;
  final menit = now.minute;
  final totalMenit = jam * 60 + menit;

  const buka = 6 * 60;
  const batasHadir = 8 * 60;
  const tutup = 20 * 60;

  if (totalMenit >= buka && totalMenit <= batasHadir) {
    return 'HADIR';
  }

  if (totalMenit > batasHadir && totalMenit <= tutup) {
    return 'TERLAMBAT';
  }

  return null;
}

String? getStatusByWaktu() {
  return AbsensiController.getStatusByJam(DateTime.now());
}

  /// Label tombol sesuai jam.
  String getLabelTombol() {
    final status = getStatusByJam(DateTime.now());
    if (status == null) return 'Di Luar Jam Absen';
    return 'Absen Sekarang';
  }

  // ─────────────────────────────────────────────
  // CEK LOKASI
  // ─────────────────────────────────────────────

  /// Hitung jarak (meter) antara dua koordinat pakai formula Haversine.
  double _hitungJarak(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // radius bumi dalam meter
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  /// Minta izin lokasi dan ambil posisi sekarang.
  Future<Position> _getPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw AbsensiException('Izin lokasi ditolak.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw AbsensiException(
          'Izin lokasi diblokir permanen. Aktifkan di pengaturan.');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw AbsensiException('GPS tidak aktif. Aktifkan lokasi terlebih dahulu.');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ─────────────────────────────────────────────
  // ABSEN SEKARANG
  // ─────────────────────────────────────────────

  /// Proses absen: cek waktu → cek lokasi → cek sudah absen hari ini →
  /// simpan ke Firestore collection `kehadiran`.
  Future<KehadiranModel> absenSekarang() async {
    // 1. Cek jam
    final status = getStatusByJam(DateTime.now());
    if (status == null) {
      throw AbsensiException('Di luar jam absen (01:00 - 10:00).');
    }

    // 2. Cek user login
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw AbsensiException('Sesi habis. Silakan login ulang.');
    }

    // 3. Ambil NIP dari collection users
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (!userDoc.exists) {
      throw AbsensiException('Data user tidak ditemukan.');
    }
    final nip = userDoc.data()!['nip'] as String? ?? '';
    if (nip.isEmpty) throw AbsensiException('NIP tidak ditemukan.');

    // 4. Cek sudah absen hari ini
    final sudahAbsen = await sudahAbsenHariIni(nip);
    if (sudahAbsen) {
      throw AbsensiException('Anda sudah melakukan absen hari ini.');
    }

    // 5. Cek lokasi
    final position = await _getPosition();
    final jarak = _hitungJarak(
      position.latitude,
      position.longitude,
      _areaLat,
      _areaLng,
    );
    debugPrint('DEBUG absen: jarak dari kantor = ${jarak.toStringAsFixed(1)} m');

    if (jarak > _radiusMeter) {
      throw AbsensiException(
        'Anda berada di luar area kantor (${jarak.toStringAsFixed(0)} m dari kantor).',
      );
    }

    // 6. Simpan ke Firestore
    final now = DateTime.now();
    final idKehadiran = _firestore.collection('kehadiran').doc().id;

    final kehadiran = KehadiranModel(
      idKehadiran: idKehadiran,
      nip: nip,
      tanggalKehadiran: now,
      status: status,
    );

    await _firestore
        .collection('kehadiran')
        .doc(idKehadiran)
        .set(kehadiran.toMap());

    return kehadiran;
  }

  // ─────────────────────────────────────────────
  // CEK SUDAH ABSEN HARI INI
  // ─────────────────────────────────────────────

  Future<bool> sudahAbsenHariIni(String nip) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('kehadiran')
        .where('nip', isEqualTo: nip)
        .where('tanggal_kehadiran',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('tanggal_kehadiran',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ─────────────────────────────────────────────
  // GET NIP DARI USER LOGIN
  // ─────────────────────────────────────────────

  Future<String> getNipCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return '';

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    if (!userDoc.exists) return '';
    return userDoc.data()!['nip'] as String? ?? '';
  }

  // ─────────────────────────────────────────────
  // GET RIWAYAT ABSENSI BY NIP
  // Diurutkan dari terbaru, max [limit] data
  // ─────────────────────────────────────────────

  Future<List<KehadiranModel>> getRiwayatAbsensi({
    required String nip,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('kehadiran')
        .where('nip', isEqualTo: nip)
        .orderBy('tanggal_kehadiran', descending: true);

    if (limit != null) query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => KehadiranModel.fromMap(doc.data()))
        .toList();
  }

  // ─────────────────────────────────────────────
  // GET DATA KARYAWAN YANG SEDANG LOGIN
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfilCurrentUser() async {
    final nip = await getNipCurrentUser();
    if (nip.isEmpty) return null;

    final karyawanDoc =
        await _firestore.collection('karyawan').doc(nip).get();
    if (!karyawanDoc.exists) return null;

    final data = karyawanDoc.data()!;
    data['nip'] = nip; // inject doc id
    return data;
  }
}

// ─────────────────────────────────────────────
// CUSTOM EXCEPTION
// ─────────────────────────────────────────────

class AbsensiException implements Exception {
  final String message;
  const AbsensiException(this.message);

  @override
  String toString() => message;
}