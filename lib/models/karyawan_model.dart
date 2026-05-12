class KaryawanModel {
  final String nip;
  final String nama;
  final String divisi;
  final String role;
  final int jatahCutiTahunan;
  final String fotoProfil;

  KaryawanModel({
    required this.nip,
    required this.nama,
    required this.divisi,
    required this.role,
    required this.jatahCutiTahunan,
    required this.fotoProfil,
  });

  factory KaryawanModel.fromMap(
    Map<String, dynamic> data,
  ) {
    return KaryawanModel(
      nip: data['nip'] ?? '',
      nama: data['nama'] ?? '',
      divisi: data['divisi'] ?? '',
      role: data['role'] ?? '',
      jatahCutiTahunan:
          data['jatah_cuti_tahunan'] ?? 0,
      fotoProfil:
          data['foto_profil'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nip': nip,
      'nama': nama,
      'divisi': divisi,
      'role': role,
      'jatah_cuti_tahunan':
          jatahCutiTahunan,
      'foto_profil': fotoProfil,
    };
  }
}