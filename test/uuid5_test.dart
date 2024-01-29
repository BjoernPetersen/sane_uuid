import 'package:sane_uuid/src/namespace.dart';
import 'package:sane_uuid/src/uuid_base.dart';
import 'package:test/test.dart';

void main() {
  group('UUIDv5', () {
    test('create domain UUID', () {
      final uuid = Uuid.v5(namespace: Namespaces.dns, name: 'google.com');
      expect(uuid.toString(), '64ee70a4-8cc1-5d25-abf2-dea6c79a09c8');
    });
    test('create URL UUID', () {
      final uuid = Uuid.v5(
        namespace: Namespaces.url,
        name: 'https://google.com',
      );
      expect(uuid.toString(), '9a4cda5b-12b5-5e03-822a-7d33af73bcf0');
    });
  });
}
