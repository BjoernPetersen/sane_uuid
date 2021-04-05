class Late<T> {
  final T Function() _generate;

  T? _value;

  T get value {
    _value ??= _generate();
    return _value!;
  }

  Late(this._generate);
}
