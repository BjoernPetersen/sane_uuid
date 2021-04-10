import 'dart:math';
import 'dart:typed_data';

import 'package:sane_uuid/src/late.dart';
import 'package:sane_uuid/src/uuid_builder.dart';

class Uuid1Generator {
  static final _random = Late(() => Random.secure());
  static DateTime? _lastTime;
  static int? _clockSequence;
  static int? _node;

  int _generateClockSequence() {
    final random = _random.value;
    // 14-bit number
    return random.nextInt(0x3FFF);
  }

  int _createTimestamp(DateTime time) {
    final referenceTime = DateTime.utc(1582, 10, 15);
    final difference = time.difference(referenceTime);
    // We need 100's of nanoseconds
    return difference.inMicroseconds * 10;
  }

  int _updateClockSequence(DateTime time) {
    final lastTime = _lastTime;
    _lastTime = time;
    if (lastTime != null && lastTime.isAfter(time)) {
      return _clockSequence = _generateClockSequence();
    } else {
      return _clockSequence ??= _generateClockSequence();
    }
  }

  int _generateNode() {
    final random = _random.value;
    // 48-bit random value (Random only support 32-bit generation)
    final value = (random.nextInt(0xFFFF) << 32) + random.nextInt(0xFFFFFFFF);
    // Set the msb to indicate a multi-cast address to avoid collisions
    return value | 0x800000000000;
  }

  int _getNode() {
    return _node ??= _generateNode();
  }

  ByteBuffer generate({DateTime? time, int? nodeId}) {
    final utcTime = (time ?? DateTime.now()).toUtc();
    final clockSequence = _updateClockSequence(utcTime);
    final timestamp = _createTimestamp(utcTime);

    if (nodeId != null && nodeId != (nodeId & 0xFFFFFFFFFFFF)) {
      throw ArgumentError.value(
        nodeId,
        'nodeId',
        'nodeId must not be larger than 48-bit',
      );
    }
    final node = nodeId ?? _getNode();

    final builder = UuidBuilder();
    builder.setTimeAndVersion(timestamp, 1);
    builder.setClockSequenceAndVariant(clockSequence);
    builder.setNode(node);
    return builder.buffer;
  }
}

class Uuid4Generator {
  static final _fallbackRandom = Late(() => Random.secure());
  final Random _random;

  Uuid4Generator(Random? random) : _random = random ?? _fallbackRandom.value;

  int _generate60BitInt() {
    return (_random.nextInt(0xFFFFFFF) << 32) + _random.nextInt(0xFFFFFFFF);
  }

  int _generate48BitInt() {
    return (_random.nextInt(0xFFFF) << 32) + _random.nextInt(0xFFFFFFFF);
  }

  ByteBuffer generate() {
    final builder = UuidBuilder();
    builder.setTimeAndVersion(_generate60BitInt(), 4);
    builder.setClockSequenceAndVariant(_random.nextInt(0x3FFF));
    builder.setNode(_generate48BitInt());
    return builder.buffer;
  }
}
