import 'package:flutter_test/flutter_test.dart';
import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/repositories/link_repository.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';
import 'package:keep_link/features/link/application/model/link_model.dart';

void main() {
  tearDown(AppCache.invalidateAll);

  group('LinkRepository.getFiltered privacy', () {
    setUp(() {
      AppCache.setLinks([
        LinkModel(id: 'public-link', categoryId: 'public-category'),
        LinkModel(id: 'private-link', categoryId: 'private-category'),
        LinkModel(id: 'uncategorized-link'),
      ]);
    });

    test('aggregate view includes links in every category by default', () {
      final result = LinkRepository.getFiltered(categoryId: 'all');

      expect(
        result.map((link) => link.id),
        containsAll(<String>[
          'public-link',
          'private-link',
          'uncategorized-link',
        ]),
      );
    });

    test('explicit private exclusion remains available for locked views', () {
      final result = LinkRepository.getFiltered(
        categoryId: 'all',
        privateCategoryIds: const {'private-category'},
        excludePrivate: true,
      );

      expect(
        result.map((link) => link.id),
        containsAll(<String>['public-link', 'uncategorized-link']),
      );
      expect(result.map((link) => link.id), isNot(contains('private-link')));
    });

    test(
      'direct private category view remains available after authorization',
      () {
        final result = LinkRepository.getFiltered(
          categoryId: 'private-category',
          privateCategoryIds: const {'private-category'},
        );

        expect(result.map((link) => link.id), ['private-link']);
      },
    );
  });

  group('AppCache account refresh boundaries', () {
    test('content refresh preserves an already loaded friend list', () {
      AppCache.setLinks([LinkModel(id: 'link-1')]);
      AppCache.setFriends([
        FriendModel(
          id: 'friend-1',
          friendUserId: 'friend-user-1',
          displayName: 'Friend',
        ),
      ]);

      AppCache.invalidateContent();

      expect(AppCache.links, isEmpty);
      expect(AppCache.linksLoaded, isFalse);
      expect(AppCache.friends.map((friend) => friend.id), ['friend-1']);
      expect(AppCache.friendsLoaded, isTrue);
    });

    test('account change invalidates friend data', () {
      AppCache.setFriends([
        FriendModel(
          id: 'friend-1',
          friendUserId: 'friend-user-1',
          displayName: 'Friend',
        ),
      ]);

      AppCache.invalidateFriends();

      expect(AppCache.friends, isEmpty);
      expect(AppCache.friendsLoaded, isFalse);
    });
  });
}
