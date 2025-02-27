import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('valid values', () {
    test('max uuid can be parsed', () {
      const maxUuid = 'ffffffff-ffff-ffff-ffff-ffffffffffff';
      final parsed = Uuid.fromString(maxUuid);
      expect(parsed.toString(), maxUuid);
    });

    test('max uuid can be parsed in upper case', () {
      const maxUuid = 'ffffffff-ffff-ffff-ffff-ffffffffffff';
      const maxUuidUpper = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF';
      final parsedLower = Uuid.fromString(maxUuid);
      final parsedUpper = Uuid.fromString(maxUuidUpper);
      expect(parsedUpper, parsedLower);
    });

    const testUuidString = '123f567a-1234-5678-1e34-b67812cd5678';
    final testUuid = Uuid.fromString(testUuidString);
    for (final format in [
      '123f567a-1234-5678-1e34-b67812cd5678',
      '123f567a123456781e34b67812cd5678',
      'urn:uuid:123f567a123456781e34b67812cd5678',
      'urn:uuid:123f567a-1234-5678-1e34-b67812cd5678',
      'uRn:uUId:123f567A-1234-5678-1e34-b67812cd5678',
    ]) {
      test('$format == $testUuidString', () {
        final uuid = Uuid.fromString(format);
        expect(uuid, equals(testUuid));
        expect(uuid.toString(), equals(testUuidString));
        expect(uuid.hashCode, equals(testUuid.hashCode));
      });
    }

    test('are unmodifiable', () {
      expect(() => testUuid.bytes[0] = 0, throwsUnsupportedError);
    });
  });

  group('invalid values', () {
    test('empty/blank values', () {
      expect(() => Uuid.fromString(''), throwsFormatException);
      expect(() => Uuid.fromString(' '), throwsFormatException);
      expect(() => Uuid.fromString('\n'), throwsFormatException);
    });
    test('surrounding whitespace', () {
      expect(
        () => Uuid.fromString('123f567a-1234-5678-1e34-b67812cd5678 '),
        throwsFormatException,
      );
      expect(
        () => Uuid.fromString(' 123f567a-1234-5678-1e34-b67812cd5678'),
        throwsFormatException,
      );
      expect(
        () => Uuid.fromString('123f567a-1234-5678-1e34-b67812cd5678\n'),
        throwsFormatException,
      );
    });
    test('long value', () {
      expect(
        () => Uuid.fromString('123f567a-1234-5678-1e34-b67812cd56781'),
        throwsFormatException,
      );
    });
    test('short value', () {
      expect(
        () => Uuid.fromString('123f567a-1234-5678-1e34-b67812cd781'),
        throwsFormatException,
      );
    });
    test('misplaced hyphen', () {
      expect(
        () => Uuid.fromString('123f-567a1234-5678-1e34-b67812cd5678'),
        throwsFormatException,
      );
    });
    test('non-hex letters', () {
      expect(
        () => Uuid.fromString('g23f567a-1234-5678-1e34-b67812cd5678'),
        throwsFormatException,
      );
    });
  });
}
