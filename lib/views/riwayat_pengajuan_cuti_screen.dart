import 'package:flutter/material.dart';
import 'package:myberikan/extension/navigation.dart';
import 'package:myberikan/views/ajukan_cuti_screen.dart';

class RiwayatPengajuanScreen extends StatefulWidget {
  const RiwayatPengajuanScreen({super.key});

  @override
  State<RiwayatPengajuanScreen> createState() => _RiwayatPengajuanScreenState();
}

class _RiwayatPengajuanScreenState extends State<RiwayatPengajuanScreen> {
  @override
  final List<String> keterangan = <String>[
    'Izin Sakit',
    'Izin Nikahan',
    'Izin Liburan',
    'Izin Cuti',
  ];
  final List<String> tanggal = <String>[
    '10/05/2026 - 12/05/2026',
    '08/10/2026 - 13/10/2026',
    '12/05/2025 - 17/05/2025',
    '02/05/2025 - 02/05/2025',
  ];
  final List<String> status = <String>[
    'Sedang Diproses',
    'Disetujui',
    'Ditolak',
    'Disetujui',
  ];

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(onPressed: (){context.pop();}, icon: Icon(Icons.arrow_back_ios_new)),
                  ),
                  Text(
                    "Pengajuan Cuti",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: "Poppins_SemiBold",
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 177,
                    width: 380,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1B365D),
                          offset: Offset(0, 20),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            "JATAH CUTI",
                            style: TextStyle(
                              fontFamily: "Poppins_Medium",
                              color: Color.fromARGB(255, 100, 116, 139),
                            ),
                          ),
                          Text(
                            "10/12",
                            style: TextStyle(
                              fontFamily: "Poppins_SemiBold",
                              fontSize: 32,
                              color: Color.fromARGB(255, 20, 133, 199),
                            ),
                          ),
                          Text(
                            "Sisa jatah cuti yang dimiliki",
                            style: TextStyle(
                              fontFamily: "Poppins_Regular",
                              fontSize: 11,
                              color: Color.fromARGB(255, 100, 116, 139),
                            ),
                          ),
                          SizedBox(height: 15),
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 332,
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    20,
                                    133,
                                    199,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {},
                                child: Text(
                                  "Tambah",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: "Poppins_SemiBold",
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Riwayat Ajukan Cuti",
                  style: TextStyle(fontFamily: "Poppins_Bold"),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: keterangan.length,
                itemBuilder: (context, index) {
                  Color statusColor;

                  if (status[index] == "Sedang Diproses") {
                    statusColor = Colors.orange;
                  } else if (status[index] == "Disetujui") {
                    statusColor = Colors.green;
                  } else {
                    statusColor = Colors.red;
                  }

                  return GestureDetector(
                    onTap: () {
                      context.push(AjukanCutiScreen());
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 14),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
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
                                keterangan[index],
                                style: TextStyle(
                                  fontFamily: "Poppins_SemiBold",
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                tanggal[index],
                                style: TextStyle(
                                  fontFamily: "Poppins_Regular",
                                  fontSize: 11,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),

                          Text(
                            status[index],
                            style: TextStyle(
                              fontFamily: "Poppins_Medium",
                              color: statusColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
