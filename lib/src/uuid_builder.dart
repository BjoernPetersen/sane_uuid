import 'dart:typed_data';

import 'package:sane_uuid/src/uuid_base.dart';

const _variant = 2 << 6;

class UuidBuilder {
  final ByteData _bytes;

  UuidBuilder() : _bytes = ByteData(kUuidBytes);

  /// 60-bit timestamp, version between 1 and 5.
  void setTimeAndVersion(int timestamp, int version) {
    if ((timestamp >> 60) != 0) {
      throw ArgumentError.value(timestamp, 'timestamp', 'Too large');
    }
    _bytes.setUint32(0, timestamp & 0xFFFFFFFF);
    _bytes.setUint16(4, (timestamp >> 32) & 0xFFFF);
    _bytes.setUint16(6, (timestamp >> 48) | (version << 12));
  }

  /// 14-bit clock sequence.
  void setClockSequenceAndVariant(int clockSequence) {
    if ((clockSequence >> 14) != 0) {
      throw ArgumentError.value(clockSequence, 'clockSequence', 'Too large');
    }
    _bytes.setUint8(8, (clockSequence >> 8) | _variant);
    _bytes.setUint8(9, clockSequence & 0xFF);
  }

  /// 48-bit node.
  void setNode(int node) {
    _bytes.setUint16(10, node >> 32);
    _bytes.setUint32(12, node & 0xFFFFFFFF);
  }

  ByteBuffer get buffer => _bytes.buffer;
}
