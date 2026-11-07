import 'lunar.dart';
import 'models.dart';

const weekdayFull = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
const weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

String wdFull(DateTime d) => weekdayFull[d.weekday - 1];
String wdShort(DateTime d) => weekdayShort[d.weekday - 1];
String dm(DateTime d) => '${d.day}/${d.month}';
String lunarDm(DateTime d) {
  final l = Lunar.fromSolar(d);
  return '${l.day}/${l.month}';
}

bool isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
int diffDays(DateTime a, DateTime b) =>
    (DateTime.utc(a.year, a.month, a.day).difference(DateTime.utc(b.year, b.month, b.day))).inDays;
DateTime mondayOf(DateTime d) => addDays(dateOnly(d), 1 - d.weekday);

String fmtMin(int m) {
  if (m <= 0) return '0p';
  final h = m ~/ 60, r = m % 60;
  if (h > 0 && r > 0) return '${h}g${r}p';
  if (h > 0) return '${h}g';
  return '${r}p';
}

const typeNames = {
  'birthday': 'Sinh nhật',
  'anniversary': 'Kỷ niệm',
  'holiday': 'Ngày lễ',
  'other': 'Khác',
};

/// Lần diễn ra tiếp theo (>= today), hoặc null nếu không còn.
DateTime? nextOccurrence(SpecialDay sd, DateTime today) {
  today = dateOnly(today);
  if (sd.repeat == 'weekly' && sd.repeatWeekdays.isNotEmpty) {
    var start = today;
    if (sd.year != null) {
      final s = DateTime(sd.year!, sd.month, sd.day);
      if (s.isAfter(start)) start = s;
    }
    for (var i = 0; i < 7; i++) {
      final d = addDays(start, i);
      if (sd.repeatWeekdays.contains(d.weekday)) return d;
    }
    return null;
  }
  if (sd.calendar == 'solar') {
    DateTime mk(int y) {
      var dd = sd.day;
      if (sd.month == 2 && dd == 29 && !isLeapYear(y)) dd = 28;
      return DateTime(y, sd.month, dd);
    }

    if (sd.repeat == 'none') {
      final d = mk(sd.year ?? today.year);
      return d.isBefore(today) ? null : d;
    }
    var d = mk(today.year);
    if (d.isBefore(today)) d = mk(today.year + 1);
    return d;
  }
  // âm lịch
  if (sd.repeat == 'none') {
    final s = Lunar.resolve(sd.day, sd.month, sd.year ?? Lunar.fromSolar(today).year, leap: sd.isLeapMonth);
    if (s == null || s.isBefore(today)) return null;
    return s;
  }
  final ly = Lunar.fromSolar(today).year;
  for (var y = ly - 1; y <= ly + 3; y++) {
    final s = Lunar.resolve(sd.day, sd.month, y, leap: sd.isLeapMonth);
    if (s != null && !s.isBefore(today)) return s;
  }
  return null;
}

bool occursOn(SpecialDay sd, DateTime d) {
  final n = nextOccurrence(sd, d);
  return n != null && n == dateOnly(d);
}

class SpecialOcc {
  final SpecialDay sd;
  final DateTime date;
  final int daysLeft;
  SpecialOcc(this.sd, this.date, this.daysLeft);
}

class Planned {
  final String key;
  final DateTime when;
  final String title, body;

  /// null = một lần; daily | weekly | yearly = iOS tự lặp mãi, không cần mở app.
  final String? repeat;
  Planned(this.key, this.when, this.title, this.body, {this.repeat});
  Map<String, dynamic> toJson() =>
      {'key': key, 'when': when.toIso8601String(), 'title': title, 'body': body, 'repeat': repeat};
  factory Planned.fromJson(Map<String, dynamic> j) =>
      Planned(j['key'], DateTime.parse(j['when']), j['title'], j['body'], repeat: j['repeat']);

  /// Lần nổ kế tiếp sau [w], hoặc null nếu không lặp.
  DateTime? after(DateTime w) => switch (repeat) {
        'daily' => DateTime(w.year, w.month, w.day + 1, w.hour, w.minute),
        'weekly' => DateTime(w.year, w.month, w.day + 7, w.hour, w.minute),
        'yearly' => DateTime(w.year + 1, w.month, w.day, w.hour, w.minute),
        _ => null,
      };
}

DateTime atTime(DateTime day, String hhmm) {
  final p = hhmm.split(':');
  return DateTime(day.year, day.month, day.day, int.parse(p[0]), int.parse(p[1]));
}

String reminderText(int offset, String name) {
  if (offset == 0) return 'Hôm nay là $name!';
  if (offset == 1) return 'Ngày mai: $name';
  return 'Còn $offset ngày đến $name';
}

String offsetLabel(int o) => o == 0
    ? 'đúng ngày'
    : o == 7
        ? 'trước 1 tuần'
        : 'trước $o ngày';

/// Các lần diễn ra trong [from, to].
List<DateTime> occurrencesBetween(SpecialDay sd, DateTime from, DateTime to) {
  final out = <DateTime>[];
  var cur = from;
  for (var guard = 0; guard < 80; guard++) {
    final n = nextOccurrence(sd, cur);
    if (n == null || n.isAfter(to)) break;
    out.add(n);
    cur = addDays(n, 1);
  }
  return out;
}
