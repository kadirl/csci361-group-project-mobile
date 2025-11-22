import 'package:flutter_test/flutter_test.dart';
import 'package:swe_mobile/core/utils/string_utils.dart';

void main() {
  group('capitalize', () {
    test('capitalizes a lowercase word', () {
      expect(capitalize('hello'), 'Hello');
    });

    test('capitalizes an uppercase word', () {
      expect(capitalize('HELLO'), 'Hello');
    });

    test('capitalizes a mixed case word', () {
      expect(capitalize('hElLo'), 'Hello');
    });

    test('handles empty string', () {
      expect(capitalize(''), '');
    });

    test('handles single letter', () {
      expect(capitalize('a'), 'A');
      expect(capitalize('A'), 'A');
    });
  });
}
