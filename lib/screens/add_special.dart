import 'package:flutter/material.dart';

import '../logic.dart';
import '../lunar.dart';
import '../models.dart';
import '../notifications.dart';
import '../store.dart';
import '../theme.dart';
import 'shell.dart';

class AddSpecialScreen extends StatefulWidget {
  final SpecialDay? editing;
  const AddSpecialScreen({super.key, this.editing});
  @override
  State<AddSpecialScreen> createState() => _AddSpecialScreenState();
}

class _AddSpecialScreenState extends State<AddSpecialScreen> {
  late final name = TextEditingController(text: widget.editing?.name ?? '');
  late String type = widget.editing?.type ?? 'birthday';
  late bool lunar = widget.editing?.calendar == 'lunar';
  late DateTime solarDate = _initSolar();
  late int lDay = widget.editing != null && lunar ? widget.editing!.day : Lunar.fromSolar(store.today).day;
  late int lMonth = widget.editing != null && lunar ? widget.editing!.month : Lunar.fromSolar(store.today).month;
  late int lYear = widget.editing != null && lunar ? (widget.editing!.year ?? Lunar.fromSolar(store.today).year) : Lunar.fromSolar(store.today).year;
  late bool lLeap = widget.editing?.isLeapMonth ?? false;
  late String repeat = widget.editing?.repeat ?? 'yearly';
  late Set<int> weekdays = {...?widget.editing?.repeatWeekdays};
  late String notifyTime = widget.editing?.notifyTime ?? '08:00';
  late Set<int> offsets = {...(widget.editing?.remindOffsetsDays ?? [0, 1])};

  DateTime _initSolar() {
    final e = widget.editing;
    if (e != null && e.calendar == 'solar') {
      return DateTime(e.year ?? store.today.year, e.month, e.day);
    }
    return store.today;
  }

  @override
  void initState() {
    super.initState();
    if (widget.editing == null || weekdays.isEmpty) weekdays = {solarDate.weekday};
  }

  String _hint() {
    if (repeat == 'weekly') {
      final ws = weekdays.toList()..sort();
      return 'Nhắc vào ${ws.map((w) => weekdayShort[w - 1]).join(', ')} mỗi tuần, bắt đầu từ ngày đã chọn.';
    }
    if (lunar) {
      final s = Lunar.resolve(lDay, lMonth, repeat == 'none' ? lYear : _currentLunarYearFor(), leap: lLeap);
      if (s == null) return 'Ngày âm lịch này không tồn tại trong năm đã chọn.';
      return repeat == 'none'
          ? 'Rơi vào ${dm(s)}/${s.year} dương lịch.'
          : 'Năm nay rơi vào ${dm(s)} dương lịch — app tự đổi ngày mỗi năm.';
    }
    return 'Tương ứng ${lunarDm(solarDate)} âm lịch.';
  }

  int _currentLunarYearFor() {
    final t = store.today;
    final cand = nextOccurrence(
        SpecialDay(id: 'x', name: 'x', calendar: 'lunar', day: lDay, month: lMonth, isLeapMonth: lLeap), t);
    return cand == null ? Lunar.fromSolar(t).year : Lunar.fromSolar(cand).year;
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      toast(context, 'Hãy nhập tên ngày');
      return;
    }
    if (repeat == 'weekly' && weekdays.isEmpty) {
      toast(context, 'Chọn ít nhất 1 thứ trong tuần');
      return;
    }
    final sd = widget.editing ?? SpecialDay(id: store.newId(), name: '', day: 1, month: 1);
    sd.name = name.text.trim();
    sd.type = type;
    sd.calendar = lunar && repeat != 'weekly' ? 'lunar' : 'solar';
    if (sd.calendar == 'lunar') {
      sd.day = lDay;
      sd.month = lMonth;
      sd.year = lYear;
      sd.isLeapMonth = lLeap;
    } else {
      sd.day = solarDate.day;
      sd.month = solarDate.month;
      sd.year = solarDate.year;
      sd.isLeapMonth = false;
    }
    sd.repeat = repeat;
    sd.repeatWeekdays = (weekdays.toList()..sort());
    sd.notifyTime = notifyTime;
    sd.remindOffsetsDays = offsets.toList()..sort();
    final first = store.specialDays.every((s) => s.isBuiltIn) && widget.editing == null;
    if (first) {
      final ok = await _askPermission();
      if (!ok) return;
    }
    store.saveSpecial(sd);
    if (mounted) nav.go(AppPage.special);
  }

  Future<bool> _askPermission() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Cho phép thông báo', style: ts(18, w: FontWeight.w700)),
        content: Text('Sổ Ngày cần quyền thông báo để nhắc bạn trước các ngày đặc biệt. Thông báo được tạo ngay trên máy, không qua máy chủ.',
            style: ts(15, color: C.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Tiếp tục', style: ts(15, w: FontWeight.w700))),
        ],
      ),
    );
    if (go != true) return false;
    await NotificationService.instance.requestPermission();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBody(top: 12, children: [
      ScreenHeader(widget.editing == null ? 'Thêm ngày đặc biệt' : 'Sửa ngày đặc biệt',
          trailing: IconBtn(Icons.close_rounded, 'Đóng, không lưu', () => nav.go(AppPage.special))),
      Field('Tên ngày', name, hint: 'Ví dụ: Sinh nhật Mẹ'),
      const SizedBox(height: 18),
      _label('Loại'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in typeNames.entries) Pill(e.value, selected: type == e.key, onTap: () => setState(() => type = e.key)),
      ]),
      const SizedBox(height: 18),
      _label('Hệ lịch'),
      Segmented(const ['Dương lịch', 'Âm lịch'], lunar ? 1 : 0, (i) {
        setState(() {
          lunar = i == 1;
          if (lunar && repeat == 'weekly') repeat = 'yearly';
        });
      }),
      const SizedBox(height: 18),
      _label('Ngày'),
      if (!lunar) _solarPicker() else _lunarPicker(),
      const SizedBox(height: 8),
      Text(_hint(), style: ts(13, color: C.muted)),
      const SizedBox(height: 18),
      _label('Lặp lại'),
      Segmented(const ['Không', 'Hằng tuần', 'Hằng năm'], const ['none', 'weekly', 'yearly'].indexOf(repeat), (i) {
        setState(() {
          repeat = const ['none', 'weekly', 'yearly'][i];
          if (repeat == 'weekly') {
            lunar = false;
            if (weekdays.isEmpty) weekdays = {solarDate.weekday};
          }
        });
      }),
      if (repeat == 'weekly') ...[
        const SizedBox(height: 12),
        Row(children: [
          for (var w = 1; w <= 7; w++) ...[
            if (w > 1) const SizedBox(width: 4),
            Expanded(
              child: Pill(weekdayShort[w - 1],
                  selected: weekdays.contains(w),
                  compact: true,
                  selColor: context.accent,
                  onTap: () => setState(() => weekdays.contains(w) ? weekdays.remove(w) : weekdays.add(w))),
            ),
          ],
        ]),
      ],
      const SizedBox(height: 18),
      _label('Giờ nhận thông báo'),
      Tap(
        onTap: () async {
          final p = notifyTime.split(':');
          final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])));
          if (t != null) setState(() => notifyTime = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
        },
        child: Container(
          height: 52,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.borderInput)),
          child: Row(children: [
            Icon(Icons.schedule_rounded, size: 20, color: C.muted),
            const SizedBox(width: 10),
            Text(notifyTime, style: ts(16)),
          ]),
        ),
      ),
      const SizedBox(height: 18),
      _label('Nhắc trước'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in const [(0, 'Đúng ngày'), (1, 'Trước 1 ngày'), (3, 'Trước 3 ngày'), (7, 'Trước 1 tuần')])
          Pill(o.$2,
              selected: offsets.contains(o.$1),
              selColor: context.accent,
              onTap: () => setState(() => offsets.contains(o.$1) ? offsets.remove(o.$1) : offsets.add(o.$1))),
      ]),
      const SizedBox(height: 28),
      BigButton('Lưu ngày đặc biệt', _save, color: context.accent),
    ]);
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: ts(13, w: FontWeight.w600, color: C.muted)),
      );

  Widget _solarPicker() => Tap(
        onTap: () async {
          final d = await showDatePicker(
              context: context, initialDate: solarDate, firstDate: DateTime(1900), lastDate: DateTime(2100));
          if (d != null) {
            setState(() {
              solarDate = d;
              if (repeat == 'weekly' && weekdays.length <= 1) weekdays = {d.weekday};
            });
          }
        },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.borderInput)),
          child: Row(children: [
            Icon(Icons.event_rounded, size: 20, color: C.muted),
            const SizedBox(width: 10),
            Expanded(child: Text('${wdFull(solarDate)}, ${solarDate.day}/${solarDate.month}/${solarDate.year}', overflow: TextOverflow.ellipsis, style: ts(16))),
          ]),
        ),
      );

  Widget _lunarPicker() {
    final leapM = Lunar.leapMonthOf(lYear);
    return Column(children: [
      Row(children: [
        Expanded(child: _stepper('Ngày', lDay, 1, 30, (v) => lDay = v)),
        const SizedBox(width: 8),
        Expanded(child: _stepper('Tháng', lMonth, 1, 12, (v) => lMonth = v)),
        const SizedBox(width: 8),
        Expanded(child: _stepper('Năm', lYear, 1900, 2100, (v) => lYear = v)),
      ]),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerLeft,
        child: Pill(
            'Tháng nhuận${leapM == lMonth ? '' : leapM == 0 ? ' (năm $lYear không có)' : ' (năm $lYear nhuận tháng $leapM)'}',
            selected: lLeap,
            onTap: () => setState(() => lLeap = !lLeap)),
      ),
    ]);
  }

  Widget _stepper(String label, int v, int min, int max, void Function(int) set) => Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.borderInput)),
        child: Column(children: [
          Text(label, style: ts(11, color: C.muted)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Tap(
              label: '$label trừ',
              onTap: () => setState(() => set(v <= min ? max : v - 1)),
              child: const SizedBox(width: 34, height: 40, child: Icon(Icons.remove_rounded, size: 18)),
            ),
            Text('$v', style: ts(16, w: FontWeight.w700)),
            Tap(
              label: '$label cộng',
              onTap: () => setState(() => set(v >= max ? min : v + 1)),
              child: const SizedBox(width: 34, height: 40, child: Icon(Icons.add_rounded, size: 18)),
            ),
          ]),
        ]),
      );
}
