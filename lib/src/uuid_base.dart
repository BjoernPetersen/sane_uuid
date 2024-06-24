import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:sane_uuid/src/generation.dart';
import 'package:sane_uuid/src/hex.dart';
import 'package:sane_uuid/src/namespace.dart';

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
final class Uuid implements Comparable<Uuid> {
  /// The nil UUID is a special form of UUID that is specified to have all
  /// 128 bits set to zero (00000000-0000-0000-0000-000000000000).
  static final Uuid nil = Uuid._fromValidBytes(Uint8List(kUuidBytes));

  /// The max UUID is a special form of UUID that is specified to have all
  /// 128 bits set to one (ffffffff-ffff-ffff-ffff-ffffffffffff).
  static final Uuid max = Uuid._fromValidBytes(
    Uint8List(kUuidBytes)..fillRange(0, kUuidBytes, 255),
  );

  /// The raw bytes of this UUID. The returned Uint8List is unmodifiable and
  /// contains exactly 16 bytes.
  final Uint8List bytes;

  ByteData get _byteData => bytes.buffer.asByteData();

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
  /// Note that [parsedTime] provides a parsed version of this timestamp,
  /// albeit only for v1 UUIDs.
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
  int get time => (timeHigh << 48) + (timeMid << 32) + timeLow;

  /// The parsed [time] as a usable [DateTime] object.
  ///
  /// This method is only useful for v1 UUIDs, because the [time] field has
  /// different semantics for other version.
  ///
  /// Throws a [StateError] if [variant] is not [UuidVariant.rfc4122] or
  /// [version] is not 1.
  DateTime get parsedTime {
    if (variant != UuidVariant.rfc4122) {
      throw StateError('Only available for RFC 4122 UUIDs');
    } else if (version != 1) {
      throw StateError('Only available for v1 UUIDs');
    }
    // time is the count of 100-nanosecond intervals
    // since 00:00:00.00, 15 October 1582.
    final referenceTime = DateTime.utc(1582, 10, 15);
    // 1000 nanoseconds are a microsecond.
    final microseconds = (time ~/ 10);
    final timeDuration = Duration(microseconds: microseconds);
    return referenceTime.add(timeDuration);
  }

  /// The version that was originally multiplexed in [timeHighAndVersion].
  ///
  /// If this UUID conforms to the structure laid out in RFC 4122, this will
  /// be a number between 1 and 5 with the following descriptions:
  ///
  /// - 1: Time-based version
  /// - 2: DCE Security version, with embedded POSIX UIDs
  /// - 3: Name-based version with MD5 hashing
  /// - 4: Random version
  /// - 5: Name-based version with SHA-1 hashing
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
    final variantBits = clockSequenceHighAndReserved >> 5;
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
  int get clockSequence => (clockSequenceHigh << 8) + clockSequenceLow;

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
  int get node => (_byteData.getUint16(10) << 32) + _byteData.getUint32(12);

  /// Creates an instance from the given bytes without defensively copying them.
  ///
  /// The given byte buffer will be wrapped in an unmodifiable view and will
  /// never be modified.
  Uuid._fromValidBytes(Uint8List bytes) : bytes = bytes.asUnmodifiableView();

  /// Generates a v1 (time-based) UUID.
  ///
  /// The default implementation doesn't use a real MAC address as a node ID.
  /// Instead it generates a random node ID and sets the "multi-cast bit"
  /// as recommended by RFC 4122. A generated node ID will be kept in-memory
  /// and reused during the lifetime of a process, but won't be persisted.
  ///
  /// Instead of using a generated node ID, you may specify one using [nodeId].
  /// If the given node ID is larger than 48-bit, an [ArgumentError] is thrown.
  factory Uuid.v1({int? nodeId}) {
    final bytes = Uuid1Generator().generate(nodeId: nodeId);
    // We trust our own generator not to modify the bytes anymore.
    return Uuid._fromValidBytes(bytes);
  }

  /// Generates a v4 (random) UUID.
  ///
  /// If you don't pass a random number generator for the [random] parameter,
  /// a global secure one will be used.
  factory Uuid.v4({Random? random}) {
    final bytes = Uuid4Generator(random).generate();
    // We trust our own generator not to modify the bytes anymore.
    return Uuid._fromValidBytes(bytes);
  }

  /// Generates a v5 (name-based with SHA-1) UUID.
  ///
  /// Expects a [namespace] UUID. Some predefined namespace UUIDs can be found
  /// in [Namespaces]. The [name] should conform to the conventions of the
  /// namespace.
  factory Uuid.v5({required Uuid namespace, required String name}) {
    final bytes = Uuid5Generator().generate(namespace: namespace, name: name);
    // We trust our own generator not to modify the bytes anymore.
    return Uuid._fromValidBytes(bytes);
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
  /// This method will throw an [FormatException] if the given String is not a
  /// valid UUID.
  factory Uuid.fromString(String uuidString) {
    final match = _uuidPattern.firstMatch(uuidString);
    if (match == null) {
      throw FormatException('Invalid UUID', uuidString);
    }
    final builder = BytesBuilder(copy: false);
    final decoder = Hex.decoder;
    for (var groupIndex = 1; groupIndex <= match.groupCount; ++groupIndex) {
      final group = match.group(groupIndex)!;
      final data = decoder.convert(group);
      builder.add(data);
    }

    return Uuid._fromValidBytes(builder.takeBytes());
  }

  /// Construct a UUID from the given byte list.
  ///
  /// The given [uuidBytes] will be copied to prevent modifications.
  ///
  /// This method throws an [ArgumentError] if, and only if, the [uuidBytes]
  /// list wasn't exactly 16 bytes (see [kUuidBytes]) long.
  factory Uuid.fromBytes(Uint8List uuidBytes) {
    if (uuidBytes.lengthInBytes != kUuidBytes) {
      throw ArgumentError.value(
        uuidBytes,
        'uuidBytes',
        'Must be $kUuidBytes bytes long, was ${uuidBytes.lengthInBytes}',
      );
    }

    final copy = Uint8List.fromList(uuidBytes);
    return Uuid._fromValidBytes(copy);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Uuid &&
          runtimeType == other.runtimeType &&
          compareTo(other) == 0;

  @override
  int get hashCode {
    return bytes.buffer.asUint32List().reduce((a, b) => a ^ b);
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
    final valueIterator = bytes.buffer.asUint32List().iterator;
    final otherValueIterator = other.bytes.buffer.asUint32List().iterator;
    while (valueIterator.moveNext() && otherValueIterator.moveNext()) {
      final diff = valueIterator.current - otherValueIterator.current;
      if (diff != 0) {
        return diff;
      }
    }
    return 0;
  }
}
