import 'dart:math';

import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('UUIDv4 generation', () {
    for (final (name, random) in [
      ('null', null),
      ('insecure', Random()),
      ('secure', Random.secure())
    ]) {
      test('with $name random', () {
        final uuid = Uuid.v4(random: random);
        expect(
          uuid.version,
          4,
          reason: 'indicating a wrong UUID version',
        );
        expect(
          uuid.clockSequenceHighAndReserved >> 6,
          2,
          reason: 'which should be the reserved bits specified in the RFC',
        );
        expect(
          () => uuid.bytes.asUint8List()[0] = 0,
          throwsUnsupportedError,
          reason:
              'The exception should be thrown because Uuid objects should be immutable',
        );
      });
    }
  });
}
