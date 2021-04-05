import 'dart:math';
import 'dart:typed_data';

import 'package:sane_uuid/src/late.dart';
import 'package:sane_uuid/src/uuid_base.dart';

const _variant = 2 << 6;

class Uuid4Generator {
  static const _version = 4 << 4;
  static final _fallbackRandom = Late(() => Random.secure());
  final Random _random;

  Uuid4Generator(Random? random) : _random = random ?? _fallbackRandom.value;

  ByteBuffer generate() {
    final builder = BytesBuilder(copy: false);
    for (var byteIndex = 0; byteIndex < kUuidBytes; byteIndex += 1) {
      var byte = _random.nextInt(255);
      if (byteIndex == 6) {
        // Insert version
        byte = (byte & 0x0F) + _version;
      } else if (byteIndex == 8) {
        // Set reserved bits
        byte = (byte & 0x3F) + _variant;
      }
      builder.addByte(byte);
    }
    return builder.takeBytes().buffer;
  }
}

class Uuid1Generator {
  static const _version = 1 << 12;
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

    final builder = ByteData(16);
    builder.setUint32(0, timestamp & 0xFFFFFFFF);
    builder.setUint16(4, (timestamp >> 32) & 0xFFFF);
    builder.setUint16(6, (timestamp >> 48) + _version);

    builder.setUint8(8, (clockSequence >> 8) + _variant);
    builder.setUint8(9, clockSequence & 0xFF);

    builder.setUint16(10, node >> 32);
    builder.setUint32(12, node & 0xFFFFFFFF);
    return builder.buffer;
  }
}
