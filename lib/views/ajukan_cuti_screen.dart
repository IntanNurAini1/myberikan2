// import 'package:flutter/material.dart';
// import 'package:myberikan/extension/navigation.dart';

// class AjukanCutiScreen extends StatefulWidget {
//   const AjukanCutiScreen({super.key});
//   static String id = "/AjukanCutiScreen";

//   @override
//   State<AjukanCutiScreen> createState() => _AjukanCutiScreenState();
// }

// class _AjukanCutiScreenState extends State<AjukanCutiScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEEF3F8),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: EdgeInsets.all(16),
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: IconButton(
//                       onPressed: () {
//                         context.pop();
//                       },
//                       icon: Icon(Icons.arrow_back_ios_new),
//                     ),
//                   ),
//                   Text(
//                     "Pengajuan Cuti",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontFamily: "Poppins_SemiBold",
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 25,
//                     backgroundImage: AssetImage("assets/images/profile 1.png"),
//                   ),
//                   SizedBox(width: 20),
//                   Text(
//                     "Budi Santoso",
//                     style: TextStyle(
//                       fontFamily: "Poppins_SemiBold",
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(16),
//               child: Column(children: [

//               ]),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//   Widget _label(String text) => Padding(
//         padding: const EdgeInsets.only(top: 15, bottom: 6),
//         child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
//       );

//   Widget _input(
//     TextEditingController controller,
//     String hint, {
//     TextInputType keyboard = TextInputType.text,
//   }) =>
//       TextField(
//         controller: controller,
//         keyboardType: keyboard,
//         decoration: InputDecoration(
//           hintText: hint,
//           filled: true,
//           fillColor: Colors.grey[200],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(10),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       );
// }
// =======================
// ajukan_cuti_screen.dart
// =======================

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myberikan/extension/navigation.dart';

class AjukanCutiScreen extends StatefulWidget {
  const AjukanCutiScreen({super.key});

  @override
  State<AjukanCutiScreen> createState() => _AjukanCutiScreenState();
}

class _AjukanCutiScreenState extends State<AjukanCutiScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;

  final alasanController = TextEditingController();

  Map<String, dynamic>? userData;
  Map<String, dynamic>? karyawanData;

  DateTime? tanggalAwal;
  DateTime? tanggalAkhir;

  File? buktiFile;
  String? buktiBase64;

  bool isLoading = true;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final uid = auth.currentUser!.uid;

    final userDoc = await firestore.collection('users').doc(uid).get();

    userData = userDoc.data();

    final nip = userData?['nip'];

    final karyawanDoc = await firestore.collection('karyawan').doc(nip).get();

    karyawanData = karyawanDoc.data();

    isLoading = false;

    setState(() {});
  }

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        tanggalAwal = picked;
      } else {
        tanggalAkhir = picked;
      }
    });
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
      maxWidth: 600,
    );

    if (picked == null) return;

    final file = File(picked.path);

    final bytes = await file.readAsBytes();

    buktiBase64 = base64Encode(bytes);

    buktiFile = file;

    setState(() {});
  }

  Future<void> submitPengajuan() async {
    if (tanggalAwal == null || tanggalAkhir == null) {
      return;
    }

    final nip = userData?['nip'];

    await firestore.collection('pengajuan').add({
      'id_pengajuan': DateTime.now().millisecondsSinceEpoch.toString(),
      'nip_pemohon': nip,
      'nip_approver': '',
      'jenis_pengajuan': alasanController.text,
      'tanggal_mulai': tanggalAwal,
      'tanggal_akhir': tanggalAkhir,
      'bukti_lampiran': buktiBase64 ?? '',
      'status_persetujuan': 'Sedang Diproses',
      'tanggal_pengajuan': DateTime.now(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Pengajuan berhasil")));

    context.pop();
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // Widget input(String value) {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[200],
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Text(value),
  //   );
  // }
  Widget inputGrey(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(value),
    );
  }

  Widget inputWhite(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: value == "hh/bb/tttt" ? Colors.grey : Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F8),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                context.pop();
                              },
                              icon: const Icon(Icons.arrow_back_ios_new),
                            ),
                          ),
                          const Text(
                            "Pengajuan Cuti",
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: "Poppins_SemiBold",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage:
                                karyawanData?['foto_profil'] != null &&
                                    karyawanData!['foto_profil']
                                        .toString()
                                        .isNotEmpty
                                ? MemoryImage(
                                    base64Decode(
                                      karyawanData!['foto_profil']
                                          .toString()
                                          .split(',')
                                          .last,
                                    ),
                                  )
                                : null,
                            child:
                                karyawanData?['foto_profil'] == null ||
                                    karyawanData!['foto_profil']
                                        .toString()
                                        .isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 20),
                          Text(
                            karyawanData?['nama'] ?? '',
                            style: const TextStyle(
                              fontFamily: "Poppins_SemiBold",
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      label("ID Karyawan"),
                      inputGrey(userData?['nip'] ?? ''),

                      label("Jabatan"),
                      inputGrey(karyawanData?['role'] ?? ''),

                      label("Tanggal Awal Cuti"),
                      GestureDetector(
                        onTap: () => pickDate(true),
                        child: inputWhite(
                          tanggalAwal == null
                              ? "hh/bb/tttt"
                              : "${tanggalAwal!.day}/${tanggalAwal!.month}/${tanggalAwal!.year}",
                        ),
                      ),

                      label("Tanggal Akhir Cuti"),
                      GestureDetector(
                        onTap: () => pickDate(false),
                        child: inputWhite(
                          tanggalAkhir == null
                              ? "hh/bb/tttt"
                              : "${tanggalAkhir!.day}/${tanggalAkhir!.month}/${tanggalAkhir!.year}",
                        ),
                      ),

                      label("Alasan Cuti"),

                      TextField(
                        controller: alasanController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: "Jelaskan alasan cuti anda disini",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      label("Bukti Cuti"),

                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white),
                          ),
                          child: buktiFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    buktiFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload),
                                    SizedBox(height: 6),
                                    Text("Silakan Unggah Bukti cuti"),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1485C7),
                          ),
                          onPressed: submitPengajuan,
                          child: const Text(
                            "Ajukan Cuti",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
