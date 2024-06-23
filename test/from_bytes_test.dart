import 'dart:typed_data';

import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('Uuid from bytes', () {
    const testUuidString = '123f567a-1234-5678-1e34-b67812cd5678';
    final testUuid = Uuid.fromString(testUuidString);

    test('are parsed correctly', () {
      final uuid = Uuid.fromBytes(testUuid.bytes);
      expect(
        uuid,
        testUuid,
      );
    });

    test('are defensively copied', () {
      final bytes = Uint8List.fromList(testUuid.bytes);
      final uuid = Uuid.fromBytes(bytes);
      bytes[0] = 0;
      expect(uuid, testUuid);
      expect(Uuid.fromBytes(bytes), isNot(equals(testUuid)));
    });

    test('are unmodifiable', () {
      final uuid = Uuid.fromBytes(testUuid.bytes);
      expect(
        () => uuid.bytes[0] = 0,
        throwsUnsupportedError,
      );
    });

    test('respect views', () {
      final longBytes = Uint8List(testUuid.bytes.lengthInBytes + 1);
      longBytes.setAll(1, testUuid.bytes);
      final uuid = Uuid.fromBytes(Uint8List.sublistView(longBytes, 1));
      expect(uuid, testUuid);
    });
  });

  group('invalid values', () {
    const testUuidString = '123f567a-1234-5678-1e34-b67812cd5678';
    final testUuid = Uuid.fromString(testUuidString);

    test('empty buffer', () {
      expect(() => Uuid.fromBytes(Uint8List(0)), throwsArgumentError);
    });

    test('bytes too short', () {
      expect(
        () => Uuid.fromBytes(testUuid.bytes.sublist(1)),
        throwsArgumentError,
      );
    });

    test('bytes too long', () {
      final bytes = Uint8List(testUuid.bytes.lengthInBytes + 1);
      bytes.setAll(0, testUuid.bytes);
      expect(
        () => Uuid.fromBytes(bytes),
        throwsArgumentError,
      );
    });
  });
}
