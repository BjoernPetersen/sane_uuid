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

  Uuid generate() {
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
    return Uuid.fromBytes(builder.takeBytes().buffer);
  }
}
