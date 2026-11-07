import 'package:flutter_test/flutter_test.dart';
import 'package:so_ngay/lunar.dart';

void main() {
  test('Tết 2026 = 17/02/2026', () {
    expect(Lunar.toSolar(1, 1, 2026), DateTime(2026, 2, 17));
  });
  test('Tết 2027 = 06/02/2027', () {
    expect(Lunar.toSolar(1, 1, 2027), DateTime(2027, 2, 6));
  });
  test('Tết 2025 = 29/01/2025', () {
    expect(Lunar.toSolar(1, 1, 2025), DateTime(2025, 1, 29));
  });
  test('7/11/2026 là 29/9 âm (mockup tính tay lệch 1)', () {
    final l = Lunar.fromSolar(DateTime(2026, 11, 7));
    expect([l.day, l.month, l.year], [29, 9, 2026]);
  });
  test('Chuyển đổi hai chiều', () {
    final l = Lunar.fromSolar(DateTime(2026, 2, 17));
    expect([l.day, l.month, l.year, l.leap], [1, 1, 2026, false]);
  });
  test('Tên năm', () {
    expect(Lunar.yearName(2026), 'Bính Ngọ');
  });
  test('Năm nhuận 2023 có tháng 2 nhuận', () {
    expect(Lunar.leapMonthOf(2023), 2);
    expect(Lunar.leapMonthOf(2026), 0);
  });
}
