import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_ngay/logic.dart';
import 'package:so_ngay/main.dart';
import 'package:so_ngay/models.dart' hide Card;
import 'package:so_ngay/models.dart' as m show Card;
import 'package:so_ngay/screens/event_sheet.dart';
import 'package:so_ngay/screens/flashcards.dart';
import 'package:so_ngay/screens/shell.dart';
import 'package:so_ngay/store.dart';
import 'package:so_ngay/theme.dart';

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
    expect(plan.where((p) => p.key.startsWith('study_')).length, greaterThan(10));
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

  test('sự kiện lặp: hằng ngày, theo thứ, đến ngày, bỏ ngày', () {
    final start = DateTime(2026, 11, 9, 8); // Thứ Hai
    final daily = Event(id: 'd', title: 'x', start: start, repeat: 'daily', repeatUntil: DateTime(2026, 11, 12));
    expect(eventOccursOn(daily, DateTime(2026, 11, 8)), isFalse);
    expect(eventOccursOn(daily, DateTime(2026, 11, 9)), isTrue);
    expect(eventOccursOn(daily, DateTime(2026, 11, 12)), isTrue);
    expect(eventOccursOn(daily, DateTime(2026, 11, 13)), isFalse);

    final weekly = Event(id: 'w', title: 'x', start: start, repeat: 'weekly', repeatWeekdays: [1, 3]);
    expect(eventOccursOn(weekly, DateTime(2026, 11, 11)), isTrue);
    expect(eventOccursOn(weekly, DateTime(2026, 11, 10)), isFalse);
    weekly.skipDates = ['2026-11-11'];
    expect(eventOccursOn(weekly, DateTime(2026, 11, 11)), isFalse);
    expect(eventOccursOn(weekly, DateTime(2026, 11, 16)), isTrue);
    expect(eventOccurrencesFrom(weekly, DateTime(2026, 11, 9), 2), [DateTime(2026, 11, 9), DateTime(2026, 11, 16)]);

    final once = Event(id: 'o', title: 'x', start: start);
    expect(eventOccursOn(once, DateTime(2026, 11, 9)), isTrue);
    expect(eventOccursOn(once, DateTime(2026, 11, 16)), isFalse);

    // Dữ liệu cũ chưa có các trường lặp vẫn đọc được; dữ liệu mới giữ nguyên.
    final old = Event.fromJson({'id': 'o', 'title': 'x', 'start': start.toIso8601String()});
    expect(old.repeat, 'none');
    final back = Event.fromJson(daily.toJson());
    expect(back.repeat, 'daily');
    expect(back.repeatUntil, DateTime(2026, 11, 12));
  });

  testWidgets('nhắc sự kiện lặp: dùng lịch iOS khi được, không thì đặt từng ngày', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.load();
    store.specialDays = [];
    store.cards = [];
    final t = store.today;
    final past = addDays(t, -30);
    final at = DateTime(past.year, past.month, past.day, 9);
    store.events = [
      Event(id: 'a', title: 'A', start: at, remindBeforeMin: [10], repeat: 'daily'),
      Event(id: 'b', title: 'B', start: at, remindBeforeMin: [10], repeat: 'weekly', repeatWeekdays: [1, 4]),
      Event(id: 'c', title: 'C', start: at, remindBeforeMin: [10], repeat: 'daily', repeatUntil: addDays(t, 5)),
      Event(id: 'd', title: 'D', start: at, remindBeforeMin: [10], repeat: 'daily', skipDates: [isoDate(addDays(t, 2))]),
    ];
    final plan = store.buildPlan();
    expect(plan.singleWhere((p) => p.key == 'ev_a_10_d').repeat, 'daily');
    expect(plan.singleWhere((p) => p.key == 'ev_b_10_w1').repeat, 'weekly');
    expect(plan.singleWhere((p) => p.key == 'ev_b_10_w4').repeat, 'weekly');
    final c = plan.where((p) => p.key.startsWith('ev_c_10_')).toList();
    expect(c.every((p) => p.repeat == null), isTrue);
    expect(c.every((p) => !p.when.isAfter(DateTime(t.year, t.month, t.day + 5, 9))), isTrue);
    expect(plan.any((p) => p.key == 'ev_d_10_${isoDate(addDays(t, 2))}'), isFalse);
    expect(plan.any((p) => p.key == 'ev_d_10_${isoDate(addDays(t, 3))}'), isTrue);

    // Lịch hôm nay xếp theo giờ dù các sự kiện bắt đầu từ những ngày khác nhau.
    final early = addDays(t, -3);
    store.events = [
      Event(id: 'late', title: 'L', start: DateTime(past.year, past.month, past.day, 18), repeat: 'daily'),
      Event(id: 'early', title: 'E', start: DateTime(early.year, early.month, early.day, 7), repeat: 'daily'),
    ];
    expect(store.eventsOn(t).map((e) => e.id), ['early', 'late']);
  });

  testWidgets('nhắc ôn: đúng giờ đã chọn, đúng số từ, bỏ ngày không có từ', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.load();
    store.specialDays = [];
    store.events = [];
    final t = store.today;
    store.settings.studyReminderTime = '06:30';
    store.cards = [
      m.Card(id: '1', deckId: 'x', word: 'a', meaning: 'a', dueDate: addDays(t, 2)),
      m.Card(id: '2', deckId: 'x', word: 'b', meaning: 'b', dueDate: addDays(t, 3)),
    ];
    final plan = store.buildPlan().where((p) => p.key.startsWith('study_')).toList();
    expect(plan.any((p) => p.key == 'study_${isoDate(addDays(t, 1))}'), isFalse);
    final day2 = plan.singleWhere((p) => p.key == 'study_${isoDate(addDays(t, 2))}');
    expect(day2.body, contains('1 từ'));
    expect(day2.when, DateTime(t.year, t.month, t.day + 2, 6, 30));
    expect(day2.repeat, isNull);
    expect(plan.singleWhere((p) => p.key == 'study_${isoDate(addDays(t, 3))}').body, contains('2 từ'));
    // Không mở app lâu vẫn còn nhắc, sau 2 tuần thì thưa dần.
    expect(plan.any((p) => p.when.isAfter(addDays(t, 40))), isTrue);

    store.settings.studyReminder = false;
    expect(store.buildPlan().any((p) => p.key.startsWith('study_')), isFalse);
  });

  testWidgets('xoá sự kiện lặp: chỉ một ngày hoặc cả chuỗi', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.load();
    final t = store.today;
    final e = Event(id: 'r', title: 'Lặp', start: DateTime(t.year, t.month, t.day, 9), repeat: 'daily');
    store.events = [e];
    final tomorrow = addDays(t, 1);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: EventRow(e, on: tomorrow))));

    await tester.longPress(find.text('Lặp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉ ngày ${dm(tomorrow)}'));
    await tester.pumpAndSettle();
    expect(eventOccursOn(e, tomorrow), isFalse);
    expect(eventOccursOn(e, t), isTrue);

    await tester.longPress(find.text('Lặp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cả chuỗi'));
    await tester.pumpAndSettle();
    expect(store.events, isEmpty);
  });

  testWidgets('tạo sự kiện lặp hằng tuần qua biểu mẫu', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.load();
    store.events = [];
    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final date = store.today;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (c) => TextButton(onPressed: () => showEventSheet(c, date), child: const Text('mở'))),
      ),
    ));
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Học nhóm');
    await tester.tap(find.text('Hằng tuần'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu sự kiện'));
    await tester.pumpAndSettle();
    final e = store.events.single;
    expect(e.repeat, 'weekly');
    expect(e.repeatWeekdays, [date.weekday]);
    expect(store.eventsOn(addDays(date, 7)).single.id, e.id);
    expect(store.eventsOn(addDays(date, 1)), isEmpty);
  });

  testWidgets('giao diện tối: mở mọi màn hình, đổi không mất trạng thái', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(() => C.dark = false);
    await store.load();
    store.settings.themeMode = 'dark';
    await tester.pumpWidget(const SoNgayApp());
    await tester.pumpAndSettle();
    expect(C.dark, isTrue);
    for (final p in AppPage.values) {
      nav.go(p);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'màn $p');
    }
    Color scaffoldBg() => Theme.of(tester.element(find.byType(Shell))).scaffoldBackgroundColor;
    expect(scaffoldBg(), C.bg);
    expect(scaffoldBg().computeLuminance(), lessThan(0.1));

    // Chữ đã dựng (kể cả widget const) phải đổi màu; biểu mẫu đang nhập phải còn.
    nav.go(AppPage.settings);
    await tester.pumpAndSettle();
    final darkInk = tester.widget<Text>(find.text('Cài đặt')).style!.color;
    await tester.tap(find.text('Sáng'));
    await tester.pumpAndSettle();
    expect(C.dark, isFalse);
    expect(store.settings.themeMode, 'light');
    final lightInk = tester.widget<Text>(find.text('Cài đặt')).style!.color;
    expect(lightInk, isNot(darkInk));
    expect(scaffoldBg().computeLuminance(), greaterThan(0.8));

    nav.go(AppPage.add);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Đang gõ dở');
    store.updateSettings((s) => s.themeMode = 'dark');
    await tester.pumpAndSettle();
    expect(C.dark, isTrue);
    expect(find.text('Đang gõ dở'), findsOneWidget);
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
