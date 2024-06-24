import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:sane_uuid/src/late.dart';
import 'package:sane_uuid/src/uuid_base.dart';

const _variant = 2 << 6;

sealed class GregorianUuidGenerator {
  static final _random = Late(() => Random.secure());
  DateTime? _lastTime;
  int? _clockSequence;
  int? _node;

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

  @nonVirtual
  @visibleForTesting
  void setClockSequence([int value = 0]) {
    _clockSequence = value;
    _lastTime = DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _setTimestampAndVersion(ByteData builder, int timestamp);

  @nonVirtual
  Uint8List generate({DateTime? time, int? nodeId}) {
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
    _setTimestampAndVersion(builder, timestamp);

    builder.setUint8(8, (clockSequence >> 8) + _variant);
    builder.setUint8(9, clockSequence & 0xFF);

    builder.setUint16(10, node >> 32);
    builder.setUint32(12, node & 0xFFFFFFFF);
    return builder.buffer.asUint8List();
  }
}

final class Uuid1Generator extends GregorianUuidGenerator {
  static const _version = 1 << 12;
  static final _instance = Late(() => Uuid1Generator._());

  Uuid1Generator._();

  factory Uuid1Generator() => _instance.value;

  @override
  void _setTimestampAndVersion(ByteData builder, int timestamp) {
    builder.setUint32(0, timestamp & 0xFFFFFFFF);
    builder.setUint16(4, (timestamp >> 32) & 0xFFFF);
    builder.setUint16(6, (timestamp >> 48) + _version);
  }
}

final class Uuid6Generator extends GregorianUuidGenerator {
  static const _version = 6 << 12;
  static final _instance = Late(() => Uuid6Generator._());

  Uuid6Generator._();

  factory Uuid6Generator() => _instance.value;

  @override
  void _setTimestampAndVersion(ByteData builder, int timestamp) {
    builder.setUint32(0, timestamp >> 28);
    builder.setUint16(4, (timestamp >> 12) & 0xFFFF);
    builder.setUint16(6, (timestamp & 0xFFF) + _version);
  }
}

/// Builds UUID bytes by reading from [getByte] and multiplexing the variant
/// and [version] in the appropriate places.
Uint8List _buildBytes({
  required int version,
  required int Function(int index) getByte,
}) {
  final builder = BytesBuilder(copy: false);
  for (var byteIndex = 0; byteIndex < kUuidBytes; byteIndex += 1) {
    var byte = getByte(byteIndex);
    if (byteIndex == 6) {
      // Insert version
      byte = (byte & 0x0F) + (version << 4);
    } else if (byteIndex == 8) {
      // Set reserved bits
      byte = (byte & 0x3F) + _variant;
    }
    builder.addByte(byte);
  }
  return builder.takeBytes();
}

final class Uuid4Generator {
  static final _fallbackRandom = Late(() => Random.secure());
  final Random _random;

  Uuid4Generator(Random? random) : _random = random ?? _fallbackRandom.value;

  Uint8List generate() {
    return _buildBytes(version: 4, getByte: (_) => _random.nextInt(255));
  }
}

final class Uuid5Generator {
  ByteBuffer _createDigest(Uuid namespace, String name) {
    final concatenated = <int>[];
    concatenated.addAll(namespace.bytes);
    concatenated.addAll(utf8.encode(name));
    final digest = sha1.convert(concatenated);
    return Uint8List.fromList(digest.bytes).buffer;
  }

  Uint8List generate({required Uuid namespace, required String name}) {
    final digest = _createDigest(namespace, name).asByteData(0, kUuidBytes);
    return _buildBytes(version: 5, getByte: digest.getUint8);
  }
}
