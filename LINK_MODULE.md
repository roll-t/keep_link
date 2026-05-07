# Link Module — Linkeep

## Tổng quan

Module **Link** là trung tâm của ứng dụng — cho phép người dùng lưu, xem, chỉnh sửa, xoá và tìm kiếm các liên kết. Toàn bộ dữ liệu được cache hai lớp: **SQLite** (persistent) và **AppCache** (in-memory reactive), với chiến lược **write-through**.

---

## Cấu trúc thư mục

```
lib/features/link/
├── application/
│   ├── model/
│   │   ├── link_model.dart          ← Model chính
│   │   ├── link_type.dart           ← Phân loại link (video/document/news)
│   │   ├── meta_data_model.dart     ← Metadata OG/SEO
│   │   └── author_model.dart        ← Tác giả (TikTok)
│   └── usecase/                     ← (Chưa dùng)
└── module/
    ├── link_add/                    ← Thêm / Chỉnh sửa link
    ├── link_colections/             ← Trang chính danh sách link
    ├── link_detail/                 ← Chi tiết & WebView
    └── link_search/                 ← Tìm kiếm nâng cao

lib/core/repository/link_repository.dart  ← Data access layer
```

---

## Models

### LinkModel

SQLite table: `links`

| Field           | SQLite column  | Kiểu         | Mô tả                              |
|-----------------|----------------|--------------|------------------------------------|
| `id`            | `id`           | TEXT PK      | Timestamp ms khi tạo               |
| `name`          | `name`         | TEXT         | Tiêu đề do người dùng đặt          |
| `image`         | `image`        | TEXT         | URL ảnh thumbnail (override)       |
| `metaDataModel` | `metaData`     | TEXT (JSON)  | Metadata OG được fetch tự động     |
| `categoryId`    | `categoryId`   | TEXT FK      | FK → `categories(id) ON DELETE SET NULL` |
| `createdAt`     | `createdAt`    | TEXT ISO8601 | Ngày tạo                           |
| `updatedAt`     | `updatedAt`    | TEXT ISO8601 | Ngày cập nhật gần nhất             |

### MetaDataModel

Được lưu dưới dạng JSON string trong cột `metaData`.

| Field         | Map key        | Mô tả                          |
|---------------|----------------|--------------------------------|
| `url`         | `URL`          | URL gốc                        |
| `title`       | `TITLE`        | Tiêu đề trang (OG title)       |
| `description` | `DESCRIPTION`  | Mô tả (OG description)         |
| `imageUrl`    | `IMAGE_URL`    | Ảnh thumbnail (OG image)       |
| `favicon`     | `FAVICON`      | Favicon URL                    |
| `appleIcon`   | `APPLE_ICON`   | Apple touch icon URL           |
| `address`     | `ADDRESS`      | Địa chỉ (dùng cho maps)        |

### LinkType

Phân loại tự động dựa trên URL:

| Type       | Nguồn                                                          |
|------------|----------------------------------------------------------------|
| `video`    | YouTube, TikTok, Vimeo, Facebook Watch, Instagram Reel, X/Twitter... |
| `document` | Google Docs/Drive, Notion, GitHub, StackOverflow, các file .pdf/.docx... |
| `news`     | Mặc định (mọi URL không khớp ở trên)                          |

### AuthorModel

Dùng cho TikTok metadata. Không lưu trong SQLite, chỉ dùng trong runtime.

---

## LinkRepository

**Chiến lược: Write-through — đọc từ memory, ghi xuống SQLite trước rồi cập nhật cache.**

```
lib/core/repository/link_repository.dart
```

### Khởi tạo cache

```
LinkRepository.ensureLoaded()
  → AppCache.linksLoaded? → skip
  → DbHelper.getAll('links', orderBy: createdAt DESC)
  → AppCache.setLinks(list)
```

Chỉ đọc SQLite **một lần duy nhất** trong toàn bộ session.

### CRUD

| Method               | SQLite            | AppCache                    | Sync Firebase           |
|----------------------|-------------------|-----------------------------|-------------------------|
| `insert(link)`       | `upsert`          | `addLink` (prepend)         | `trackLinkUpsert` + `pushNow` |
| `update(link)`       | `update`          | `updateLink` (in-place)     | `trackLinkUpsert` + `pushNow` |
| `delete(id)`         | `delete`          | `removeLink`                | `trackLinkDelete` + `pushNow` |
| `ensureLoaded()`     | `getAll` (1 lần)  | `setLinks`                  | —                       |

### Phân trang (in-memory)

```
getFilteredPage(categoryId, privateCategoryIds, excludePrivate, page, pageSize)
  → lọc AppCache.links theo privacy + category
  → skip(page * pageSize).take(pageSize)
```

---

## Các module con

---

### 1. link_add — Thêm / Chỉnh sửa link

**Files:**
- `presentation/controller/add_link_controller.dart`
- `presentation/page/add_link_page.dart`
- `presentation/widgets/deep_link_preview.dart`

#### Luồng Thêm link

```
User nhập URL
  → onChangeLink(url)
  → _extractUrl(input)      ← Tách URL ra khỏi text hỗn hợp (regex)
  → debounce 150ms
  → DeepLinkController.fetchMetaData(url)   ← fetch OG metadata
  → ever(_deepLink.metaData) → tự điền titleController
  → User nhấn "Lưu" → validateInput()
  → LinkRepository.insert(link)
  → Close page (result: true)
```

#### Luồng Chỉnh sửa link

```
Truyền LinkModel qua arguments (ArgumentHandlerMixinController)
  → isEditModel = true
  → Điền lại linkController, titleController, popup category
  → User nhấn "Lưu" → updateLink()
  → LinkRepository.update(link)
  → Close page (result: true)
```

#### Luồng mở từ Share Intent (Deep Link)

```
DeepLinkService.isOpenedFromShare = true
  → deepLink.deepLink != null → điền sẵn linkController
  → User lưu → addLink()
  → Android: SystemNavigator.pop() (đóng app về launcher)
  → iOS: Get.back()
```

#### Clipboard

```
onPasteClipboard()
  → Clipboard.getData()
  → _extractUrl(text)        ← Tách URL khỏi text (regex)
  → Nếu còn text thừa → điền vào titleController
  → onChangeLink(url)
```

#### Validation

| Điều kiện                           | Lỗi                              |
|-------------------------------------|----------------------------------|
| Category chưa chọn (chọn "all")     | Dialog cảnh báo "Hãy chọn danh mục" |
| Link trống                          | `errorLinkMess`: "Link không được để trống" |
| Link không hợp lệ (không có http/https) | `errorLinkMess`: "Link không hợp lệ" |
| Tiêu đề trống                       | `errorTitleMess`: "Tiêu đề không được để trống" |

---

### 2. link_colections — Danh sách link (Trang chính)

**Files:**
- `presentation/controller/link_collection_controller.dart`
- `presentation/controller/header_link_collection_controller.dart`

#### Luồng hiển thị

```
onInit()
  → refreshData()
      → _currentPage = 0, listLink.clear()
      → fetchAllLinks(isInitial: true)
          → LinkRepository.ensureLoaded()    ← SQLite (1 lần)
          → CategoryRepository.ensureLoaded()
          → LinkRepository.getFilteredPage(...)  ← in-memory
          → listLink.addAll(page)
          → _currentPage++
```

#### Phân trang (Infinite Scroll)

```
ScrollController.addListener(_scrollListener)
  → pixels >= maxScrollExtent - 200
  → loadMore() → fetchAllLinks(isInitial: false)
```

Mỗi page: **20 items** (`_pageSize = 20`).

#### Lọc theo bảo mật

```
isSecurityEnabled && isAllCategory (chọn "All")
  → excludePrivate = true → bỏ qua link thuộc category riêng tư
isSecurityEnabled && chọn category cụ thể
  → excludePrivate = false → hiển thị đủ (đã qua PIN check)
```

#### Xoá link

```
onDeleteLink(id)
  → Dialog xác nhận
  → LinkRepository.delete(id)
  → listLink.removeWhere(id)
  → Get.back() x2 (đóng dialog + đóng detail page)
```

---

### 3. link_detail — Chi tiết & WebView

**Files:**
- `presentation/controller/link_detail_controller.dart`

#### Hiển thị nội dung

| `LinkType` | Hiển thị                                        |
|------------|-------------------------------------------------|
| `video`    | Thumbnail + nút Play → mở WebView inline        |
| `document` | Card metadata + nút mở WebView                 |
| `news`     | Card metadata (ảnh, tiêu đề, mô tả) + WebView  |

#### WebView

- **User Agent**: Mobile Chrome (Android) cho tất cả link thông thường; iOS Safari UA riêng cho TikTok.
- **Cache**: `LOAD_CACHE_ELSE_NETWORK` — ưu tiên cache, giảm latency.
- **Ad Blocker**: Chặn tầng mạng (domain block) + tiêm JS xoá DOM quảng cáo.
- **TikTok**: Tiêm JS ẩn banner "Mở trong app", chặn popup download, dùng MutationObserver.
- **Điều hướng**: Back/Forward qua `webViewController`, nút reload, nút về trang gốc.

#### Các action

| Action           | Mô tả                                            |
|------------------|--------------------------------------------------|
| `copyUrl()`      | Copy URL vào clipboard                           |
| `openInApp()`    | Mở trong trình duyệt hệ thống                   |
| `openInMaps()`   | Mở Google Maps với địa chỉ trong metadata        |
| `goToEdit()`     | Điều hướng sang `AddLinkPage` với link hiện tại |
| `deleteLink()`   | Uỷ quyền cho `LinkCollectionController`          |

---

### 4. link_search — Tìm kiếm nâng cao

**Files:**
- `presentation/controller/search_link_controller.dart`

#### Tính năng

- Tìm kiếm full-text: tiêu đề, tên ghi chú, URL — **không phân biệt dấu** (`removeDiacritics`).
- Debounce **300ms** — tránh query quá nhanh.
- Lọc đa chiều: **category**, **nguồn** (domain), **khoảng thời gian**.
- Sắp xếp: Mới nhất / Cũ nhất / A→Z / Z→A.
- **Top sources**: tự tính top 5 domain từ cache.
- **Gợi ý & lịch sử** tìm kiếm (lưu `GetStorage`, tối đa 20 mục).
- Tôn trọng cài đặt bảo mật (ẩn link private).

#### Luồng tìm kiếm

```
searchTec.addListener → searchText.value = text
debounce 300ms → _runSearch() + _computeSuggestions()

_runSearch()
  → AppCache.links
      .where(_passPrivacyFilter)
      .where(_passCategoryFilter)
      .where(_passSourceFilter)
      .where(_passDateFilter)
      .where(_matchSearch)    ← full-text diacritics-insensitive
  → _applySorting()
  → searchResults.assignAll(...)
```

#### Lịch sử & Gợi ý

```
User chọn suggestion/history → applyQuery(text)
  → Fill searchTec
  → _saveToHistory(text)     ← lưu GetStorage
  → _runSearch()
  → suggestions.clear()
  → unfocus keyboard
```

---

## Luồng dữ liệu tổng quát

```
┌──────────────┐    insert/update/delete    ┌──────────────┐
│ AddLink /    │ ─────────────────────────► │ LinkRepo     │
│ LinkDetail   │                            │  .insert()   │
└──────────────┘                            │  .update()   │
                                            │  .delete()   │
                                            └──────┬───────┘
                                                   │ write-through
                              ┌────────────────────┼────────────────────┐
                              ▼                    ▼                    ▼
                         ┌─────────┐        ┌──────────┐       ┌──────────────┐
                         │ SQLite  │        │ AppCache │       │ SessionSync  │
                         │ (disk)  │        │(RxList)  │       │  (Firebase)  │
                         └─────────┘        └────┬─────┘       └──────────────┘
                                                 │ reactive
                              ┌──────────────────┼──────────────────┐
                              ▼                  ▼                  ▼
                    LinkCollection        LinkSearch         CategoryController
                    Controller            Controller         (recompute counts)
```

---

## Cache lifecycle

| Sự kiện            | Hành động                                                  |
|--------------------|-------------------------------------------------------------|
| App khởi động      | `AppCache.linksLoaded = false` (cache trống)               |
| Mở trang đầu tiên  | `LinkRepository.ensureLoaded()` → đọc SQLite → warm cache  |
| Mở lại trang       | Cache warm → bỏ qua SQLite, dùng in-memory                 |
| Thêm/Sửa/Xoá      | SQLite + AppCache cập nhật đồng thời (write-through)        |
| Đăng xuất          | `AppCache.invalidateAll()` → xoá toàn bộ cache             |
| Đăng nhập lại      | `SessionSyncService.syncAfterLogin()` → merge + pull Firebase → warm lại cache |

---

## Đồng bộ Firebase (SessionSyncService)

Mỗi thao tác write sẽ:
1. **`trackLinkUpsert(link)`** / **`trackLinkDelete(id)`** — thêm vào in-memory queue.
2. **`pushNow()`** — đẩy toàn bộ queue lên Firebase ngay lập tức (fire-and-forget).
3. Nếu push thất bại → queue được persist vào `GetStorage` và retry khi mở lại app.

---

## Files liên quan

| File | Vai trò |
|------|---------|
| `lib/features/link/application/model/link_model.dart` | Model SQLite |
| `lib/features/link/application/model/meta_data_model.dart` | OG Metadata |
| `lib/features/link/application/model/link_type.dart` | Phân loại link |
| `lib/features/link/application/model/author_model.dart` | Tác giả TikTok |
| `lib/features/link/module/link_add/presentation/controller/add_link_controller.dart` | Thêm/Sửa link |
| `lib/features/link/module/link_add/presentation/page/add_link_page.dart` | UI thêm/sửa |
| `lib/features/link/module/link_colections/presentation/controller/link_collection_controller.dart` | Danh sách + phân trang |
| `lib/features/link/module/link_detail/presentation/controller/link_detail_controller.dart` | Chi tiết + WebView |
| `lib/features/link/module/link_search/presentation/controller/search_link_controller.dart` | Tìm kiếm nâng cao |
| `lib/core/repository/link_repository.dart` | Data access layer |
| `lib/core/cache/app_cache.dart` | In-memory reactive cache |
| `lib/core/cache/sql_lite.dart` | SQLite helper |
| `lib/core/service/session_sync_service.dart` | Đồng bộ Firebase |
