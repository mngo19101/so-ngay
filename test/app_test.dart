import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_ngay/logic.dart';
import 'package:so_ngay/main.dart';
import 'package:so_ngay/models.dart';
import 'package:so_ngay/screens/flashcards.dart';
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

  testWidgets('kho từ vựng: riêng từng bộ, tìm kiếm và xoá', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.load();
    final a = store.addDeck('Kho A');
    final b = store.addDeck('Kho B');
    store.addCard(a.id, 'apple', 'quả táo');
    store.addCard(a.id, 'book', 'quyển sách');
    store.addCard(b.id, 'cat', 'con mèo');
    await tester.pumpWidget(MaterialApp(home: VocabBankScreen(deckId: a.id)));
    expect(find.text('apple'), findsOneWidget);
    expect(find.text('book'), findsOneWidget);
    expect(find.text('cat'), findsNothing);

    await tester.enterText(find.byType(TextField), 'SÁCH');
    await tester.pump();
    expect(find.text('apple'), findsNothing);
    expect(find.text('book'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();
    expect(store.deckCards(a.id).map((c) => c.word), ['apple']);
    expect(store.deckCards(b.id).map((c) => c.word), ['cat']);
    expect(find.text('Không tìm thấy từ nào'), findsOneWidget);
  });

  testWidgets('lịch nhắc không phụ thuộc việc mở app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.load();
    final t = store.today;
    store.settings.morningEnabled = true;
    store.settings.studyReminder = true;
    store.specialDays = [
      SpecialDay(id: 'sol', name: 'Sinh nhật', day: 15, month: 6, remindOffsetsDays: [0]),
      SpecialDay(id: 'leap', name: 'Đầu tháng 3', day: 1, month: 3, remindOffsetsDays: [1]),
      SpecialDay(id: 'lun', name: 'Giỗ', calendar: 'lunar', day: 3, month: 2, remindOffsetsDays: [0]),
      SpecialDay(id: 'wk', name: 'Học nhóm', day: 1, month: 1, repeat: 'weekly', repeatWeekdays: [2]),
    ];
    final far = DateTime(t.year + 3, 1, 1, 9);
    store.events = [Event(id: 'e', title: 'Xa', start: far, remindBeforeMin: [0])];
    final plan = store.buildPlan();
    String? rep(String key) => plan.firstWhere((p) => p.key == key).repeat;
    expect(rep('morning'), 'daily');
    expect(rep('study'), 'daily');
    expect(rep('sd_sol_0'), 'yearly');
    expect(rep('sd_wk_0_w2'), 'weekly');
    // Âm lịch và ngày lệch theo năm nhuận không lặp được: đặt nhiều lần trước.
    expect(plan.where((p) => p.key.startsWith('sd_lun_0_')).length, greaterThan(3));
    expect(plan.where((p) => p.key.startsWith('sd_leap_1_')).length, greaterThan(3));
    expect(plan.any((p) => p.key == 'ev_e_0' && p.when == far), isTrue);
    expect(store.droppedReminders, 0);

    store.specialDays = [
      for (var i = 0; i < 80; i++) SpecialDay(id: 's$i', name: 'n$i', day: 1 + i % 28, month: 1 + i % 12),
    ];
    final full = store.buildPlan();
    expect(full.length, lessThanOrEqualTo(63));
    expect(full.any((p) => p.key == 'ev_e_0'), isTrue);
    expect(store.droppedReminders, greaterThan(0));
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
