import 'package:flutter_test/flutter_test.dart';
import 'package:myberikan/controllers/absensi_controller.dart';

void main() {
  group('Unit Test getStatusByJam()', () {

    test('06:00 menghasilkan HADIR', () {
      expect(
        AbsensiController.getStatusByJam(
          DateTime(2026, 6, 18, 6, 0),
        ),
        'HADIR',
      );
    });

    test('08:00 menghasilkan HADIR', () {
      expect(
        AbsensiController.getStatusByJam(
          DateTime(2026, 6, 18, 8, 0),
        ),
        'HADIR',
      );
    });

    test('08:01 menghasilkan TERLAMBAT', () {
      expect(
        AbsensiController.getStatusByJam(
          DateTime(2026, 6, 18, 8, 1),
        ),
        'TERLAMBAT',
      );
    });

    test('09:00 menghasilkan TERLAMBAT', () {
      expect(
        AbsensiController.getStatusByJam(
          DateTime(2026, 6, 18, 9, 0),
        ),
        'TERLAMBAT',
      );
    });

    test('05:59 menghasilkan null', () {
      expect(
        AbsensiController.getStatusByJam(
          DateTime(2026, 6, 1, 5, 59),
        ),
        null,
      );
    });

  });
}