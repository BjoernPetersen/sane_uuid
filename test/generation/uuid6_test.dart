import 'package:sane_uuid/src/generation.dart';
import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('UUIDv6 generation', () {
    test('random node ID is stable', () {
      final uuid = Uuid.v6();
      final uuid2 = Uuid.v6();
      expect(uuid, isNot(uuid2));
      expect(uuid.node, uuid2.node);
    });

    group('using specific node ID', () {
      test('that is too long', () {
        // 49 bit long
        final nodeId = 0x1000000000000;
        expect(() => Uuid.v6(nodeId: nodeId), throwsArgumentError);
      });

      test('with leading zero', () {
        // 47 bit long
        final nodeId = 0x010000000000;
        final uuid = Uuid.v6(nodeId: nodeId);
        expect(uuid.node, nodeId);
        expect(uuid.toString(), endsWith('-010000000000'));
      });

      test('with exactly 48 bit', () {
        // 48 bit long
        final nodeId = 0xF123456789AB;
        final uuid = Uuid.v6(nodeId: nodeId);
        expect(uuid.node, nodeId);
        expect(uuid.toString(), endsWith('-f123456789ab'));
      });
    });

    group('generator', () {
      test('changes clock sequence if clock drifts backward', () async {
        final time = DateTime.now();
        await Future.delayed(const Duration(seconds: 1));
        final laterTime = DateTime.now();
        final uuid = Uuid.fromBytes(
          Uuid6Generator().generate(time: laterTime, nodeId: 0),
        );
        final uuid2 = Uuid.fromBytes(
          Uuid6Generator().generate(time: time, nodeId: 0),
        );

        expect(uuid, isNot(uuid2));
        expect(uuid.node, uuid2.node);
        expect(uuid.clockSequence, isNot(uuid2.clockSequence));
      });

      test('matches reference', () async {
        final time = DateTime.utc(2022, 2, 22, 19, 22, 22, 0, 0);
        final generator = Uuid6Generator();
        generator.setClockSequence(0x33C8);

        final uuid = Uuid.fromBytes(
          generator.generate(time: time, nodeId: 0x9F6BDECED846),
        );

        // Test vector from RFC 9562
        final reference = Uuid.fromString(
          '1EC9414C-232A-6B00-B3C8-9F6BDECED846',
        );
        expect(uuid, reference);
        expect(uuid.parsedTime, time);
      });
    });
  });
}
