import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_ngay/logic.dart';
import 'package:so_ngay/main.dart';
import 'package:so_ngay/models.dart';
import 'package:so_ngay/screens/shell.dart';
import 'package:so_ngay/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nextOccurrence: dương, âm, hằng tuần', () {
    final today = DateTime(2026, 11, 7);
    final solar = SpecialDay(id: 'a', name: 'x', day: 20, month: 11);
    expect(nextOccurrence(solar, today), DateTime(2026, 11, 20));
    final tet = SpecialDay(id: 'b', name: 'Tết', calendar: 'lunar', day: 1, month: 1);
    expect(nextOccurrence(tet, today), DateTime(2027, 2, 6));
    final weekly = SpecialDay(
        id: 'c', name: 'w', day: 1, month: 11, year: 2026, repeat: 'weekly', repeatWeekdays: [1, 5]);
    expect(nextOccurrence(weekly, today), DateTime(2026, 11, 9));
    final leap = SpecialDay(id: 'd', name: '29/2', day: 29, month: 2);
    expect(nextOccurrence(leap, DateTime(2027, 1, 1)), DateTime(2027, 2, 28));
  });

  test('fmtMin', () {
    expect(fmtMin(1040), '17g20p');
    expect(fmtMin(180), '3g');
    expect(fmtMin(30), '30p');
  });

  testWidgets('mở mọi màn hình không lỗi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final loader = FontLoader('BeVietnamPro');
    for (final w in ['Regular', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$w.ttf'));
    }
    await loader.load();
    await store.load();
    await tester.pumpWidget(const SoNgayApp());
    await tester.pumpAndSettle();
    for (final p in AppPage.values) {
      nav.go(p);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'màn $p');
    }
  });

  testWidgets('thêm phiên học và sự kiện', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.load();
    final sid = store.subjects.first.id;
    store.addSession(sid, store.today, 90);
    store.addSession(sid, store.today, -30);
    expect(store.minutesOn(sid, store.today), 60);
    expect(store.streak(), 1);
    final card = store.cards.first;
    store.review(card, true);
    expect(card.intervalDays, 1);
    expect(card.stage, 1);
    store.review(card, true); // ôn sớm: không đổi lịch
    expect(card.stage, 1);
    card.dueDate = store.today;
    store.review(card, true);
    expect(card.intervalDays, 3);
    expect(card.stage, 2);
    store.review(card, false);
    expect(card.intervalDays, 1);
    expect(card.stage, 0);
  });
}
