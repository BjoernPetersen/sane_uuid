final class Late<T> {
  final T Function() _generate;

  T? _value;

  T get value {
    return _value ??= _generate();
  }

  Late(this._generate);
}
