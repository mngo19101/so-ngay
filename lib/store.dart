import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';
import 'models.dart';
import 'notifications.dart';

const subjectPalette = [0xFF2A78D6, 0xFFEB6834, 0xFF1BAF7A, 0xFFEDA100, 0xFFE87BA4, 0xFF7A4FD1, 0xFF0E9AA7, 0xFF8C6D3F];

class AppStore extends ChangeNotifier {
  Settings settings = Settings();
  List<SpecialDay> specialDays = [];
  List<Event> events = [];
  List<Deck> decks = [];
  List<Card> cards = [];
  List<StudyLog> studyLogs = [];
  List<Subject> subjects = [];
  List<StudySession> sessions = [];
  List<NotificationLog> notifLogs = [];
  List<Planned> planned = [];
  bool loaded = false;
  SharedPreferences? _prefs;
  int _seq = 0;

  String newId() => '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';
  DateTime get today => dateOnly(DateTime.now());

  // ---------- lưu / tải ----------
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString('data');
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _seed();
      }
    } else {
      _seed();
    }
    loaded = true;
    _flushDelivered();
    await _save();
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'settings': settings.toJson(),
        'specialDays': specialDays.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'decks': decks.map((e) => e.toJson()).toList(),
        'cards': cards.map((e) => e.toJson()).toList(),
        'studyLogs': studyLogs.map((e) => e.toJson()).toList(),
        'subjects': subjects.map((e) => e.toJson()).toList(),
        'sessions': sessions.map((e) => e.toJson()).toList(),
        'notifLogs': notifLogs.map((e) => e.toJson()).toList(),
        'planned': planned.map((e) => e.toJson()).toList(),
      };

  List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
      (v as List? ?? []).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();

  void _fromJson(Map<String, dynamic> j) {
    settings = Settings.fromJson(Map<String, dynamic>.from(j['settings'] ?? {}));
    specialDays = _list(j['specialDays'], SpecialDay.fromJson);
    events = _list(j['events'], Event.fromJson);
    decks = _list(j['decks'], Deck.fromJson);
    cards = _list(j['cards'], Card.fromJson);
    studyLogs = _list(j['studyLogs'], StudyLog.fromJson);
    subjects = _list(j['subjects'], Subject.fromJson);
    sessions = _list(j['sessions'], StudySession.fromJson);
    notifLogs = _list(j['notifLogs'], NotificationLog.fromJson);
    planned = _list(j['planned'], Planned.fromJson);
    if (decks.isEmpty) _seedDecks();
    if (subjects.isEmpty) _seedSubjects();
  }

  Future<void> _save() async {
    await _prefs?.setString('data', jsonEncode(toJson()));
  }

  void changed({bool reschedule = false}) {
    notifyListeners();
    _save();
    if (reschedule) rescheduleNotifications();
  }

  void _seedDecks() {
    decks = [Deck('deck_en', 'Tiếng Anh'), Deck('deck_ielts', 'IELTS'), Deck('deck_ml', 'Thuật ngữ ML')];
  }

  void _seedSubjects() {
    final names = ['Học máy', 'Toán rời rạc', 'Tiếng Anh', 'Lập trình Python', 'Khác'];
    const cols = [0xFF2A78D6, 0xFFEB6834, 0xFF1BAF7A, 0xFFEDA100, 0xFFE87BA4];
    subjects = [for (var i = 0; i < names.length; i++) Subject('sub_$i', names[i], cols[i])];
  }

  void _seed() {
    settings = Settings();
    _seedDecks();
    _seedSubjects();
    int n = 0;
    SpecialDay h(String name, int d, int m, {String cal = 'solar', List<int> off = const [0, 1]}) =>
        SpecialDay(
          id: 'builtin_${n++}',
          name: name,
          type: 'holiday',
          calendar: cal,
          day: d,
          month: m,
          repeat: 'yearly',
          remindOffsetsDays: off,
          isBuiltIn: true,
        );
    specialDays = [
      h('Tết Dương lịch', 1, 1),
      h('Tết Nguyên đán', 1, 1, cal: 'lunar', off: [0, 1, 3, 7]),
      h('Giỗ Tổ Hùng Vương', 10, 3, cal: 'lunar'),
      h('Ngày Giải phóng miền Nam', 30, 4),
      h('Quốc tế Lao động', 1, 5),
      h('Quốc khánh', 2, 9),
      h('Ngày Nhà giáo Việt Nam', 20, 11),
      h('Giáng sinh', 25, 12),
      h('Ngày Quốc tế Phụ nữ', 8, 3),
      h('Ngày Phụ nữ Việt Nam', 20, 10),
    ];
    final t = today;
    final w = [
      ['hello', '/həˈləʊ/', 'interjection', 'xin chào', 'Hello, how are you?'],
      ['persevere', '/ˌpɜːsɪˈvɪə/', 'verb', 'kiên trì', 'She persevered despite the difficulties.'],
      ['resilient', '/rɪˈzɪliənt/', 'adjective', 'kiên cường', 'Children are often very resilient.'],
      ['ambition', '/æmˈbɪʃn/', 'noun', 'hoài bão', 'He has great ambition.'],
      ['remember', '/rɪˈmembə/', 'verb', 'ghi nhớ', 'I remember her name.'],
      ['journey', '/ˈdʒɜːni/', 'noun', 'hành trình', 'It was a long journey.'],
    ];
    cards = [
      for (final x in w)
        Card(
            id: newId(),
            deckId: 'deck_en',
            word: x[0],
            ipa: x[1],
            partOfSpeech: x[2],
            meaning: x[3],
            example: x[4],
            dueDate: t)
    ];
  }

  // ---------- thông báo ----------
  void _flushDelivered() {
    final now = DateTime.now();
    final done = planned.where((p) => !p.when.isAfter(now)).toList();
    for (final p in done) {
      if (settings.pushEnabled) {
        notifLogs.insert(0, NotificationLog(newId(), p.title, p.body, p.when.toIso8601String(), false));
      }
    }
    planned.removeWhere((p) => !p.when.isAfter(now));
    if (notifLogs.length > 100) notifLogs = notifLogs.sublist(0, 100);
  }

  List<Planned> buildPlan() {
    final now = DateTime.now();
    final t = today;
    final horizon = addDays(t, 60);
    final out = <Planned>[];
    for (final sd in specialDays.where((s) => s.enabled)) {
      final occs = occurrencesBetween(sd, t, addDays(horizon, 8));
      for (final occ in occs) {
        for (final off in sd.remindOffsetsDays) {
          final when = atTime(addDays(occ, -off), sd.notifyTime);
          if (when.isAfter(now) && !when.isAfter(addDays(horizon, 1))) {
            out.add(Planned('sd_${sd.id}_${isoDate(occ)}_$off', when, 'SỔ NGÀY · ${sd.notifyTime}',
                '${reminderText(off, sd.name)} ${wdFull(occ)} ${dm(occ)}'));
          }
        }
      }
    }
    for (final e in events) {
      for (final m in e.remindBeforeMin) {
        final when = e.start.subtract(Duration(minutes: m));
        if (when.isAfter(now) && when.isBefore(horizon)) {
          out.add(Planned('ev_${e.id}_$m', when, 'Sắp tới: ${e.title}',
              '${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')}${e.location != null && e.location!.isNotEmpty ? ' · ${e.location}' : ''}'));
        }
      }
    }
    out.sort((a, b) => a.when.compareTo(b.when));
    final res = out.take(46).toList();
    if (settings.morningEnabled) {
      for (var i = 0; i < 7; i++) {
        final d = addDays(t, i);
        final when = atTime(d, settings.morningTime);
        if (!when.isAfter(now)) continue;
        final n = eventsOn(d).length;
        final up = _nearestAfter(d);
        res.add(Planned('morning_${isoDate(d)}', when, 'Tóm tắt buổi sáng',
            'Hôm nay có $n việc${up != null ? ' · còn ${up.daysLeft} ngày đến ${up.sd.name}' : ''}'));
      }
    }
    if (settings.studyReminder) {
      for (var i = 0; i < 7; i++) {
        final d = addDays(t, i);
        final when = atTime(d, '20:00');
        if (!when.isAfter(now)) continue;
        final n = cards.where((c) => !c.dueDate.isAfter(d)).length;
        if (n > 0) res.add(Planned('study_${isoDate(d)}', when, 'Ôn từ vựng', 'Bạn có $n từ cần ôn hôm nay'));
      }
    }
    res.sort((a, b) => a.when.compareTo(b.when));
    return res.take(60).toList();
  }

  SpecialOcc? _nearestAfter(DateTime d) {
    SpecialOcc? best;
    for (final sd in specialDays.where((s) => s.enabled && s.repeat != 'weekly')) {
      final n = nextOccurrence(sd, d);
      if (n == null) continue;
      final left = diffDays(n, d);
      if (best == null || left < best.daysLeft) best = SpecialOcc(sd, n, left);
    }
    return best;
  }

  Future<void> rescheduleNotifications() async {
    _flushDelivered();
    if (!settings.pushEnabled) {
      planned = [];
      await NotificationService.instance.cancelAll();
      changedQuiet();
      return;
    }
    final plan = buildPlan();
    planned = plan;
    await NotificationService.instance.schedule(plan, sound: settings.sound);
    changedQuiet();
  }

  void changedQuiet() {
    notifyListeners();
    _save();
  }

  int get unreadCount => notifLogs.where((n) => !n.read).length;
  void markAllRead() {
    for (final n in notifLogs) {
      n.read = true;
    }
    changed();
  }

  Future<void> sendTest() async {
    final title = 'SỔ NGÀY · thử';
    const body = 'Thông báo hoạt động bình thường.';
    await NotificationService.instance.showNow(title, body, sound: settings.sound);
    notifLogs.insert(0, NotificationLog(newId(), title, body, DateTime.now().toIso8601String(), false));
    changed();
  }

  // ---------- ngày đặc biệt ----------
  List<SpecialOcc> upcoming({String? type}) {
    final t = today;
    final out = <SpecialOcc>[];
    for (final sd in specialDays) {
      if (!sd.enabled) continue;
      if (type != null && sd.type != type) continue;
      final n = nextOccurrence(sd, t);
      if (n != null) out.add(SpecialOcc(sd, n, diffDays(n, t)));
    }
    out.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return out;
  }

  List<SpecialDay> specialsOn(DateTime d) =>
      specialDays.where((s) => s.enabled && occursOn(s, d)).toList();

  void saveSpecial(SpecialDay sd) {
    final i = specialDays.indexWhere((s) => s.id == sd.id);
    if (i >= 0) {
      specialDays[i] = sd;
    } else {
      specialDays.add(sd);
    }
    changed(reschedule: true);
  }

  void deleteSpecial(String id) {
    specialDays.removeWhere((s) => s.id == id);
    changed(reschedule: true);
  }

  void toggleSpecial(SpecialDay sd, bool v) {
    sd.enabled = v;
    changed(reschedule: true);
  }

  // ---------- sự kiện ----------
  List<Event> eventsOn(DateTime d) {
    final l = events.where((e) => dateOnly(e.start) == dateOnly(d)).toList();
    l.sort((a, b) => a.start.compareTo(b.start));
    return l;
  }

  void saveEvent(Event e) {
    final i = events.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      events[i] = e;
    } else {
      events.add(e);
    }
    changed(reschedule: true);
  }

  void deleteEvent(String id) {
    events.removeWhere((e) => e.id == id);
    changed(reschedule: true);
  }

  // ---------- cài đặt ----------
  void updateSettings(void Function(Settings s) f, {bool reschedule = false}) {
    f(settings);
    changed(reschedule: reschedule);
  }

  // ---------- thẻ từ vựng ----------
  List<Card> deckCards(String deckId) => cards.where((c) => c.deckId == deckId).toList();
  List<Card> dueCards(String deckId, [DateTime? on]) {
    final d = on ?? today;
    final l = cards.where((c) => c.deckId == deckId && !c.dueDate.isAfter(d)).toList();
    l.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return l;
  }

  Card addCard(String deckId, String word, String meaning, {String? ipa, String? pos, String? example}) {
    final c = Card(
        id: newId(),
        deckId: deckId,
        word: word.trim(),
        meaning: meaning.trim(),
        ipa: ipa?.trim().isEmpty ?? true ? null : ipa!.trim(),
        partOfSpeech: pos?.trim().isEmpty ?? true ? null : pos!.trim(),
        example: example?.trim().isEmpty ?? true ? null : example!.trim(),
        dueDate: today);
    cards.add(c);
    changed();
    return c;
  }

  void deleteCard(String id) {
    cards.removeWhere((c) => c.id == id);
    changed();
  }

  Deck addDeck(String name) {
    final ex = decks.where((d) => d.name.toLowerCase() == name.trim().toLowerCase());
    if (ex.isNotEmpty) return ex.first;
    final d = Deck(newId(), name.trim());
    decks.add(d);
    changed();
    return d;
  }

  void _log(bool correct) {
    final k = isoDate(today);
    final i = studyLogs.indexWhere((l) => l.date == k);
    if (i >= 0) {
      studyLogs[i].cardsReviewed++;
      if (correct) studyLogs[i].correct++;
    } else {
      studyLogs.add(StudyLog(k, 1, correct ? 1 : 0));
    }
  }

  /// Lặp lại ngắt quãng (đường cong quên Ebbinghaus): nhớ đúng thì giãn dần
  /// 1 → 3 → 7 → 14 → 30 → 60 → 120 → 240 ngày. Quên thì quay về bước đầu.
  /// Ôn sớm hơn hạn (chưa đến ngày) không làm tăng bước — chỉ tính thống kê.
  void review(Card c, bool known, {bool sameDay = false}) {
    if (known) {
      c.correctCount++;
      final isDue = !c.dueDate.isAfter(today);
      if (isDue) {
        c.intervalDays = srsSchedule[math.min(c.stage, srsSchedule.length - 1)];
        c.stage++;
        c.ease = math.min(3.0, c.ease + 0.05);
        c.dueDate = addDays(today, c.intervalDays);
      }
    } else {
      c.wrongCount++;
      c.stage = 0;
      c.intervalDays = 1;
      c.ease = math.max(1.3, c.ease - 0.2);
      c.dueDate = sameDay ? today : addDays(today, 1);
    }
    _log(known);
    changed();
  }

  // ---------- giờ học ----------
  Subject? subjectById(String id) {
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  Subject addSubject(String name) {
    final n = name.trim();
    for (final s in subjects) {
      if (s.name.toLowerCase() == n.toLowerCase()) return s;
    }
    final s = Subject(newId(), n, subjectPalette[subjects.length % subjectPalette.length]);
    subjects.add(s);
    changed();
    return s;
  }

  void renameSubject(Subject s, String name) {
    if (name.trim().isEmpty) return;
    s.name = name.trim();
    changed();
  }

  void deleteSubject(Subject s) {
    subjects.remove(s);
    sessions.removeWhere((x) => x.subjectId == s.id);
    changed();
  }

  int minutesOn(String subjectId, DateTime d) {
    final k = isoDate(d);
    var t = 0;
    for (final s in sessions) {
      if (s.subjectId == subjectId && s.date == k) t += s.minutes;
    }
    return t;
  }

  int dayTotal(DateTime d) {
    final k = isoDate(d);
    var t = 0;
    for (final s in sessions) {
      if (s.date == k) t += s.minutes;
    }
    return t;
  }

  Map<String, int> _dayCache = {};
  int _dayCacheVer = -1;
  int _ver = 0;
  int get version => _ver;
  @override
  void notifyListeners() {
    _ver++;
    super.notifyListeners();
  }

  int dayTotalCached(DateTime d) {
    if (_dayCacheVer != _ver) {
      _dayCache = {};
      for (final s in sessions) {
        _dayCache[s.date] = (_dayCache[s.date] ?? 0) + s.minutes;
      }
      _dayCacheVer = _ver;
    }
    return _dayCache[isoDate(d)] ?? 0;
  }

  List<StudySession> sessionsOn(DateTime d) {
    final k = isoDate(d);
    final l = sessions.where((s) => s.date == k).toList();
    l.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return l;
  }

  StudySession addSession(String subjectId, DateTime d, int minutes) {
    final s = StudySession(newId(), subjectId, isoDate(d), minutes, DateTime.now().toIso8601String());
    sessions.add(s);
    changed();
    return s;
  }

  /// Trả false nếu xoá khiến tổng môn/ngày âm.
  bool deleteSession(StudySession s) {
    final after = minutesOn(s.subjectId, parseDate(s.date)) - s.minutes;
    if (after < 0) return false;
    sessions.remove(s);
    changed();
    return true;
  }

  Set<String> activeDates() {
    final set = <String>{};
    for (final l in studyLogs) {
      if (l.cardsReviewed > 0) set.add(l.date);
    }
    for (final s in sessions) {
      if (s.minutes > 0) set.add(s.date);
    }
    return set;
  }

  int streak() {
    final set = activeDates();
    var d = today;
    if (!set.contains(isoDate(d))) d = addDays(d, -1);
    var n = 0;
    while (set.contains(isoDate(d))) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  // ---------- sao lưu ----------
  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  String? importJson(String text) {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      _fromJson(j);
      changed(reschedule: true);
      return null;
    } catch (e) {
      return 'Dữ liệu không hợp lệ';
    }
  }
}

final store = AppStore();
