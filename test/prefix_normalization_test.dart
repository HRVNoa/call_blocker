import 'package:flutter_test/flutter_test.dart';
import 'package:call_blocker/services/storage_service.dart';
import 'package:call_blocker/models/blocked_prefix.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Prefix normalization tests', () {
    late StorageService storageService;

    setUp(() async {
      // Initialize SharedPreferences with mock
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    test('Should block number with prefix containing spaces', () async {
      // Add a prefix with spaces
      await storageService.addPrefix(
        BlockedPrefix(
          prefix: '06 61',
          description: 'Test prefix with spaces',
          isEnabled: true,
        ),
      );

      // Test with a clean number
      final shouldBlock1 = await storageService.isNumberBlocked('0661123456');
      expect(shouldBlock1, true, reason: 'Should block 0661123456 with prefix "06 61"');

      // Test with a formatted number
      final shouldBlock2 = await storageService.isNumberBlocked('06 61 12 34 56');
      expect(shouldBlock2, true, reason: 'Should block "06 61 12 34 56" with prefix "06 61"');

      // Test with international format (NOW SHOULD WORK!)
      final shouldBlock3 = await storageService.isNumberBlocked('+33661123456');
      expect(shouldBlock3, true, reason: 'Should block +33661123456 (converted to 0661)');
      
      // Test with international format with spaces
      final shouldBlock4 = await storageService.isNumberBlocked('+33 6 61 12 34 56');
      expect(shouldBlock4, true, reason: 'Should block +33 6 61 12 34 56 (converted to 0661)');
    });

    test('Should block number with clean prefix', () async {
      // Add a prefix without spaces
      await storageService.addPrefix(
        BlockedPrefix(
          prefix: '0661',
          description: 'Test prefix without spaces',
          isEnabled: true,
        ),
      );

      // Test with a clean number
      final shouldBlock1 = await storageService.isNumberBlocked('0661123456');
      expect(shouldBlock1, true, reason: 'Should block 0661123456 with prefix "0661"');

      // Test with a formatted number
      final shouldBlock2 = await storageService.isNumberBlocked('06 61 12 34 56');
      expect(shouldBlock2, true, reason: 'Should block "06 61 12 34 56" with prefix "0661"');
    });

    test('Should NOT block number with disabled prefix', () async {
      // Add a disabled prefix
      await storageService.addPrefix(
        BlockedPrefix(
          prefix: '0661',
          description: 'Disabled prefix',
          isEnabled: false,
        ),
      );

      final shouldBlock = await storageService.isNumberBlocked('0661123456');
      expect(shouldBlock, false, reason: 'Should NOT block with disabled prefix');
    });

    test('Should NOT block number with non-matching prefix', () async {
      // Add a prefix
      await storageService.addPrefix(
        BlockedPrefix(
          prefix: '0162',
          description: 'Paris prefix',
          isEnabled: true,
        ),
      );

      final shouldBlock = await storageService.isNumberBlocked('0661123456');
      expect(shouldBlock, false, reason: 'Should NOT block non-matching number');
    });

    test('Should handle multiple prefixes correctly', () async {
      // Add multiple prefixes
      await storageService.addPrefix(
        BlockedPrefix(prefix: '0162', description: 'Paris 1', isEnabled: true),
      );
      await storageService.addPrefix(
        BlockedPrefix(prefix: '06 61', description: 'Mobile spam', isEnabled: true),
      );
      await storageService.addPrefix(
        BlockedPrefix(prefix: '0999', description: 'Test disabled', isEnabled: false),
      );

      // Test each
      expect(await storageService.isNumberBlocked('0162123456'), true);
      expect(await storageService.isNumberBlocked('0661123456'), true);
      expect(await storageService.isNumberBlocked('0999123456'), false); // disabled
      expect(await storageService.isNumberBlocked('0601123456'), false); // no match
    });
  });
}
