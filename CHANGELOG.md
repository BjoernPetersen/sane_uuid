## 1.1.0

### Features

- You can now generate v6 UUIDs (specified by RFC 9562) using `Uuid.v6()`

## 1.0.1

### Bugfixes

- Fixed rounding error in `Uuid.parsedTime`

## 1.0.0

### Breaking Changes

- Bumped minimum Dart version to 3.3.0
- The `Uuid.fromBytes` factory now accepts a Uint8List instead of a ByteBuffer
- The type of `Uuid.bytes` has changed to Uint8List.

## 1.0.0-alpha.5

### Breaking Changes

- Require Dart 3
- Introduce class modifiers where applicable

## 1.0.0-alpha.4

- Throw FormatException instead of ArgumentError in `Uuid.fromString`,
  because clients shouldn't have to catch errors.

## 1.0.0-alpha.2

- Initial version
