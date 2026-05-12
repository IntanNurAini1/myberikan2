class KehadiranModel {
  final String idKehadiran;
  final String nip;
  final DateTime tanggalKehadiran;
  final String status;

  KehadiranModel({
    required this.idKehadiran,
    required this.nip,
    required this.tanggalKehadiran,
    required this.status,
  });

  factory KehadiranModel.fromMap(
    Map<String, dynamic> data,
  ) {
    return KehadiranModel(
      idKehadiran:
          data['id_kehadiran'] ?? '',
      nip: data['nip'] ?? '',
      tanggalKehadiran:
          data['tanggal_kehadiran']
              .toDate(),
      status: data['status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_kehadiran': idKehadiran,
      'nip': nip,
      'tanggal_kehadiran':
          tanggalKehadiran,
      'status': status,
    };
  }
}