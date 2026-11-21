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
import 'package:so_ngay/srs.dart';
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
    // Nạp font báo "đổi font hệ thống" bất đồng bộ; chạy trong thời gian thực và
    // chờ thông báo đó tới, rồi pump để khung hình nó đặt không còn treo khi gỡ
    // cây widget (Flutter 3.50 coi đó là animation còn chạy).
    await tester.runAsync(() async {
      await loader.load();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
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
    final t = store.today;
    store.grade(card, Fsrs.good); // từ mới, nhớ → 3 ngày
    expect(card.dueDate, addDays(t, 3));
    expect(card.stage, 1);
    store.grade(card, Fsrs.good); // ôn lại cùng ngày: không giãn thêm
    expect(card.dueDate, addDays(t, 3));
    card.lastReview = addDays(t, -3); // 3 ngày sau, đúng hạn
    card.dueDate = t;
    store.grade(card, Fsrs.good);
    expect(card.intervalDays, greaterThan(8));
    final s = card.stability;
    card.lastReview = addDays(t, -card.intervalDays);
    card.dueDate = t;
    store.grade(card, Fsrs.again);
    expect(card.dueDate, t); // quên → ôn lại ngay hôm nay
    expect(card.stage, 0);
    expect(card.lapses, 1);
    expect(card.stability, lessThan(s));
  });

  test('FSRS: ôn đúng hạn liên tục thì khoảng ôn giãn tới hàng năm; "Khó" ngắn hơn "Nhớ", "Dễ" dài hơn', () {
    var s = 0.0, d = 0.0;
    int? elapsed;
    final gaps = <int>[];
    for (var i = 0; i < 6; i++) {
      final n = Fsrs.next(s, d, elapsed, Fsrs.good);
      s = n.s;
      d = n.d;
      elapsed = n.days;
      gaps.add(n.days);
    }
    for (var i = 1; i < gaps.length; i++) {
      expect(gaps[i], greaterThan(gaps[i - 1]));
    }
    expect(gaps.last, greaterThan(365));
    final hard = Fsrs.next(10, 5, 10, Fsrs.hard).days;
    final good = Fsrs.next(10, 5, 10, Fsrs.good).days;
    final easy = Fsrs.next(10, 5, 10, Fsrs.easy).days;
    expect(hard, lessThan(good));
    expect(easy, greaterThan(good));
    expect(Fsrs.next(10, 5, 10, Fsrs.again).days, 0);
    // Dữ liệu lịch cũ được chuyển sang FSRS.
    final old = m.Card.fromJson({
      'id': 'x', 'deckId': 'd', 'word': 'a', 'meaning': 'b', 'dueDate': '2026-11-28', 'intervalDays': 7, 'ease': 2.5,
    });
    expect(old.stability, 7);
    expect(old.lastReview, DateTime(2026, 11, 21));
    expect(alignTyped('remeber', 'remember').where((x) => !x.$2).map((x) => x.$1), ['_']);
  });

  testWidgets('menu ☰: mở ngăn kéo, chọn tab Ghi chú', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await store.load();
    nav.go(AppPage.today);
    await tester.pumpWidget(const SoNgayApp());
    await tester.pumpAndSettle();
    expect(find.text('Ghi chú'), findsNothing);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Thông báo'), findsOneWidget);
    await tester.tap(find.text('Ghi chú'));
    await tester.pumpAndSettle();
    expect(nav.page, AppPage.notes);
    expect(find.text('Thông báo'), findsNothing); // ngăn kéo đã đóng
  });

  testWidgets('ghi chú: + tự điền ngày, lưu khi rời trang, sửa và xoá', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await store.load();
    store.notes.clear();
    nav.go(AppPage.notes);
    await tester.pumpWidget(const SoNgayApp());
    await tester.pumpAndSettle();

    final before = DateTime.now();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Ghi chú mới'), findsOneWidget);
    expect(find.textContaining('${before.day}/${before.month}/${before.year}'), findsOneWidget);

    // Quay lại khi chưa viết gì thì không tạo ghi chú trống.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(store.notes, isEmpty);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Đi chợ');
    await tester.enterText(find.byType(TextField).at(1), 'Sữa, trứng');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.notes.single.title, 'Đi chợ');
    expect(store.notes.single.body, 'Sữa, trứng');
    expect(store.notes.single.date.difference(before).inMinutes.abs(), lessThan(2));
    expect(find.text('Đi chợ'), findsOneWidget);

    await tester.tap(find.text('Đi chợ'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa ghi chú'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Đi siêu thị');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.notes.single.title, 'Đi siêu thị');

    await tester.tap(find.text('Đi siêu thị'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();
    expect(store.notes, isEmpty);

    final n = Note(id: 'x', title: 't', date: DateTime(2026, 1, 2, 3, 4), updatedAt: DateTime(2026));
    expect(Note.fromJson(n.toJson()).date, DateTime(2026, 1, 2, 3, 4));
  });

  testWidgets('ghi chú: chia nhóm theo tháng, lọc theo tháng bằng bảng chọn', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await store.load();
    store.notes
      ..clear()
      ..addAll([
        Note(id: 'a', title: 'Học triết được cộng điểm', date: DateTime(2026, 11, 21, 15, 14), updatedAt: DateTime(2026)),
        Note(id: 'b', title: 'Hôm nay thi triết', date: DateTime(2026, 11, 14, 10, 27), updatedAt: DateTime(2026)),
        Note(id: 'c', title: 'Ôn chương 3', date: DateTime(2026, 10, 29, 20, 5), updatedAt: DateTime(2026)),
        Note(id: 'd', title: 'Năm ngoái', date: DateTime(2025, 3, 1, 8, 0), updatedAt: DateTime(2026)),
      ]);
    expect(store.noteCountsIn(2026), {11: 2, 10: 1});
    expect(store.notesSorted('', DateTime(2026, 10)).map((n) => n.id), ['c']);
    nav.go(AppPage.notes);
    await tester.pumpWidget(const SoNgayApp());
    await tester.pumpAndSettle();

    expect(find.text('THÁNG 11, 2026'), findsOneWidget);
    expect(find.text('THÁNG 10, 2026'), findsOneWidget);
    expect(find.text('THÁNG 3, 2025'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Xem ghi chú theo tháng'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget); // mở ở năm có ghi chú mới nhất
    await tester.tap(find.text('T10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem'));
    await tester.pumpAndSettle();
    expect(find.text('THÁNG 10, 2026 · 1 GHI CHÚ'), findsOneWidget);
    expect(find.text('Ôn chương 3'), findsOneWidget);
    expect(find.text('Hôm nay thi triết'), findsNothing);

    // Tháng trống không bấm được.
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('T1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả').last);
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay thi triết'), findsOneWidget);
    expect(find.text('Năm ngoái'), findsOneWidget);
  });

  testWidgets('quản lý bộ: đổi tên, xoá bộ kèm thẻ, giữ lại ít nhất một bộ', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await store.load();
    store.decks
      ..clear()
      ..addAll([Deck('d1', 'IELTS'), Deck('d2', 'Thuật ngữ ML')]);
    store.cards.clear();
    store.addCard('d2', 'overfitting', 'quá khớp');
    store.addCard('d2', 'epoch', 'vòng huấn luyện');
    store.addCard('d1', 'abundant', 'dồi dào');
    expect(store.renameDeck('d1', 'thuật ngữ ml'), isFalse); // trùng tên
    nav.go(AppPage.cards);
    await tester.pumpWidget(const SoNgayApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Quản lý bộ'));
    await tester.tap(find.text('Quản lý bộ'));
    await tester.pumpAndSettle();
    expect(find.text('2 bộ'), findsOneWidget);
    expect(find.text('2 từ'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Đổi tên bộ IELTS'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'IELTS 7.0');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(store.decks.first.name, 'IELTS 7.0');
    expect(find.text('IELTS 7.0'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Xoá bộ Thuật ngữ ML'));
    await tester.pumpAndSettle();
    expect(find.text('2 từ trong bộ cũng sẽ bị xoá. Không thể hoàn tác.'), findsOneWidget);
    await tester.tap(find.text('Xoá'));
    await tester.pumpAndSettle();
    expect(store.decks.map((d) => d.id), ['d1']);
    expect(store.cards.map((c) => c.word), ['abundant']);
    expect(find.text('Cần giữ lại ít nhất một bộ.'), findsOneWidget);
    expect(store.deleteDeck('d1'), isFalse);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Thuật ngữ ML'), findsNothing);
    expect(find.textContaining('Bộ IELTS 7.0'), findsOneWidget);
  });

  testWidgets('học: lật thẻ rồi tự chấm 4 mức, quên thì ôn lại cuối lượt', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await store.load();
    store.decks
      ..clear()
      ..add(Deck('d1', 'IELTS'));
    store.cards.clear();
    store.addCard('d1', 'apple', 'quả táo');
    store.addCard('d1', 'book', 'quyển sách');
    nav.go(AppPage.cards);
    await tester.pumpWidget(const SoNgayApp());
    await tester.pumpAndSettle();
    expect(find.text('Thẻ 1 / 2'), findsOneWidget);
    expect(find.text('Nhớ'), findsNothing);
    await tester.tap(find.text('Lật thẻ'));
    await tester.pumpAndSettle();
    expect(find.text('ôn lại ngay'), findsOneWidget);
    expect(find.text('3 ngày'), findsOneWidget);
    expect(find.text('16 ngày'), findsOneWidget);
    await tester.tap(find.text('Quên'));
    await tester.pumpAndSettle();
    expect(find.text('Thẻ 2 / 3'), findsOneWidget);
    await tester.tap(find.text('Lật thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhớ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lật thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhớ'));
    await tester.pumpAndSettle();
    expect(find.text('Xong lượt ôn!'), findsOneWidget);
    expect(find.text('Nhớ 2 · Quên 1'), findsOneWidget);
    expect(store.cards.every((c) => c.dueDate.isAfter(store.today)), isTrue);
  });

  testWidgets('dò lại: sai thì hỏi lại cuối lượt, Enter để chấm/sang câu, kết quả liệt kê từ sai', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await store.load();
    store.decks
      ..clear()
      ..add(Deck('d1', 'IELTS'));
    store.cards.clear();
    for (final w in [('apple', 'quả táo'), ('book', 'quyển sách'), ('water', 'nước'), ('journey', 'hành trình')]) {
      store.addCard('d1', w.$1, w.$2, pos: 'noun');
    }
    nav.go(AppPage.cards);
    await tester.pumpWidget(const SoNgayApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dò lại'));
    await tester.pumpAndSettle();
    expect(find.text('Thông minh'), findsOneWidget);
    await tester.tap(find.text('Việt → Anh'));
    await tester.pumpAndSettle();

    m.Card shown() => store.cards.firstWhere((c) => find.text(c.meaning).evaluate().isNotEmpty);
    Future<void> submit(String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    final first = shown();
    await submit('zzz');
    expect(find.text('Chưa đúng'), findsOneWidget);
    expect(find.text('Câu 1 / 5'), findsOneWidget); // câu sai được thêm vào cuối
    expect(first.dueDate, store.today);
    await tester.testTextInput.receiveAction(TextInputAction.done); // Enter → câu tiếp
    await tester.pump();
    expect(find.text('Câu 2 / 5'), findsOneWidget);

    await submit(shown().word);
    expect(find.text('Chính xác!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400)); // đúng thì tự sang câu
    expect(find.text('Câu 3 / 5'), findsOneWidget);

    while (find.text('đúng ngay lần đầu').evaluate().isEmpty) {
      await submit(shown().word);
      await tester.pump(const Duration(milliseconds: 1400));
    }
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    expect(find.text('TỪ CẦN ÔN THÊM · 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Ôn lại 1 từ sai'));
    await tester.tap(find.text('Ôn lại 1 từ sai'));
    await tester.pumpAndSettle();
    expect(find.text('Câu 1 / 1'), findsOneWidget);
    expect(find.text(first.meaning), findsOneWidget);
  });
}
