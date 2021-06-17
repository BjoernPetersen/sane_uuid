## 1.0.0-alpha.2

- Initial version

## 1.0.0-alpha.3

- Throw FormatException instead of ArgumentError in `Uuid.fromString`,
  because clients shouldn't have to catch errors.