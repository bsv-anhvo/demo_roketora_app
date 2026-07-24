# So sánh tốc độ xử lý: `captureDualPhoto` vs `captureDualPhoto2`

Tài liệu này so sánh hai hàm chụp ảnh trong `lib/providers/camera/take_photo_notifier.dart`, tập trung vào **thời gian xử lý sau khi nhấn nút chụp** — yêu cầu chính là không để người dùng chờ quá lâu.

| | `captureDualPhoto` (dòng 78) | `captureDualPhoto2` (dòng 133) |
|---|---|---|
| **Mục tiêu** | Chụp ảnh gốc sạch, xử lý hậu kỳ đầy đủ trong app | Chụp nhanh, tận dụng luồng có sẵn của `PhotoCameraState` |
| **API chụp** | `CamerawesomePlugin.takePhoto()` trực tiếp | `photoState.takePhoto()` (wrapper của plugin) |
| **Số bước xử lý ảnh (Dart)** | 3–4 lần decode/encode JPEG | 0–1 lần (chỉ copy file) |
| **Ước lượng độ trễ thêm** | Cao (~500ms–2s+ tùy máy & độ phân giải) | Thấp (~50–200ms chủ yếu là copy file) |
| **Phù hợp yêu cầu tốc độ** | ❌ Chậm hơn | ✅ Nhanh hơn |

---

## Luồng xử lý từng bước

### `captureDualPhoto` — luồng đầy đủ (chậm hơn)

| # | Bước | Loại tác vụ | Độ nặng | Ghi chú |
|---|---|---|---|---|
| 1 | `setFilter(None)` | Native bridge | Nhẹ | Tắt filter preview trước khi chụp |
| 2 | `CamerawesomePlugin.takePhoto()` | Hardware + I/O | Trung bình | Chụp ảnh thật sự (không thể bỏ) |
| 3 | `normalizeOrientation()` | **Decode → encode JPEG** | **Nặng** | Đọc toàn bộ file, xử lý pixel, ghi lại |
| 4 | `centerCropToPortraitRatio()` *(nếu aspect ratio cần crop)* | **Decode → encode JPEG** | **Nặng** | Thêm 1 vòng xử lý ảnh full-size |
| 5 | `File.copy()` | Disk I/O | Trung bình | Copy file gốc sang path filter |
| 6 | `applyToFile(filter)` | **Decode → filter → encode** | **Nặng** | Áp filter bằng `image` package trong Dart |
| 7 | `registerPhotoCapture()` | DB + metadata I/O | Trung bình | Ghi timestamp vào 2 file + database |
| 8 | `setFilter(activeFilter)` | Native bridge | Nhẹ | Khôi phục filter preview |

**Tổng:** Sau bước chụp hardware, còn **ít nhất 3 lần** đọc/ghi và xử lý toàn bộ ảnh JPEG trong Dart (normalize → crop → filter).

---

### `captureDualPhoto2` — luồng tối giản (nhanh hơn)

| # | Bước | Loại tác vụ | Độ nặng | Ghi chú |
|---|---|---|---|---|
| 1 | `photoState.takePhoto()` | Hardware + I/O + filter plugin | Trung bình | Gộp chụp + path builder; filter do plugin xử lý (iOS) |
| 2 | Lấy path từ `CaptureRequest` | In-memory | Rất nhẹ | Chỉ đọc metadata request |
| 3 | `File.copy()` *(nếu path khác nhau)* | Disk I/O | Trung bình | Tạo bản `photo_*.jpg` từ `photo_original_*.jpg` |

**Tổng:** Sau bước chụp, **không có** vòng decode/encode JPEG nào trong app layer.

---

## Bảng so sánh chi tiết theo hạng mục

| Hạng mục | `captureDualPhoto` | `captureDualPhoto2` | Ảnh hưởng tốc độ |
|---|---|---|---|
| Chụp qua plugin | ✅ | ✅ | Tương đương (cùng native capture) |
| Tắt/khôi phục filter trước-sau chụp | ✅ `setFilter` 2 lần | ❌ | `captureDualPhoto2` tiết kiệm ~2 round-trip native |
| Chuẩn hóa orientation (EXIF → pixel) | ✅ `normalizeOrientation` | ❌ | Tiết kiệm 1 lần decode/encode (~100–400ms) |
| Crop theo aspect ratio (software) | ✅ *(có điều kiện)* | ❌ | Tiết kiệm thêm 1 lần decode/encode nếu bật |
| Áp filter sau chụp (Dart) | ✅ `applyToFile` | ❌ *(plugin xử lý khi chụp)* | Tiết kiệm 1 lần decode/filter/encode (~150–500ms) |
| Copy file tạo bản filter | ✅ | ✅ | Tương đương |
| Ghi metadata capture | ✅ `registerPhotoCapture` | ❌ | Tiết kiệm I/O DB + 2 file metadata |
| Ảnh gốc không filter | ✅ Chụp với `Filter.None` | ⚠️ Filter có thể đã bake vào file | Không ảnh hưởng tốc độ, nhưng khác chất lượng/luồng |
| Aspect ratio chính xác (crop software) | ✅ | ⚠️ Phụ thuộc preview native | Trade-off chất lượng vs tốc độ |

---

## Ước lượng thời gian (tham khảo)

> Các con số dưới đây là **ước lượng tương đối**, không benchmark thực tế. Thời gian phụ thuộc thiết bị, độ phân giải ảnh và filter đang chọn.

| Giai đoạn | `captureDualPhoto` | `captureDualPhoto2` |
|---|---|---|
| Chụp hardware (native) | ~200–800ms | ~200–800ms |
| Xử lý ảnh sau chụp (Dart) | ~400–1500ms | ~0ms |
| Copy file | ~20–100ms | ~20–100ms |
| Metadata / DB | ~30–150ms | ~0ms |
| Filter toggle native | ~20–80ms | ~0ms |
| **Tổng ước lượng** | **~700–2600ms** | **~250–950ms** |

**Chênh lệch ước tính:** `captureDualPhoto2` nhanh hơn khoảng **400–1500ms** mỗi lần chụp (chủ yếu nhờ bỏ xử lý ảnh full-size trong Dart).

---

## Tại sao `captureDualPhoto2` nhanh hơn?

1. **Không decode/encode JPEG lặp lại** — `captureDualPhoto` mỗi bước (`normalizeOrientation`, `centerCrop`, `applyToFile`) đều đọc toàn bộ ảnh vào RAM, xử lý pixel, rồi ghi lại file.
2. **Ít round-trip native hơn** — không cần `setFilter(None)` → chụp → `setFilter(restore)`.
3. **Không ghi metadata ngay** — bỏ qua `registerPhotoCapture` (DB + ghi EXIF sidecar).
4. **Ủy quyền cho plugin** — `takePhoto()` gộp path builder + capture + filter handler trong một luồng.

---

## Trade-off cần lưu ý

| Tiêu chí | `captureDualPhoto` | `captureDualPhoto2` |
|---|---|---|
| Tốc độ phản hồi sau chụp | Chậm | **Nhanh** ✅ |
| Ảnh gốc thật sự (không filter) | Có | Có thể đã có filter từ plugin |
| Crop aspect ratio chính xác | Có (software crop) | Không |
| Metadata capture timestamp | Có | Không |
| Orientation chuẩn hóa | Có | Không (phụ thuộc output native) |

---

## Kết luận

| | |
|---|---|
| **Yêu cầu** | Chụp hình không để thời gian xử lý quá lâu |
| **Khuyến nghị** | Dùng **`captureDualPhoto2`** cho luồng chụp chính |
| **Khi nào giữ `captureDualPhoto`** | Khi cần ảnh gốc sạch, crop aspect ratio chính xác, hoặc metadata capture đầy đủ — chấp nhận đổi lại thời gian chờ |

---

*Tạo ngày: 2026-07-20 · File nguồn: `lib/providers/camera/take_photo_notifier.dart`*
