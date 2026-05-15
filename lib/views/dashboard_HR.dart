import 'package:flutter/material.dart';
// import 'package:myberikan/views/pengajuan_cuti_screen.dart';
import 'package:myberikan/views/data_absensi_screen.dart';
import 'package:myberikan/views/riwayat_pengajuan_cuti_screen.dart';
import 'package:myberikan/views/data_karyawan_view.dart';

void main() {
  runApp(const DashboardHr());
}

class DashboardHr extends StatefulWidget {
  const DashboardHr({super.key});

  @override
  State<DashboardHr> createState() => _DashboardHrState();
}

class _DashboardHrState extends State<DashboardHr> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HR Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B7FD4)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HRDashboardScreen(),
    );
  }
}

class HRDashboardScreen extends StatelessWidget {
  const HRDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Fitur Aplikasi'),
              const SizedBox(height: 12),
              _buildFiturAplikasi(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Riwayat Aktivitas'),
              const SizedBox(height: 12),
              _buildActivityList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFD6E8F7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.person, color: Color(0xFF2B7FD4), size: 30),
        ),
        const SizedBox(width: 12),
        // Greeting
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang!',
              style: TextStyle(fontSize: 12, color: Color(0xFF7A8FA6)),
            ),
            Text(
              'Budi Santoso',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2D45),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Icons
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF2B7FD4),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.menu, color: Color(0xFF2B7FD4)),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role + badge
          Row(
            children: [
              const Text(
                'HR Manager',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2D45),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AKTIF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'ID: 8829-PRT-2024',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A8FA6)),
          ),
          const SizedBox(height: 14),
          // Shift + Kehadiran Row
          Row(
            children: [
              // Shift pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Color(0xFF2B7FD4)),
                    SizedBox(width: 6),
                    Text(
                      'Shift Pagi • 08:00 - 17:00',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2B7FD4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Kehadiran
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'KEHADIRAN',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7A8FA6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(
                    '20/22 Hari',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B7FD4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Absen Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B7FD4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Absen Sekarang',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A2D45),
      ),
    );
  }

  Widget _buildFiturAplikasi(BuildContext context) {
    final features = [
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Pengajuan Cuti',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiwayatPengajuanScreen()),
        ),
      },
      {
        'icon': Icons.event_available_outlined,
        'label': 'Verifikasi Cuti',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiwayatPengajuanScreen()),
        ),
      },
      {
        'icon': Icons.bar_chart_outlined,
        'label': 'Data Absensi',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DataAbsensiScreen()),
        ),
      },
      {
        'icon': Icons.date_range_outlined,
        'label': 'Data Cuti',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiwayatPengajuanScreen()),
        ),
      },
      {
        'icon': Icons.people_outline,
        'label': 'Data Karyawan',
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DataKaryawanView()),
        ),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 52,
        runSpacing: 16,
        children: features.map((f) {
          return SizedBox(
            width: 72,
            child: InkWell(
              onTap: f['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF3F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      f['icon'] as IconData,
                      color: const Color(0xFF2B7FD4),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    f['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1A2D45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityList() {
    final activities = [
      {'title': 'Absensi Berhasil', 'subtitle': 'Hari ini • 07:58 WIB'},
      {'title': 'Absensi Berhasil', 'subtitle': 'Kemarin • 07:28 WIB'},
      {'title': 'Absensi Berhasil', 'subtitle': '9 Mei • 08:00 WIB'},
    ];

    return Column(
      children: activities.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.login,
                  color: Color(0xFF2B7FD4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['title']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2D45),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a['subtitle']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2B7FD4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}