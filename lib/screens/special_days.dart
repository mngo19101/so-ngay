import 'package:flutter/material.dart';

import '../logic.dart';
import '../store.dart';
import '../theme.dart';
import 'shell.dart';

class SpecialDaysScreen extends StatefulWidget {
  const SpecialDaysScreen({super.key});
  @override
  State<SpecialDaysScreen> createState() => _SpecialDaysScreenState();
}

class _SpecialDaysScreenState extends State<SpecialDaysScreen> {
  String? filter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.upcoming(type: filter);
        final off = store.specialDays.where((s) => !s.enabled && (filter == null || s.type == filter)).toList();
        return ScreenBody(top: 12, children: [
          ScreenHeader('Ngày đặc biệt',
              trailing: Tap(
                label: 'Thêm ngày đặc biệt',
                onTap: () => nav.go(AppPage.add),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(22)),
                  child: Text('+ Thêm', style: ts(14, w: FontWeight.w700, color: Colors.white)),
                ),
              )),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in const [(null, 'Tất cả'), ('birthday', 'Sinh nhật'), ('anniversary', 'Kỷ niệm'), ('holiday', 'Ngày lễ'), ('other', 'Khác')]) ...[
                Pill(f.$2, selected: filter == f.$1, onTap: () => setState(() => filter = f.$1)),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          if (list.isEmpty && off.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Chưa có ngày đặc biệt nào.', style: ts(14, color: C.muted))),
            ),
          for (final o in list) _row(context, o),
          if (off.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Đã tắt', style: ts(15, w: FontWeight.w700, color: C.muted)),
            const SizedBox(height: 8),
            for (final s in off)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Box(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(children: [
                    Expanded(child: Text(s.name, style: ts(15, color: C.muted))),
                    Switch2(false, (v) => store.toggleSpecial(s, v), 'Bật ${s.name}'),
                  ]),
                ),
              ),
          ],
        ]);
      },
    );
  }

  Widget _row(BuildContext context, SpecialOcc o) {
    final sd = o.sd;
    final colors = C.typeColors(sd.type);
    final lunarTxt = sd.repeat == 'weekly'
        ? 'Hằng tuần: ${sd.repeatWeekdays.map((w) => weekdayShort[w - 1]).join(', ')}'
        : 'Âm lịch ${lunarDm(o.date)}';
    final offs = sd.remindOffsetsDays.toList()..sort();
    final remind = offs.isEmpty ? 'không nhắc' : 'nhắc ${offs.map(offsetLabel).join(', ')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(sd.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: C.sunday, borderRadius: BorderRadius.circular(18)),
          child: Icon(sd.isBuiltIn ? Icons.notifications_off_outlined : Icons.delete_outline_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          if (sd.isBuiltIn) {
            store.toggleSpecial(sd, false);
            return false;
          }
          return confirm(context, 'Xoá "${sd.name}"?', 'Các thông báo của ngày này cũng sẽ bị huỷ.');
        },
        onDismissed: (_) => store.deleteSpecial(sd.id),
        child: Tap(
          onTap: () => nav.go(AppPage.add, edit: sd),
          child: Box(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(14)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${o.date.day}', style: ts(18, w: FontWeight.w700, color: colors.$2, h: 1.1)),
                  Text('Th${o.date.month}', style: ts(11, w: FontWeight.w600, color: colors.$2)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(sd.name, style: ts(15, w: FontWeight.w600)),
                  Text('$lunarTxt · $remind', maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(12, color: C.muted)),
                ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${o.daysLeft}', style: ts(22, w: FontWeight.w700, color: o.daysLeft == 0 ? context.accent : C.ink)),
                Text(o.daysLeft == 0 ? 'hôm nay' : 'ngày', style: ts(11, color: C.muted)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
