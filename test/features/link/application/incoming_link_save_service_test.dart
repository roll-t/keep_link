import 'package:flutter_test/flutter_test.dart';
import 'package:keep_link/features/link/application/incoming_link_save_service.dart';

void main() {
  group('IncomingLinkSaveService', () {
    test('extracts an http link from shared prose', () {
      expect(
        IncomingLinkSaveService.extractUrl(
          'Bài viết hay: https://Example.com/posts/42?from=share',
        ),
        'https://Example.com/posts/42?from=share',
      );
    });

    test('removes punctuation added by the sharing app', () {
      expect(
        IncomingLinkSaveService.extractUrl('Xem https://example.com/news).'),
        'https://example.com/news',
      );
    });

    test('rejects shared text without a web link', () {
      expect(IncomingLinkSaveService.extractUrl('Không có link'), isNull);
    });

    test(
      'normalizes host, trailing slash and fragment for duplicate checks',
      () {
        expect(
          IncomingLinkSaveService.normalizeUrl(
            'HTTPS://WWW.Example.COM/article/#comments',
          ),
          'https://www.example.com/article',
        );
      },
    );

    test('uses surrounding shared text as the fallback title', () {
      expect(
        IncomingLinkSaveService.fallbackTitle(
          'Một bài viết hữu ích https://example.com/a',
          'https://example.com/a',
        ),
        'Một bài viết hữu ích',
      );
    });
  });
}
