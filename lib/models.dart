// Mô hình dữ liệu (mục 4 của đặc tả). Ngày lưu dạng 'yyyy-MM-dd'.

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime parseDate(String s) {
  final p = s.substring(0, 10).split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

class Event {
  String id, title;
  DateTime start; // ngày + giờ
  int? durationMin;
  String? location;
  String category; // study | personal | habit | other
  List<int> remindBeforeMin;
  Event({
    required this.id,
    required this.title,
    required this.start,
    this.durationMin,
    this.location,
    this.category = 'other',
    this.remindBeforeMin = const [],
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start': start.toIso8601String(),
        'durationMin': durationMin,
        'location': location,
        'category': category,
        'remindBeforeMin': remindBeforeMin,
      };
  factory Event.fromJson(Map<String, dynamic> j) => Event(
        id: j['id'],
        title: j['title'],
        start: DateTime.parse(j['start']),
        durationMin: j['durationMin'],
        location: j['location'],
        category: j['category'] ?? 'other',
        remindBeforeMin: (j['remindBeforeMin'] as List? ?? []).cast<int>(),
      );
}

class SpecialDay {
  String id, name;
  String type; // birthday | anniversary | holiday | other
  String calendar; // solar | lunar
  int day, month;
  bool isLeapMonth;
  int? year; // solar: năm bắt đầu; lunar: năm âm gốc
  String repeat; // none | weekly | yearly
  List<int> repeatWeekdays; // 1=T2..7=CN
  List<int> remindOffsetsDays;
  String notifyTime;
  bool isBuiltIn;
  bool enabled;
  SpecialDay({
    required this.id,
    required this.name,
    this.type = 'other',
    this.calendar = 'solar',
    required this.day,
    required this.month,
    this.isLeapMonth = false,
    this.year,
    this.repeat = 'yearly',
    this.repeatWeekdays = const [],
    this.remindOffsetsDays = const [0],
    this.notifyTime = '08:00',
    this.isBuiltIn = false,
    this.enabled = true,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'calendar': calendar,
        'day': day,
        'month': month,
        'isLeapMonth': isLeapMonth,
        'year': year,
        'repeat': repeat,
        'repeatWeekdays': repeatWeekdays,
        'remindOffsetsDays': remindOffsetsDays,
        'notifyTime': notifyTime,
        'isBuiltIn': isBuiltIn,
        'enabled': enabled,
      };
  factory SpecialDay.fromJson(Map<String, dynamic> j) => SpecialDay(
        id: j['id'],
        name: j['name'],
        type: j['type'] ?? 'other',
        calendar: j['calendar'] ?? 'solar',
        day: j['day'],
        month: j['month'],
        isLeapMonth: j['isLeapMonth'] ?? false,
        year: j['year'],
        repeat: j['repeat'] ?? 'yearly',
        repeatWeekdays: (j['repeatWeekdays'] as List? ?? []).cast<int>(),
        remindOffsetsDays: (j['remindOffsetsDays'] as List? ?? [0]).cast<int>(),
        notifyTime: j['notifyTime'] ?? '08:00',
        isBuiltIn: j['isBuiltIn'] ?? false,
        enabled: j['enabled'] ?? true,
      );
}

class Deck {
  String id, name;
  Deck(this.id, this.name);
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Deck.fromJson(Map<String, dynamic> j) => Deck(j['id'], j['name']);
}

class Card {
  String id, deckId, word, meaning;
  String? ipa, partOfSpeech, example;
  DateTime dueDate;
  int intervalDays, correctCount, wrongCount;
  double ease;
  Card({
    required this.id,
    required this.deckId,
    required this.word,
    required this.meaning,
    this.ipa,
    this.partOfSpeech,
    this.example,
    required this.dueDate,
    this.intervalDays = 0,
    this.ease = 2.5,
    this.correctCount = 0,
    this.wrongCount = 0,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'word': word,
        'ipa': ipa,
        'partOfSpeech': partOfSpeech,
        'meaning': meaning,
        'example': example,
        'dueDate': isoDate(dueDate),
        'intervalDays': intervalDays,
        'ease': ease,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
      };
  factory Card.fromJson(Map<String, dynamic> j) => Card(
        id: j['id'],
        deckId: j['deckId'],
        word: j['word'],
        ipa: j['ipa'],
        partOfSpeech: j['partOfSpeech'],
        meaning: j['meaning'],
        example: j['example'],
        dueDate: parseDate(j['dueDate']),
        intervalDays: j['intervalDays'] ?? 0,
        ease: (j['ease'] ?? 2.5).toDouble(),
        correctCount: j['correctCount'] ?? 0,
        wrongCount: j['wrongCount'] ?? 0,
      );
}

class StudyLog {
  String date;
  int cardsReviewed, correct;
  StudyLog(this.date, this.cardsReviewed, this.correct);
  Map<String, dynamic> toJson() => {'date': date, 'cardsReviewed': cardsReviewed, 'correct': correct};
  factory StudyLog.fromJson(Map<String, dynamic> j) =>
      StudyLog(j['date'], j['cardsReviewed'] ?? 0, j['correct'] ?? 0);
}

class Subject {
  String id, name;
  int color;
  Subject(this.id, this.name, this.color);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(j['id'], j['name'], j['color']);
}

class StudySession {
  String id, subjectId, date, createdAt;
  int minutes;
  StudySession(this.id, this.subjectId, this.date, this.minutes, this.createdAt);
  Map<String, dynamic> toJson() =>
      {'id': id, 'subjectId': subjectId, 'date': date, 'minutes': minutes, 'createdAt': createdAt};
  factory StudySession.fromJson(Map<String, dynamic> j) =>
      StudySession(j['id'], j['subjectId'], j['date'], j['minutes'], j['createdAt']);
}

class NotificationLog {
  String id, title, body, sentAt;
  bool read;
  NotificationLog(this.id, this.title, this.body, this.sentAt, this.read);
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'body': body, 'sentAt': sentAt, 'read': read};
  factory NotificationLog.fromJson(Map<String, dynamic> j) =>
      NotificationLog(j['id'], j['title'], j['body'], j['sentAt'], j['read'] ?? false);
}

class Settings {
  String displayName;
  int accent;
  bool pushEnabled, sound, sidebarCollapsed, studyReminder;
  bool morningEnabled;
  String morningTime;
  int dailyGoalMin, weeklyGoalMin;
  Settings({
    this.displayName = 'bạn',
    this.accent = 0xFFD9472B,
    this.pushEnabled = true,
    this.sound = true,
    this.sidebarCollapsed = true,
    this.studyReminder = true,
    this.morningEnabled = true,
    this.morningTime = '07:00',
    this.dailyGoalMin = 180,
    this.weeklyGoalMin = 1200,
  });
  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'accent': accent,
        'pushEnabled': pushEnabled,
        'sound': sound,
        'sidebarCollapsed': sidebarCollapsed,
        'studyReminder': studyReminder,
        'morningEnabled': morningEnabled,
        'morningTime': morningTime,
        'dailyGoalMin': dailyGoalMin,
        'weeklyGoalMin': weeklyGoalMin,
      };
  factory Settings.fromJson(Map<String, dynamic> j) {
    final d = Settings();
    return Settings(
      displayName: j['displayName'] ?? d.displayName,
      accent: j['accent'] ?? d.accent,
      pushEnabled: j['pushEnabled'] ?? d.pushEnabled,
      sound: j['sound'] ?? d.sound,
      sidebarCollapsed: j['sidebarCollapsed'] ?? d.sidebarCollapsed,
      studyReminder: j['studyReminder'] ?? d.studyReminder,
      morningEnabled: j['morningEnabled'] ?? d.morningEnabled,
      morningTime: j['morningTime'] ?? d.morningTime,
      dailyGoalMin: j['dailyGoalMin'] ?? d.dailyGoalMin,
      weeklyGoalMin: j['weeklyGoalMin'] ?? d.weeklyGoalMin,
    );
  }
}
