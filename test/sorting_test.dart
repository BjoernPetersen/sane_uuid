import 'package:sane_uuid/uuid.dart';
import 'package:test/test.dart';

void main() {
  test('random ID is equal to itself', () {
    final uuid = Uuid.v4();
    expect(uuid.compareTo(uuid), 0);
  });

  group('with zero and one', () {
    final zeroUuid = Uuid.fromString('00000000-0000-0000-0000-000000000000');
    final oneUuid = Uuid.fromString('00000000-0000-0000-0000-000000000001');

    test('zero < one', () => expect(zeroUuid < oneUuid, true));
    test('zero <= one', () => expect(zeroUuid <= oneUuid, true));
    test('one > zero', () => expect(oneUuid > zeroUuid, true));
    test('one >= zero', () => expect(oneUuid >= zeroUuid, true));
    test('one !< zero', () => expect(oneUuid < zeroUuid, false));
  });

  group('with zero and max', () {
    final zeroUuid = Uuid.fromString('00000000-0000-0000-0000-000000000000');
    final maxUuid = Uuid.fromString('FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF');

    test('max == max', () => expect(maxUuid.compareTo(maxUuid), 0));
    test('zero < max', () => expect(zeroUuid < maxUuid, true));
    test('max > zero', () => expect(maxUuid > zeroUuid, true));
  });

  test('no overflow', () {
    final maxUuid = Uuid.fromString('FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF');
    final largeUuid = Uuid.fromString('EFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF');
    expect(maxUuid > largeUuid, true);
  });
}
