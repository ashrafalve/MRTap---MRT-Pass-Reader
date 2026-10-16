import 'dart:typed_data';

/// Small byte helpers shared by the FeliCa reader.
///
/// Kept dependency-free so they can be unit tested without any plugin.

const String _hexDigits = '0123456789ABCDEF';

/// Formats bytes as upper-case hex separated by single spaces, e.g.
/// `08 52 10 00`.
String toHex(Uint8List bytes) {
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < bytes.length; i++) {
    if (i > 0) {
      buffer.write(' ');
    }
    final int b = bytes[i] & 0xFF;
    buffer
      ..write(_hexDigits[b >> 4])
      ..write(_hexDigits[b & 0x0F]);
  }
  return buffer.toString();
}

/// Little-endian 16-bit read. FeliCa balances and service codes are
/// little-endian.
int readUint16LE(Uint8List bytes, int offset) =>
    (bytes[offset] & 0xFF) | ((bytes[offset + 1] & 0xFF) << 8);

/// Little-endian 24-bit read, used for the balance field.
int readUint24LE(Uint8List bytes, int offset) =>
    (bytes[offset] & 0xFF) |
    ((bytes[offset + 1] & 0xFF) << 8) |
    ((bytes[offset + 2] & 0xFF) << 16);

/// Big-endian 24-bit read, used for the packed timestamp field.
int readUint24BE(Uint8List bytes, int offset) =>
    ((bytes[offset] & 0xFF) << 16) |
    ((bytes[offset + 1] & 0xFF) << 8) |
    (bytes[offset + 2] & 0xFF);

/// Parses a hex string such as `0127` into bytes, ignoring whitespace.
Uint8List? hexToBytes(String hex) {
  final String cleaned = hex.replaceAll(RegExp(r'\s'), '');
  if (cleaned.length.isOdd) {
    return null;
  }
  final Uint8List out = Uint8List(cleaned.length ~/ 2);
  for (int i = 0; i < out.length; i++) {
    final int? value = int.tryParse(
      cleaned.substring(i * 2, i * 2 + 2),
      radix: 16,
    );
    if (value == null) {
      return null;
    }
    out[i] = value;
  }
  return out;
}
