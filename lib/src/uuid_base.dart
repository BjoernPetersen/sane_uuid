import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sane_uuid/src/generation.dart';
import 'package:sane_uuid/src/hex.dart';

/// The length of a UUID in bytes.
const kUuidBytes = 16;
final RegExp _uuidPattern = RegExp(
  r'^(?:urn:uuid:)?([0-9a-f]{8})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{4})-?([0-9a-f]{12})$',
  caseSensitive: false,
);

enum UuidVariant {
  /// Reserved, NCS backward compatibility.
  ncsReserved,

  /// The variant specified by RFC 4122.
  rfc4122,

  ///  Reserved, Microsoft Corporation backward compatibility.
  microsoftReserved,

  /// Reserved for future definition.
  futureReserved,
}

/// Represents a RFC 4122 UUID. More generally, any 128-bit byte sequence can be
/// represented by this class, but the semantics for the fields described in the
/// may not apply for other variants.
///
/// Instances follow the rules for equivalence and ordering laid out by the RFC.
@immutable
class Uuid implements Comparable<Uuid> {
  /// The raw bytes of this UUID. The returned ByteBuffer is unmodifiable and
  /// contains exactly 16 bytes.
  final ByteBuffer bytes;

  ByteData get _byteData => bytes.asByteData();

  /// The low field of the timestamp, i.e. octets 0-3.
  /// This field will be random for v4 UUIDs.
  ///
  /// Note that the full timestamp can be retrieved using [time].
  int get timeLow => _byteData.getUint32(0);

  /// The mid field of the timestamp, i.e. octets 4-5.
  /// This field will be random for v4 UUIDs.
  ///
  /// Note that the full timestamp can be retrieved using [time].
  int get timeMid => _byteData.getUint16(4);

  /// The high field of the timestamp multiplexed with the version number,
  /// i.e. octets 6-7. For v4 UUIDs, the timestamp will be random, but the
  /// version bits will be 4 (`0b0100`).
  ///
  /// Note that the full timestamp can be retrieved using [time].
  int get timeHighAndVersion => _byteData.getUint16(6);

  /// The high field of the timestamp without the version number that was
  /// originally multiplexed into [timeHighAndVersion].
  ///
  /// Note that the full timestamp can be retrieved using [time].
  int get timeHigh => timeHighAndVersion & 0x0FFF;

  /// The full "timestamp" of the UUID.
  ///
  /// ## Definition from RFC 4122
  ///
  /// The timestamp is a 60-bit value.  For UUID version 1, this is
  /// represented by Coordinated Universal Time (UTC) as a count of 100-
  /// nanosecond intervals since 00:00:00.00, 15 October 1582 (the date of
  /// Gregorian reform to the Christian calendar).
  ///
  /// For systems that do not have UTC available, but do have the local
  /// time, they may use that instead of UTC, as long as they do so
  /// consistently throughout the system.  However, this is not recommended
  /// since generating the UTC from local time only needs a time zone
  /// offset.
  ///
  /// For UUID version 3 or 5, the timestamp is a 60-bit value constructed
  /// from a name as described in
  /// [Section 4.3](https://tools.ietf.org/html/rfc4122#section-4.3).
  ///
  /// For UUID version 4, the timestamp is a randomly or pseudo-randomly
  /// generated 60-bit value, as described in
  /// [Section 4.4](https://tools.ietf.org/html/rfc4122#section-4.4).
  int get time => timeHigh << 48 + timeMid << 32 + timeLow;

  /// The version that was originally multiplexed in [timeHighAndVersion].
  /// If this UUID conforms to the structure laid out in RFC 4122, this will
  /// be a number between 1 (inclusive) and 5 (inclusive).
  int get version => timeHighAndVersion >> 12;

  /// The high field of the clock sequence multiplexed with the variant.
  int get clockSequenceHighAndReserved => _byteData.getUint8(8);

  /// The high field of the clock sequence without the [variant].
  ///
  /// Note that this is only correct for UUIDs of the variant laid out in
  /// RFC 4122 because others may use fewer or more variant bits.
  int get clockSequenceHigh => clockSequenceHighAndReserved & 0x3F;

  /// The UUID variant which determines the layout of the UUID.
  ///
  /// Note that only the [UuidVariant.rfc4122] variant is properly represented
  /// by this class. Other variants are treated as if they were RFC 4122 UUIDs.
  UuidVariant get variant {
    final variantBits = clockSequenceHighAndReserved >> 13;
    if (variantBits < 4) {
      return UuidVariant.ncsReserved;
    } else if (variantBits == 7) {
      return UuidVariant.futureReserved;
    } else if (variantBits == 6) {
      return UuidVariant.microsoftReserved;
    } else {
      return UuidVariant.rfc4122;
    }
  }

  /// The low field of the clock sequence.
  int get clockSequenceLow => _byteData.getUint8(9);

  /// The combined clock sequence. Note that the semantics of this value differ
  /// between UUID versions. For v4 UUIDs in particular, this is a random value.
  int get clockSequence => clockSequenceHigh << 8 + clockSequenceLow;

  /// The spatially unique node identifier.
  ///
  /// ## Definition from RFC 4122
  ///
  /// For UUID version 1, the node field consists of an IEEE 802 MAC
  /// address, usually the host address.  For systems with multiple IEEE
  /// 802 addresses, any available one can be used.  The lowest addressed
  /// octet (octet number 10) contains the global/local bit and the
  /// unicast/multicast bit, and is the first octet of the address
  /// transmitted on an 802.3 LAN.
  ///
  /// For systems with no IEEE address, a randomly or pseudo-randomly
  /// generated value may be used; see
  /// [Section 4.5](https://tools.ietf.org/html/rfc4122#section-4.5).
  /// The multicast bit must be set in such addresses, in order that they will
  /// never conflict with addresses obtained from network cards.

  /// For UUID version 3 or 5, the node field is a 48-bit value constructed
  /// from a name as described in
  /// [Section 4.3](https://tools.ietf.org/html/rfc4122#section-4.3).
  ///
  /// For UUID version 4, the node field is a randomly or pseudo-randomly
  /// generated 48-bit value as described in
  /// [Section 4.4](https://tools.ietf.org/html/rfc4122#section-4.4).
  int get node => _byteData.getUint16(10) << 32 + _byteData.getUint32(12);

  /// Creates an instance from the given bytes without defensively copying them.
  ///
  /// The given byte buffer will be wrapped in an unmodifiable view.
  Uuid._fromValidBytes(ByteBuffer bytes)
      : bytes = UnmodifiableByteBufferView(bytes);

  /// Generates a v4 (random) UUID.
  ///
  /// If you don't pass a random number generator for the [random] parameter,
  /// a global secure one will be used.
  factory Uuid.v4({Random? random}) {
    return Uuid4Generator(random).generate();
  }

  /// Parses a UUID from the given String.
  ///
  /// The following forms are accepted:
  ///
  /// ```
  /// 12345678-1234-5678-1234-567812345678
  /// 12345678123456781234567812345678
  /// urn:uuid:12345678-1234-5678-1234-567812345678
  /// urn:uuid:12345678123456781234567812345678
  /// ```
  ///
  /// Note that all formats listed above will yield the same UUID.
  ///
  /// Furthermore, parsing is case insensitive, but surrounding whitespace will
  /// NOT be ignored.
  ///
  /// This method will throw an [ArgumentError] if the given String is not a
  /// valid UUID.
  factory Uuid.fromString(String uuidString) {
    final match = _uuidPattern.firstMatch(uuidString);
    if (match == null) {
      throw ArgumentError.value(
        uuidString,
        'uuidString',
        'Invalid UUID: $uuidString',
      );
    }
    final builder = BytesBuilder(copy: false);
    final decoder = Hex.decoder;
    for (var groupIndex = 1; groupIndex <= match.groupCount; ++groupIndex) {
      final group = match.group(groupIndex)!;
      final data = decoder.convert(group);
      builder.add(data);
    }

    return Uuid._fromValidBytes(builder.takeBytes().buffer);
  }

  /// Construct a UUID from the given byte buffer.
  ///
  /// The given [uuidBytes] will be copied to prevent modifications.
  ///
  /// This method throws an [ArgumentError] if, and only if, the [uuidBytes]
  /// buffer wasn't exactly 16 bytes (see [kUuidBytes]) long.
  factory Uuid.fromBytes(ByteBuffer uuidBytes) {
    if (uuidBytes.lengthInBytes != kUuidBytes) {
      throw ArgumentError.value(
        uuidBytes,
        'uuidBytes',
        'Must be $kUuidBytes bytes long, was ${uuidBytes.lengthInBytes}',
      );
    }

    final copy = Uint8List(uuidBytes.lengthInBytes);
    final inputList = uuidBytes.asInt8List();
    for (var index = 0; index < copy.length; index += 1) {
      copy[index] = inputList[index];
    }
    return Uuid._fromValidBytes(copy.buffer);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Uuid &&
          runtimeType == other.runtimeType &&
          compareTo(other) == 0;

  @override
  int get hashCode {
    return bytes.asUint32List().reduce((a, b) => a ^ b);
  }

  /// Returns the string representation of this UUID as specified by RFC 4122.
  @override
  String toString() {
    final encoded = Hex.encoder.convert(_byteData);
    return [
      encoded.substring(0, 8),
      encoded.substring(8, 12),
      encoded.substring(12, 16),
      encoded.substring(16, 20),
      encoded.substring(20),
    ].join('-');
  }

  bool operator <(Uuid other) => compareTo(other) < 0;

  bool operator <=(Uuid other) => compareTo(other) <= 0;

  bool operator >(Uuid other) => compareTo(other) > 0;

  bool operator >=(Uuid other) => compareTo(other) >= 0;

  @override
  int compareTo(Uuid other) {
    // We just compare the underlying bytes without a care about the specifics
    final valueIterator = bytes.asUint32List().iterator;
    final otherValueIterator = other.bytes.asUint32List().iterator;
    while (valueIterator.moveNext() && otherValueIterator.moveNext()) {
      final diff = valueIterator.current - otherValueIterator.current;
      if (diff != 0) {
        return diff;
      }
    }
    return 0;
  }
}
