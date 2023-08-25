import 'package:sane_uuid/src/uuid_base.dart';

final class Namespaces {
  const Namespaces._();

  /// Name string is a fully-qualified domain name.
  static final Uuid dns =
      Uuid.fromString('6ba7b810-9dad-11d1-80b4-00c04fd430c8');

  /// Name string is a URL.
  static final Uuid url =
      Uuid.fromString('6ba7b811-9dad-11d1-80b4-00c04fd430c8');

  /// Name string is an ISO OID.
  static final Uuid oid =
      Uuid.fromString('6ba7b812-9dad-11d1-80b4-00c04fd430c8');

  /// Name string is an X.500 DN (in DER or a text output format).
  static final Uuid x500 =
      Uuid.fromString('6ba7b814-9dad-11d1-80b4-00c04fd430c8');
}
