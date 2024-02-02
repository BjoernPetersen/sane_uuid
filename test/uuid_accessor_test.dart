import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('example UUIDs', () {
    for (final (uuidString, version) in [
      ('250f64f4-5de9-4ed9-8ad7-000004ae597d', 4)
    ]) {
      test(uuidString, () {
        final uuid = Uuid.fromString(uuidString);
        expect(uuid.version, version);
        expect(uuid.toString(), uuidString);
      });
    }
  });
}
