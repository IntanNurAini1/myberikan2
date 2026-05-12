class PengajuanModel {
  final String idPengajuan;
  final String nipPemohon;
  final String nipApprover;
  final String jenisPengajuan;
  final DateTime tanggalMulai;
  final DateTime tanggalAkhir;
  final String buktiLampiran;
  final String statusPersetujuan;
  final DateTime tanggalPengajuan;

  PengajuanModel({
    required this.idPengajuan,
    required this.nipPemohon,
    required this.nipApprover,
    required this.jenisPengajuan,
    required this.tanggalMulai,
    required this.tanggalAkhir,
    required this.buktiLampiran,
    required this.statusPersetujuan,
    required this.tanggalPengajuan,
  });

  factory PengajuanModel.fromMap(
    Map<String, dynamic> data,
  ) {
    return PengajuanModel(
      idPengajuan:
          data['id_pengajuan'] ?? '',
      nipPemohon:
          data['nip_pemohon'] ?? '',
      nipApprover:
          data['nip_approver'] ?? '',
      jenisPengajuan:
          data['jenis_pengajuan'] ?? '',
      tanggalMulai:
          data['tanggal_mulai']
              .toDate(),
      tanggalAkhir:
          data['tanggal_akhir']
              .toDate(),
      buktiLampiran:
          data['bukti_lampiran'] ?? '',
      statusPersetujuan:
          data['status_persetujuan'] ??
              '',
      tanggalPengajuan:
          data['tanggal_pengajuan']
              .toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_pengajuan': idPengajuan,
      'nip_pemohon': nipPemohon,
      'nip_approver': nipApprover,
      'jenis_pengajuan':
          jenisPengajuan,
      'tanggal_mulai':
          tanggalMulai,
      'tanggal_akhir':
          tanggalAkhir,
      'bukti_lampiran':
          buktiLampiran,
      'status_persetujuan':
          statusPersetujuan,
      'tanggal_pengajuan':
          tanggalPengajuan,
    };
  }
}