import 'package:keep_link/core/data/cache/app_cache.dart';
import 'package:keep_link/core/data/cache/sql_lite.dart';
import 'package:keep_link/features/friend/application/model/friend_model.dart';

class FriendRepository {
  FriendRepository._();

  static const String _table = 'friends';

  static Future<void> ensureLoaded() async {
    if (AppCache.friendsLoaded) return;

    final rows = await DbHelper.getAll(
      _table,
      orderByColumn: 'created_at',
      descending: true,
    );
    final list = rows
        .map((r) => FriendModel.fromJson(Map<String, dynamic>.from(r)))
        .toList();
    AppCache.setFriends(list);
  }

  static List<FriendModel> getAll() => List.unmodifiable(AppCache.friends);

  static Future<void> insert(FriendModel friend) async {
    await DbHelper.upsert(friend);
    AppCache.addFriend(friend);
  }

  static Future<void> update(FriendModel friend) async {
    await DbHelper.upsert(friend);
    AppCache.updateFriend(friend);
  }

  static Future<void> delete(String id) async {
    await DbHelper.delete(_table, id);
    AppCache.removeFriend(id);
  }

  static Future<void> replaceAll(
    List<FriendModel> friends, {
    bool preserveFavorites = true,
  }) async {
    if (preserveFavorites) await ensureLoaded();

    final favoriteMap = preserveFavorites
        ? {
            for (final friend in AppCache.friends)
              if ((friend.id ?? '').isNotEmpty) friend.id!: friend.isFavorite,
          }
        : const <String, bool>{};

    final merged = friends
        .map(
          (friend) => friend.copyWith(
            isFavorite: favoriteMap[friend.id ?? ''] ?? friend.isFavorite,
          ),
        )
        .toList();

    await DbHelper.clearTable(_table);
    await DbHelper.upsertAll(merged);
    AppCache.setFriends(merged);
  }
}
