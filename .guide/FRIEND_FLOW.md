# Friend Flow — Linkeep

## Tổng quan

Tính năng **Bạn bè** cho phép người dùng kết nối với nhau, sau đó chia sẻ danh mục link (Category) qua lại. Toàn bộ dữ liệu được lưu trên **Firebase Realtime Database** và cache cục bộ bằng **SQLite** + **AppCache** (in-memory).

---

## Cấu trúc Firebase

```
users/
  {uid}/
    friends/
      {friendUserId}/           ← FriendModel của phía mình
        friendUserId: string
        displayName:  string
        email:        string
        photoUrl:     string
        sourceLink:   string
        createdAt:    ISO8601
        updatedAt:    ISO8601

    friendRequests/
      {fromUserId}/              ← Lời mời đến (inbox)
        displayName: string
        email:       string
        photoUrl:    string
        sourceLink:  string
        status:      "pending"
        createdAt:   ISO8601

    sentFriendRequests/
      {targetUserId}/            ← Lời mời đã gửi (outbox)
        status: "pending"
        createdAt: ISO8601

    sharedWith/
      {friendUid}/
        {categoryId}: true       ← Mình đã share category nào cho ai

    sharedCategoryAccess/
      {ownerUid}/
        {categoryId}: timestamp  ← Mình được bạn share category nào

friendDirectory/
  profiles/
    {uid}/                       ← Hồ sơ công khai để tìm bạn qua email
      uid:         string
      displayName: string
      email:       string
      photoUrl:    string
```

---

## Model

### FriendModel (`lib/features/friend/application/model/friend_model.dart`)

| Field          | SQLite column    | Kiểu          | Mô tả                        |
|----------------|------------------|---------------|------------------------------|
| `id`           | `id`             | TEXT PK       | Bằng `friendUserId`          |
| `friendUserId` | `friend_user_id` | TEXT NOT NULL | UID của người bạn            |
| `displayName`  | `display_name`   | TEXT NOT NULL | Tên hiển thị                 |
| `email`        | `email`          | TEXT          | Gmail                        |
| `photoUrl`     | `photo_url`      | TEXT          | Avatar URL                   |
| `sourceLink`   | `source_link`    | TEXT          | Link/email dùng để kết bạn   |
| `isFavorite`   | `is_favorite`    | INTEGER 0/1   | Đã đánh dấu yêu thích chưa  |
| `createdAt`    | `created_at`     | TEXT ISO8601  | Ngày kết bạn                 |
| `updatedAt`    | `updated_at`     | TEXT ISO8601  | Cập nhật gần nhất            |

### FriendRequestModel (`lib/features/friend/application/model/friend_request_model.dart`)

| Field          | Kiểu    | Mô tả                            |
|----------------|---------|----------------------------------|
| `fromUserId`   | String  | UID người gửi lời mời            |
| `displayName`  | String  | Tên hiển thị của người gửi       |
| `email`        | String? | Gmail                            |
| `photoUrl`     | String? | Avatar                           |
| `sourceLink`   | String? | Link gốc đã dùng để gửi lời mời |
| `status`       | String  | `"pending"`                      |
| `createdAt`    | DateTime? | Thời điểm gửi                  |

---

## Các luồng chính

### 1. Thêm bạn

Người dùng có **3 cách** gửi lời mời kết bạn:

#### a. Bằng Link bạn bè (Deep Link)

```
keeplink://open/friend?data=<base64url>
```

- **Tạo link**: `FriendConnectionService.buildLink(user)` — encode JSON `{uid, displayName, email, photoUrl, ts}` thành base64url.
- **Đọc từ Clipboard**: `FriendController.addFriendFromClipboard()`.
- **Quét QR**: `FriendController.addFriendFromLink(rawInput)` — parse link, kiểm tra hợp lệ, gửi lời mời.

#### b. Bằng Gmail

```
FriendController.addFriendFromEmail(rawEmail)
  → FirebaseService.findUserProfileByEmail(email)  // query friendDirectory/profiles
  → _sendFriendRequest(...)
```

- Chỉ chấp nhận `@gmail.com`.
- Tra cứu profile qua `friendDirectory/profiles` (indexed by email) — **không scan `/users`**.

#### c. Quét QR

- Mở bottom sheet `_QrScannerSheet` với `mobile_scanner`.
- Khi quét thành công → `FriendController.addFriendFromLink(barcode)`.

#### Luồng gửi lời mời (`_sendFriendRequest`)

```
1. Kiểm tra: đã là bạn? đã gửi lời mời rồi?
2. Nếu người kia đang gửi lời mời đến mình → chấp nhận thẳng (acceptFriendRequest)
3. Gọi FirebaseService.sendFriendRequest(...)
   → Ghi users/{myUid}/sentFriendRequests/{targetUid}
   → Ghi users/{targetUid}/friendRequests/{myUid}
4. Thêm targetUid vào pendingRequestUserIds (local)
```

**Giới hạn:** tối đa **10 bạn** (`FriendController.maxFriends`).

---

### 2. Chấp nhận / Từ chối lời mời

#### Chấp nhận (`acceptFriendRequest`)

```
FirebaseService.acceptFriendRequest(request)
  → users/{myUid}/friends/{fromUserId}  = currentUserFriend
  → users/{myUid}/friendRequests/{fromUserId} = null  (xoá)
  → users/{fromUserId}/friends/{myUid}  = requesterFriend
  → users/{fromUserId}/sentFriendRequests/{myUid} = null  (xoá)
→ _syncRemoteFriendState()  (cập nhật cache)
```

#### Từ chối (`declineFriendRequest`)

```
FirebaseService.declineFriendRequest(fromUserId)
  → users/{myUid}/friendRequests/{fromUserId} = null
→ incomingRequests.remove(...)  (local)
```

---

### 3. Xoá bạn

```
FriendController.confirmDeleteFriend(friend)
  → hiện dialog xác nhận
  → FirebaseService.removeFriend(friendUserId)
      Phía mình:   users/{myUid}/friends/{friendUid}           = null
                   users/{myUid}/sharedWith/{friendUid}        = null
                   users/{myUid}/sharedCategoryAccess/{friendUid} = null
      Phía bạn:    users/{friendUid}/friends/{myUid}           = null  (best-effort)
                   users/{friendUid}/sharedWith/{myUid}        = null  (best-effort)
                   users/{friendUid}/sharedCategoryAccess/{myUid} = null (best-effort)
  → _syncRemoteFriendState()
```

> Bước "phía bạn" là best-effort; nếu Firebase rules không cho phép, bạn sẽ tự dọn khi `_friendsWatcher` phát hiện bị xoá.

---

### 4. Chia sẻ danh mục (Category Sharing)

#### Share

```
FirebaseService.shareCategory(friendUid, categoryId)
  → users/{ownerUid}/sharedWith/{friendUid}/{categoryId} = true
  → users/{friendUid}/sharedCategoryAccess/{ownerUid}/{categoryId} = ServerValue.timestamp
```

#### Unshare

```
FirebaseService.unshareCategory(friendUid, categoryId)
  → xoá users/{ownerUid}/sharedWith/{friendUid}/{categoryId}
  → xoá users/{friendUid}/sharedCategoryAccess/{ownerUid}/{categoryId}
```

#### Xem danh mục được chia sẻ (`SharedCategoriesPage`)

- `SharedCategoryController.loadSharedCategories()` → `FirebaseService.getSharedCategoriesFromFriends()` đọc `sharedCategoryAccess`.
- Kết quả được **cache tĩnh** (`_cachedList`) — invalidate khi có thay đổi real-time.
- `openSharedCategory(category)` → stream realtime `watchSharedCategoryLinks(ownerUid, categoryId)`.

---

## Luồng dữ liệu & Cache

```
Firebase Realtime DB
       │
       ▼
FirebaseService.getRemoteFriends()
       │
       ▼
FriendRepository.replaceAll(list)
  ├── DbHelper.clearTable('friends')
  ├── DbHelper.upsertAll(merged)    ← SQLite (persistent)
  └── AppCache.setFriends(merged)   ← In-memory RxList (reactive)
                   │
                   ▼
           ever(AppCache.friends, _applyFilters)
                   │
                   ▼
        FriendController.visibleFriends  ← UI reactive
```

**Chiến lược cache:** Write-through. Đọc luôn từ memory, ghi xuống SQLite trước rồi cập nhật cache.

---

## Real-time Watchers (FriendController)

| Watcher                  | Firebase path                              | Mục đích                                         |
|--------------------------|--------------------------------------------|--------------------------------------------------|
| `_requestWatcher`        | `users/{uid}/friendRequests`               | Badge & notification lời mời đến                |
| `_sharedCategoryWatcher` | `users/{uid}/sharedCategoryAccess`         | Badge & notification danh mục được chia sẻ mới  |
| `_friendsWatcher`        | `users/{uid}/friends` (count only)         | Phát hiện khi bị ai đó chấp nhận lời mời        |
| `_linkCountWatchers`     | `users/{ownerUid}/categories/{catId}/links`| Phát hiện link mới trong danh mục bạn share     |

Tất cả watcher được **huỷ** khi đăng xuất và **khởi động lại** khi đăng nhập (qua `_authSub`).

---

## Lifecycle Controller

```
onInit()
  ├── fetchFriends()              ← Load SQLite → sync Firebase
  ├── _startRequestWatcher()
  ├── _startSharedCategoryWatcher()
  ├── _startFriendsWatcher()
  └── _authSub = authStateChanges.listen(...)
        ├── user != null → fetchFriends() + restart watchers
        └── user == null → cancel watchers + clear state

onClose()
  └── cancel all subscriptions
```

### fetchFriends()

```
FriendRepository.ensureLoaded()   ← SQLite (chỉ load 1 lần)
  ↓
_syncRemoteFriendState()
  ↓
Future.wait([
  getRemoteFriends(),             ← Firebase
  getIncomingFriendRequests(),    ← Firebase
  getOutgoingFriendRequestUserIds()
])
  ↓
FriendRepository.replaceAll(remoteFriends)
  ↓
_applyFilters() → visibleFriends
```

---

## Notification & Badge

| Sự kiện                             | Badge tăng                | Notification local         |
|-------------------------------------|---------------------------|----------------------------|
| Lời mời mới đến                     | `pendingRequestCount`     | `showFriendRequestNotification` |
| Danh mục mới được chia sẻ           | `pendingSharedCount`      | `showSharedCategoryNotification` |
| Link mới trong danh mục được share  | `pendingSharedCount`      | `showSharedCategoryNotification` |

Badge `pendingSharedCount` được reset khi user mở `SharedCategoriesPage` (`markSharedCategoriesAsSeen()`). Trạng thái "đã xem" được lưu local qua `AppGetStorage.setSeenSharedKeys(uid, keys)`.

---

## Bộ lọc & Tìm kiếm

`_applyFilters()` lọc `AppCache.friends` theo:
- `favoritesOnly` — chỉ hiển thị bạn đã đánh dấu yêu thích.
- `searchController.text` — tìm theo `displayName`, `email`, hoặc `friendUserId`.

Kết quả gán vào `visibleFriends` (reactive) → UI tự cập nhật.

---

## Files liên quan

| File | Vai trò |
|------|---------|
| `lib/features/friend/presentation/controller/friend_controller.dart` | Controller chính |
| `lib/features/friend/presentation/controller/shared_category_controller.dart` | Controller danh mục được chia sẻ |
| `lib/features/friend/presentation/page/friend_page.dart` | UI trang bạn bè |
| `lib/features/friend/presentation/page/shared_categories_page.dart` | UI trang danh mục được chia sẻ |
| `lib/features/friend/application/model/friend_model.dart` | Model bạn bè |
| `lib/features/friend/application/model/friend_request_model.dart` | Model lời mời kết bạn |
| `lib/features/friend/application/model/shared_category_model.dart` | Model danh mục được chia sẻ |
| `lib/features/friend/application/di/friend_binding.dart` | DI binding |
| `lib/core/service/firebase_service.dart` | Firebase API (friends, requests, sharing) |
| `lib/core/service/friend_connection_service.dart` | Build/parse deep link kết bạn |
| `lib/core/repository/friend_repository.dart` | SQLite + AppCache CRUD |
| `lib/core/cache/app_cache.dart` | In-memory reactive cache |
