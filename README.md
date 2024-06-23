# sane_uuid

[![codecov](https://codecov.io/github/BjoernPetersen/sane_uuid/graph/badge.svg?token=Aq3lxFN46g)](https://codecov.io/github/BjoernPetersen/sane_uuid)

A properly designed UUID library for Dart.

- Supports v1, v4, and v5 generation
- Immutable `Uuid` type with equality, comparison and accessors for properties defined by RFC4122
  - The internal representation of the UUID is a byte array, not a String
- Support for all syntactically correct UUIDs (regardless of RFC4122 semantics)

## Usage

A simple usage example:

```dart
import 'package:sane_uuid/uuid.dart';

// randomly generated using secure random number generator
final Uuid randomUuid = Uuid.v4();
// Prints properly formatted UUID, e.g.: a8796ef4-8767-4cd0-b432-c5e93ba120df
print(randomUuid);

// parse any common UUID string
final parsedUuid = Uuid.fromString(
  'a8796ef4-8767-4cd0-b432-c5e93ba120df',
);

// UUID objects with the same data are actually equal
assertTrue(randomUuid == parsedUuid);
```

For more examples, see the [examples](example) page.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/BjoernPetersen/sane_uuid/issues

## License

This project is released under the MIT License. That includes every file in this repository,
unless explicitly stated otherwise at the top of a file.
A copy of the license text can be found in the [LICENSE file](LICENSE).
