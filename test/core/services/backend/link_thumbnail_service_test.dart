import 'package:flutter_test/flutter_test.dart';
import 'package:keep_link/core/services/backend/link_thumbnail_service.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';
import 'package:keep_link/features/link/application/model/meta_data_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LinkThumbnailService and LinkModel.displayImage', () {
    test('LinkModel.displayImage prefers local image over metadata imageUrl', () {
      final linkWithLocal = LinkModel(
        id: '123',
        image: '/data/user/0/app/thumbnails/123.jpg',
        metaDataModel: MetaDataModel(
          url: 'https://example.com',
          title: 'Test',
          description: '',
          imageUrl: 'https://cdn.example.com/remote.jpg',
          favicon: '',
          appleIcon: '',
        ),
      );

      expect(linkWithLocal.displayImage, '/data/user/0/app/thumbnails/123.jpg');

      final linkWithoutLocal = LinkModel(
        id: '456',
        metaDataModel: MetaDataModel(
          url: 'https://example.com',
          title: 'Test',
          description: '',
          imageUrl: 'https://cdn.example.com/remote.jpg',
          favicon: '',
          appleIcon: '',
        ),
      );

      expect(linkWithoutLocal.displayImage, 'https://cdn.example.com/remote.jpg');
    });

    test('deleteThumbnail does not throw when file does not exist', () async {
      await expectLater(
        LinkThumbnailService.deleteThumbnail('non_existent_link_999'),
        completes,
      );
      await expectLater(
        LinkThumbnailService.deleteThumbnails(['id_1', 'id_2']),
        completes,
      );
    });

    test('saveThumbnail gracefully returns null on invalid or empty url', () async {
      final result1 = await LinkThumbnailService.saveThumbnail(
        linkId: '123',
        remoteUrl: '',
      );
      expect(result1, isNull);

      final result2 = await LinkThumbnailService.saveThumbnail(
        linkId: '',
        remoteUrl: 'https://example.com/image.jpg',
      );
      expect(result2, isNull);

      final result3 = await LinkThumbnailService.saveThumbnail(
        linkId: '123',
        remoteUrl: 'ftp://not-supported',
      );
      expect(result3, isNull);
    });
  });
}
