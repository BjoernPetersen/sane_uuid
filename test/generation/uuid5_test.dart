import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  group('UUIDv5 generation', () {
    test('create domain UUID', () {
      final uuid = Uuid.v5(namespace: Namespaces.dns, name: 'google.com');
      expect(uuid.toString(), '64ee70a4-8cc1-5d25-abf2-dea6c79a09c8');
      expect(uuid.version, 5);
      expect(
        () => uuid.bytes[0] = 0,
        throwsUnsupportedError,
        reason:
            'The exception should be thrown because Uuid objects should be immutable',
      );
    });
    test('create URL UUID', () {
      final uuid = Uuid.v5(
        namespace: Namespaces.url,
        name: 'https://google.com',
      );
      expect(uuid.toString(), '9a4cda5b-12b5-5e03-822a-7d33af73bcf0');
      expect(uuid.version, 5);
      expect(
        () => uuid.bytes[0] = 0,
        throwsUnsupportedError,
        reason:
            'The exception should be thrown because Uuid objects should be immutable',
      );
    });
  });
}
