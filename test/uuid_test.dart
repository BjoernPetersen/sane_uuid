import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('example UUID', () {
    late Uuid uuid;

    setUp(() {
      uuid = Uuid.fromString('250f64f4-5de9-4ed9-8ad7-000004ae597d');
    });

    test('is version 4', () {
      expect(uuid.version, 4);
    });
    test('toString is correct', () {
      expect(uuid.toString(), '250f64f4-5de9-4ed9-8ad7-000004ae597d');
    });
  });

  group('v4 generation', () {
    late Uuid uuid;

    setUp(() {
      uuid = Uuid.v4();
    });

    test('is version 4', () {
      expect(uuid.version, 4);
    });
    test('has reserved bits', () {
      expect(uuid.clockSequenceHighAndReserved >> 6, 2);
    });
  });
}
