import 'dart:math';

import 'package:sane_uuid/src/generation.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

class _ScriptedRandom implements Random {
  final List<int> _bytes;
  int _index = 0;

  _ScriptedRandom(this._bytes);

  @override
  int nextInt(int max) {
    if (max != 256) {
      throw UnimplementedError('Only byte-sized values are scripted');
    }
    return _bytes[_index++];
  }

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  double nextDouble() => throw UnimplementedError();
}

void main() {
  group('UUIDv7 generation', () {
    for (final (name, random) in [
      ('null', null),
      ('insecure', Random()),
      ('secure', Random.secure()),
    ]) {
      test('with $name random', () {
        final uuid = Uuid.v7(random: random);
        expect(uuid.version, 7, reason: 'indicating a wrong UUID version');
        expect(
          uuid.clockSequenceHighAndReserved >> 6,
          2,
          reason: 'which should be the reserved bits specified in the RFC',
        );
        expect(uuid.variant, UuidVariant.rfc4122);
        expect(
          () => uuid.bytes[0] = 0,
          throwsUnsupportedError,
          reason:
              'The exception should be thrown because Uuid objects should be immutable',
        );
      });
    }

    test('encodes the current time within a few seconds', () {
      final before = DateTime.now().toUtc();
      final uuid = Uuid.v7();
      final after = DateTime.now().toUtc();

      final parsed = uuid.parsedTime;
      expect(
        parsed.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        parsed.isAfter(after.add(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test('embedded timestamp advances across calls', () async {
      final first = Uuid.v7();
      await Future.delayed(const Duration(milliseconds: 5));
      final second = Uuid.v7();
      expect(second.parsedTime.isAfter(first.parsedTime), isTrue);
    });

    group('generator', () {
      test('rejects negative timestamps', () {
        final time = DateTime.fromMillisecondsSinceEpoch(-1, isUtc: true);
        expect(
          () => Uuid7Generator().generate(time: time),
          throwsArgumentError,
        );
      });

      test('matches reference', () {
        // Test vector from RFC 9562, Appendix A.6:
        // 017F22E2-79B0-7CC3-98C4-DC0C0C07398F
        // unix_ts_ms = 0x17F22E279B0 = 1645557742000
        // = 2022-02-22 19:22:22 UTC
        final time = DateTime.fromMillisecondsSinceEpoch(
          0x17F22E279B0,
          isUtc: true,
        );
        // Bytes the generator must read for indices 6..15 to reproduce the
        // reference output. Bits overridden by the version (byte 6 high
        // nibble) and variant (byte 8 top two bits) can be anything; we
        // pick values whose unmasked bits match the reference exactly.
        final scripted = _ScriptedRandom([
          0x0C, // byte 6: low nibble -> rand_a high nibble (0xC)
          0xC3, // byte 7: rand_a low byte
          0x18, // byte 8: low 6 bits -> rand_b high 6 bits (0x18)
          0xC4, 0xDC, 0x0C, 0x0C, 0x07, 0x39, 0x8F,
        ]);

        final uuid = Uuid.fromBytes(
          Uuid7Generator(scripted).generate(time: time),
        );

        final reference = Uuid.fromString(
          '017F22E2-79B0-7CC3-98C4-DC0C0C07398F',
        );
        expect(uuid, reference);
        expect(uuid.parsedTime, time);
      });
    });
  });
}
