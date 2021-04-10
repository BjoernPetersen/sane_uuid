import 'package:sane_uuid/uuid.dart';

void main() {
  // randomly generated using secure random number generator
  final Uuid randomUuid = Uuid.v4();

  // parse any common UUID string
  final parsedHyphenated = Uuid.fromString(
    'a8796ef4-8767-4cd0-b432-c5e93ba120df',
  );
  final parsedWithoutHyphens = Uuid.fromString(
    'a8796ef487674cd0b432c5e93ba120df',
  );

  // UUID objects have proper equality and hashCode
  assert(parsedHyphenated == parsedWithoutHyphens);
  assert(parsedHyphenated.hashCode == parsedWithoutHyphens.hashCode);

  // UUID objects can be compared/sorted lexicographically
  final biggerUuid = Uuid.fromString(
    'b8796ef4-8767-4cd0-b432-c5e93ba120df',
  );
  final smallerUuid = Uuid.fromString(
    '18796ef4-8767-4cd0-b432-c5e93ba120df',
  );
  final list = [biggerUuid, smallerUuid, parsedHyphenated];
  list.sort();
  // Is ordered like this now: [smallerUuid, parsedHyphenated, biggerUuid]
  print(list);

  // Access any detailed information in the UUID:
  final timeBasedUuid = Uuid.v1();
  assert(timeBasedUuid.version == 1);
  final time = timeBasedUuid.parsedTime;
  // A usable timestamp for v1 UUIDs!
  print(time);
}
