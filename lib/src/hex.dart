import 'dart:convert';
import 'dart:typed_data';

const _alphabet = '0123456789abcdef';

abstract class Hex {
  const Hex._();

  static const Converter<ByteData, String> encoder = _HexEncoder();
  static const Converter<String, List<int>> decoder = _HexDecoder();
}

class _HexEncoder extends Converter<ByteData, String> {
  const _HexEncoder();

  @override
  String convert(ByteData input) {
    final result = StringBuffer();
    for (var index = 0; index < input.lengthInBytes; index += 1) {
      final byte = input.getUint8(index);
      final msb = byte >> 4;
      result.write(_alphabet[msb]);
      final lsb = byte & 0x0F;
      result.write(_alphabet[lsb]);
    }
    return result.toString();
  }
}

class _HexDecoder extends Converter<String, List<int>> {
  const _HexDecoder();

  @override
  List<int> convert(String input) {
    // Note: we can assume the input to have an even length
    final result = Uint8List(input.length ~/ 2);
    final lowerInput = input.toLowerCase();
    for (var index = 0; index < result.length; index += 1) {
      final msb = _alphabet.indexOf(lowerInput[index * 2]) << 4;
      final lsb = _alphabet.indexOf(lowerInput[index * 2 + 1]);
      result[index] = msb + lsb;
    }
    return result;
  }
}
