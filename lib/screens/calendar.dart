import 'package:flutter/material.dart';

import '../logic.dart';
import '../lunar.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'event_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime month = DateTime(store.today.year, store.today.month);
  late DateTime selected = store.today;
  int _cacheVer = -1;
  DateTime? _cacheMonth;
  final Map<String, List<SpecialDay>> _sp = {};

  void _shift(int n) => setState(() {
        month = DateTime(month.year, month.month + n);
        final t = store.today;
        selected = (month.year == t.year && month.month == t.month) ? t : month;
      });

  List<SpecialDay> _specials(DateTime d) {
    if (_cacheVer != store.version || _cacheMonth != month) {
      _sp.clear();
      _cacheVer = store.version;
      _cacheMonth = month;
    }
    return _sp.putIfAbsent(isoDate(d), () => store.specialsOn(d));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = store.today;
        final first = DateTime(month.year, month.month, 1);
        final start = addDays(first, -(first.weekday - 1));
        final days = [for (var i = 0; i < 42; i++) addDays(start, i)];
        final lm1 = Lunar.fromSolar(first);
        final lm2 = Lunar.fromSolar(DateTime(month.year, month.month + 1, 0));
        final sub = lm1.month == lm2.month ? 'Tháng ${lm1.month} âm lịch' : 'Tháng ${lm1.month} – ${lm2.month} âm lịch';
        final dayEvents = store.eventsOn(selected);
        final daySpecials = _specials(selected);
        final sel = selected;
        final isToday = sel == t;
        return GestureDetector(
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v < -300) _shift(1);
            if (v > 300) _shift(-1);
          },
          child: ScreenBody(top: 12, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tháng ${month.month}, ${month.year}', style: ts(22, w: FontWeight.w700, ls: -0.3)),
                  Text(sub, style: ts(13, color: C.muted)),
                ]),
              ),
              IconBtn(Icons.chevron_left_rounded, 'Tháng trước', () => _shift(-1)),
              const SizedBox(width: 8),
              IconBtn(Icons.chevron_right_rounded, 'Tháng sau', () => _shift(1)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(weekdayShort[i], style: ts(12, w: FontWeight.w600, color: i == 6 ? C.sunday : C.muted)),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            for (var r = 0; r < 6; r++)
              Row(children: [
                for (var c = 0; c < 7; c++) Expanded(child: _cell(days[r * 7 + c], t)),
              ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${isToday ? 'Hôm nay · ' : ''}${wdFull(sel)}, ${dm(sel)}', style: ts(16, w: FontWeight.w700)),
                  Text('Âm lịch ${lunarDm(sel)}', style: ts(12, color: C.muted)),
                ]),
              ),
              Tap(
                label: 'Thêm sự kiện',
                onTap: () => showEventSheet(context, sel),
                child: Padding(padding: const EdgeInsets.all(10), child: Text('+ Thêm', style: ts(14, w: FontWeight.w600, color: context.accent))),
              ),
            ]),
            const SizedBox(height: 8),
            for (final s in daySpecials)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Box(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: C.typeColors(s.type).$1, borderRadius: BorderRadius.circular(10)),
                      child: Text(typeNames[s.type] ?? '', style: ts(12, w: FontWeight.w600, color: C.typeColors(s.type).$2)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.name, style: ts(15, w: FontWeight.w600))),
                  ]),
                ),
              ),
            if (dayEvents.isEmpty && daySpecials.isEmpty)
              Tap(
                onTap: () => showEventSheet(context, sel),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: C.borderInput)),
                  child: Text('Chưa có gì — thêm sự kiện', style: ts(14, w: FontWeight.w600, color: C.muted)),
                ),
              )
            else if (dayEvents.isNotEmpty)
              Box(child: Column(children: [for (final e in dayEvents) EventRow(e)])),
          ]),
        );
      },
    );
  }

  Widget _cell(DateTime d, DateTime t) {
    final inMonth = d.month == month.month;
    final isSel = d == selected;
    final isToday = d == t;
    final l = Lunar.fromSolar(d);
    final hasSpecial = _specials(d).isNotEmpty;
    final hasEvent = store.eventsOn(d).isNotEmpty;
    final fg = isSel ? Colors.white : (d.weekday == 7 ? C.sunday : C.ink);
    return Semantics(
      button: true,
      label: '${wdFull(d)} ${dm(d)}, âm lịch ${l.day}/${l.month}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          selected = d;
          if (!inMonth) month = DateTime(d.year, d.month);
        }),
        child: Opacity(
          opacity: inMonth ? 1 : 0.35,
          child: Container(
            height: 56,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: isSel ? C.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isToday && !isSel ? Border.all(color: context.accent, width: 1.5) : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${d.day}', style: ts(15, w: FontWeight.w600, color: fg)),
              Text(l.day == 1 ? '1/${l.month}' : '${l.day}',
                  style: ts(10, color: isSel ? Colors.white70 : C.muted)),
              SizedBox(
                height: 6,
                child: (hasSpecial || hasEvent)
                    ? Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(color: hasSpecial ? context.accent : C.blue, shape: BoxShape.circle),
                      )
                    : null,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
