import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_link/core/services/backend/social_video_download_service.dart';

void main() {
  group('SocialVideoDownloadService', () {
    test('accepts supported social links and direct video files', () {
      expect(
        SocialVideoDownloadService.supports(
          'https://www.tiktok.com/@creator/video/123',
        ),
        isTrue,
      );
      expect(
        SocialVideoDownloadService.supports(
          'https://www.instagram.com/reel/abc/',
        ),
        isTrue,
      );
      expect(
        SocialVideoDownloadService.supports(
          'https://cdn.example.com/video/high.mp4',
        ),
        isTrue,
      );
      expect(
        SocialVideoDownloadService.supports('https://example.com/article'),
        isFalse,
      );
    });

    test('returns direct video URLs without a page request', () async {
      final source = await SocialVideoDownloadService.resolve(
        'https://cdn.example.com/videos/demo.webm?token=abc',
      );

      expect(source.url, contains('demo.webm'));
      expect(source.extension, 'webm');
      expect(source.platform, 'direct');
    });

    test('selects the highest quality TikTok playback candidate', () async {
      final client = Dio();
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              headers: Headers.fromMap({
                'set-cookie': [
                  'ttwid=session-123; Path=/; Secure',
                  'msToken=token-456; Path=/; Secure',
                ],
              }),
              data: r'''
                <script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">
                  {
                    "__DEFAULT_SCOPE__": {
                      "webapp.video-detail": {
                        "itemInfo": {
                          "itemStruct": {
                            "video": {
                              "bitrateInfo": [
                                {
                                  "Bitrate": 500000,
                                  "PlayAddr": {
                                    "Width": 540,
                                    "Height": 960,
                                    "UrlList": ["https://cdn.example.com/low.mp4"]
                                  }
                                },
                                {
                                  "Bitrate": 2500000,
                                  "PlayAddr": {
                                    "Width": 1080,
                                    "Height": 1920,
                                    "UrlList": ["https://cdn.example.com/high.mp4"]
                                  }
                                }
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                </script>
              ''',
            ),
          ),
        ),
      );

      final source = await SocialVideoDownloadService.resolve(
        'https://www.tiktok.com/@creator/video/123',
        client: client,
      );

      expect(source.url, 'https://cdn.example.com/high.mp4');
      expect(source.platform, 'tiktok');
      expect(
        source.requestHeaders['Cookie'],
        'ttwid=session-123; msToken=token-456',
      );
      expect(
        source.requestHeaders['Referer'],
        'https://www.tiktok.com/@creator/video/123',
      );
    });

    test('extracts a public Instagram og:video source', () async {
      final client = Dio();
      client.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: '''
                <html><head>
                  <meta property="og:video" content="https://cdn.example.com/reel.mp4" />
                </head></html>
              ''',
            ),
          ),
        ),
      );

      final source = await SocialVideoDownloadService.resolve(
        'https://www.instagram.com/reel/abc/',
        client: client,
      );

      expect(source.url, 'https://cdn.example.com/reel.mp4');
      expect(source.platform, 'instagram');
    });

    test('resolves YouTube video to a playable stream source', () async {
      final source = await SocialVideoDownloadService.resolve(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(source.platform, 'youtube');
      expect(source.url, contains('googlevideo.com'));
      expect(source.extension, isNotEmpty);
    });

    test('throws source_unavailable for non-existent YouTube video', () async {
      expect(
        () => SocialVideoDownloadService.resolve(
          'https://www.youtube.com/shorts/non_existent_id_12345',
        ),
        throwsA(
          isA<SocialVideoDownloadException>().having(
            (error) => error.code,
            'code',
            'source_unavailable',
          ),
        ),
      );
    });
  });
}
