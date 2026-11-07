# Sổ Ngày

Ứng dụng Flutter (iPhone): lịch + âm lịch, ngày đặc biệt có thông báo cục bộ, flashcard từ vựng 4 trò dò lại, theo dõi giờ học và biểu đồ. Chạy offline, dữ liệu lưu trên máy.

## Lấy file IPA chưa ký
1. Tab **Actions** → **Build unsigned IPA** → **Run workflow** (hoặc push lên `main`).
2. Đợi ~10–15 phút, tải artifact **SoNgay-unsigned-ipa**.
3. Mở ESign → nhập `SoNgay-unsigned.ipa` → ký và cài.

## Chạy test
```
flutter pub get
flutter analyze
flutter test
```
