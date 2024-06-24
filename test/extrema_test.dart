import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  test('nil UUID is correct', () {
    expect(Uuid.nil.toString(), '00000000-0000-0000-0000-000000000000');
  });
  test('max UUID is correct', () {
    expect(Uuid.max.toString(), 'ffffffff-ffff-ffff-ffff-ffffffffffff');
  });
}
