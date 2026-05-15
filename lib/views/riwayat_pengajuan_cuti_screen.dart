// import 'package:flutter/material.dart';
// import 'package:myberikan/extension/navigation.dart';
// import 'package:myberikan/views/ajukan_cuti_screen.dart';

// class RiwayatPengajuanScreen extends StatefulWidget {
//   const RiwayatPengajuanScreen({super.key});

//   @override
//   State<RiwayatPengajuanScreen> createState() => _RiwayatPengajuanScreenState();
// }

// class _RiwayatPengajuanScreenState extends State<RiwayatPengajuanScreen> {
//   @override
//   final List<String> keterangan = <String>[
//     'Izin Sakit',
//     'Izin Nikahan',
//     'Izin Liburan',
//     'Izin Cuti',
//   ];
//   final List<String> tanggal = <String>[
//     '10/05/2026 - 12/05/2026',
//     '08/10/2026 - 13/10/2026',
//     '12/05/2025 - 17/05/2025',
//     '02/05/2025 - 02/05/2025',
//   ];
//   final List<String> status = <String>[
//     'Sedang Diproses',
//     'Disetujui',
//     'Ditolak',
//     'Disetujui',
//   ];

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
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 // mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 177,
//                     width: 380,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Color(0x1B365D),
//                           offset: Offset(0, 20),
//                           blurRadius: 25,
//                         ),
//                       ],
//                     ),
//                     child: Padding(
//                       padding: EdgeInsets.all(20),
//                       child: Column(
//                         children: [
//                           Text(
//                             "JATAH CUTI",
//                             style: TextStyle(
//                               fontFamily: "Poppins_Medium",
//                               color: Color.fromARGB(255, 100, 116, 139),
//                             ),
//                           ),
//                           Text(
//                             "10/12",
//                             style: TextStyle(
//                               fontFamily: "Poppins_SemiBold",
//                               fontSize: 32,
//                               color: Color.fromARGB(255, 20, 133, 199),
//                             ),
//                           ),
//                           Text(
//                             "Sisa jatah cuti yang dimiliki",
//                             style: TextStyle(
//                               fontFamily: "Poppins_Regular",
//                               fontSize: 11,
//                               color: Color.fromARGB(255, 100, 116, 139),
//                             ),
//                           ),
//                           SizedBox(height: 15),
//                           Align(
//                             alignment: Alignment.center,
//                             child: SizedBox(
//                               width: 332,
//                               height: 36,
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Color.fromARGB(
//                                     255,
//                                     20,
//                                     133,
//                                     199,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                 ),
//                                 onPressed: () {
//                                   context.push(const AjukanCutiScreen());
//                                 },
//                                 child: Text(
//                                   "Tambah",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontFamily: "Poppins_SemiBold",
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "Riwayat Ajukan Cuti",
//                   style: TextStyle(fontFamily: "Poppins_Bold"),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 padding: EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: keterangan.length,
//                 itemBuilder: (context, index) {
//                   Color statusColor;

//                   if (status[index] == "Sedang Diproses") {
//                     statusColor = Colors.orange;
//                   } else if (status[index] == "Disetujui") {
//                     statusColor = Colors.green;
//                   } else {
//                     statusColor = Colors.red;
//                   }

//                   return GestureDetector(
//                     onTap: () {
//                       context.push(AjukanCutiScreen());
//                     },
//                     child: Container(
//                       margin: EdgeInsets.only(bottom: 14),
//                       padding: EdgeInsets.all(14),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(18),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black12,
//                             blurRadius: 6,
//                             offset: Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 keterangan[index],
//                                 style: TextStyle(
//                                   fontFamily: "Poppins_SemiBold",
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 tanggal[index],
//                                 style: TextStyle(
//                                   fontFamily: "Poppins_Regular",
//                                   fontSize: 11,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                             ],
//                           ),

//                           Text(
//                             status[index],
//                             style: TextStyle(
//                               fontFamily: "Poppins_Medium",
//                               color: statusColor,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// =======================
// riwayat_pengajuan_screen.dart
// =======================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myberikan/extension/navigation.dart';
import 'package:myberikan/views/ajukan_cuti_screen.dart';

class RiwayatPengajuanScreen extends StatefulWidget {
  const RiwayatPengajuanScreen({super.key});

  @override
  State<RiwayatPengajuanScreen> createState() => _RiwayatPengajuanScreenState();
}

class _RiwayatPengajuanScreenState extends State<RiwayatPengajuanScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;

  bool isLoading = true;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? karyawanData;

  List<Map<String, dynamic>> pengajuanList = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final uid = auth.currentUser!.uid;

      final userDoc = await firestore.collection('users').doc(uid).get();

      userData = userDoc.data();

      final nip = userData?['nip'];

      final karyawanDoc = await firestore.collection('karyawan').doc(nip).get();

      karyawanData = karyawanDoc.data();

      final pengajuanSnapshot = await firestore
          .collection('pengajuan')
          .where('nip_pemohon', isEqualTo: nip)
          .orderBy('tanggal_pengajuan', descending: true)
          .get();

      pengajuanList = pengajuanSnapshot.docs.map((e) => e.data()).toList();

      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading = false;
      setState(() {});
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F8),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
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
                  ),

                  // CARD
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      height: 177,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, 6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              "JATAH CUTI",
                              style: TextStyle(
                                fontFamily: "Poppins_Medium",
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "$sisaCuti/${karyawanData?['jatah_cuti_tahunan'] ?? 12}",
                              style: const TextStyle(
                                fontFamily: "Poppins_SemiBold",
                                fontSize: 32,
                                color: Color(0xFF1485C7),
                              ),
                            ),
                            const Text(
                              "Sisa jatah cuti yang dimiliki",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1485C7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  await context.push(const AjukanCutiScreen());

                                  fetchData();
                                },
                                child: const Text(
                                  "Tambah",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // TITLE
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Riwayat Ajukan Cuti",
                        style: TextStyle(fontFamily: "Poppins_Bold"),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // LIST
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pengajuanList.length,
                      itemBuilder: (context, index) {
                        final item = pengajuanList[index];

                        Color statusColor;

                        if (item['status_persetujuan'] == 'Sedang Diproses') {
                          statusColor = Colors.orange;
                        } else if (item['status_persetujuan'] == 'Disetujui') {
                          statusColor = Colors.green;
                        } else {
                          statusColor = Colors.red;
                        }

                        final start = (item['tanggal_mulai'] as Timestamp)
                            .toDate();

                        final end = (item['tanggal_akhir'] as Timestamp)
                            .toDate();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['jenis_pengajuan'],
                                    style: const TextStyle(
                                      fontFamily: "Poppins_SemiBold",
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}",
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                item['status_persetujuan'],
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
