import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keep_link/core/services/backend/tiktok_metadata_service.dart';

void main() {
  group('TikTokMetadataService.isTikTokUrl', () {
    test('accepts canonical and short TikTok links', () {
      expect(
        TikTokMetadataService.isTikTokUrl(
          'https://www.tiktok.com/@scout2015/video/6718335390845095173',
        ),
        isTrue,
      );
      expect(
        TikTokMetadataService.isTikTokUrl('https://vm.tiktok.com/abc123/'),
        isTrue,
      );
      expect(
        TikTokMetadataService.isTikTokUrl('https://vt.tiktok.com/xyz789/'),
        isTrue,
      );
    });

    test('rejects lookalike, malformed and non-web links', () {
      expect(
        TikTokMetadataService.isTikTokUrl('https://tiktok.com.example.com/a'),
        isFalse,
      );
      expect(
        TikTokMetadataService.isTikTokUrl('https://evil-tiktok.com/a'),
        isFalse,
      );
      expect(TikTokMetadataService.isTikTokUrl('tiktok://video/123'), isFalse);
      expect(TikTokMetadataService.isTikTokUrl('not a link'), isFalse);
    });
  });

  test('removes share parameters before requesting oEmbed metadata', () async {
    final client = Dio();
    String? requestedUrl;
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path != 'https://www.tiktok.com/oembed') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: '''
                  <script id="api-data" type="application/json">
                    {
                      "videoDetail": {
                        "itemInfo": {
                          "itemStruct": {
                            "contentLocation": {
                              "address": {
                                "addressLocality": "Can Tho",
                                "streetAddress": "Phố Lẩu Restaurant, 158H/6 Đ. Nguyễn Văn Cừ, An Khánh, Ninh Kiều, Cần Thơ"
                              }
                            },
                            "poi": {
                              "name": "Phố Lẩu Restaurant",
                              "address": "158H/6 Đ. Nguyễn Văn Cừ, An Khánh, Ninh Kiều, Cần Thơ"
                            }
                          }
                        }
                      }
                    }
                  </script>
                ''',
              ),
            );
            return;
          }

          requestedUrl = options.queryParameters['url'] as String?;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'title': 'A public TikTok post',
                'author_name': 'Creator',
                'thumbnail_url': 'https://example.com/cover.jpg',
              },
            ),
          );
        },
      ),
    );

    final originalUrl =
        'https://www.tiktok.com/@creator/video/123?_r=1&_t=tracking#share';
    final metadata = await TikTokMetadataService.fetch(
      originalUrl,
      client: client,
    );

    expect(requestedUrl, 'https://www.tiktok.com/@creator/video/123');
    expect(metadata?.url, originalUrl);
    expect(metadata?.title, 'A public TikTok post');
    expect(metadata?.description, 'Creator');
    expect(metadata?.imageUrl, 'https://example.com/cover.jpg');
    expect(
      metadata?.address,
      'Phố Lẩu Restaurant, 158H/6 Đ. Nguyễn Văn Cừ, An Khánh, Ninh Kiều, Cần Thơ',
    );
  });
}
