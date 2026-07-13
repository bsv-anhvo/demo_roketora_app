import 'dart:convert';

class FileIdGenerator {
  static const String _alphabet =
      '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Generate short file id from original file id.
  static String generate(String fileId) {
    final crc = _crc32(utf8.encode(fileId));

    final base32 = _toCrockfordBase32(crc);

    final checkDigit = _calculateCheckDigit(base32);

    return base32 + checkDigit;
  }

  /// CRC32 IEEE
  static int _crc32(List<int> bytes) {
    const int polynomial = 0xEDB88320;

    int crc = 0xFFFFFFFF;

    for (final b in bytes) {
      crc ^= b;

      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ polynomial;
        } else {
          crc >>= 1;
        }
      }
    }

    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  /// Convert uint32 to Crockford Base32.
  static String _toCrockfordBase32(int value) {
    if (value == 0) {
      return '0';
    }

    final chars = <String>[];

    while (value > 0) {
      chars.add(_alphabet[value & 31]);
      value >>= 5;
    }

    return chars.reversed.join();
  }

  /// Calculate check digit.
  static String _calculateCheckDigit(String input) {
    int sum = 0;

    for (int i = 0; i < input.length; i++) {
      final value = _alphabet.indexOf(input[i]);

      // weight = 1,2,3,...
      sum += value * (i + 1);
    }

    final remainder = sum % 32;

    return _alphabet[remainder];
  }
}