import 'package:flutter/material.dart';

import '../logic.dart';
import '../lunar.dart';
import '../store.dart';
import '../theme.dart';
import 'event_sheet.dart';
import 'shell.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final t = store.today;
        final l = Lunar.fromSolar(t);
        final up = store.upcoming();
        final first = up.isEmpty ? null : up.first;
        final rest = up.skip(1).take(3).toList();
        final events = store.eventsOn(t);
        return ScreenBody(top: 12, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${greetingFor(now)}, ${store.settings.displayName}', style: ts(14, w: FontWeight.w500, color: C.muted)),
                const SizedBox(height: 4),
                Text('${wdFull(t)}, ${dm(t)}', style: ts(28, w: FontWeight.w700, ls: -0.5)),
                const SizedBox(height: 4),
                Text('Âm lịch ${l.day}/${l.month}${l.leap ? ' nhuận' : ''} · năm ${Lunar.yearName(l.year)}', style: ts(13, color: C.muted)),
              ]),
            ),
            Tap(
              label: 'Thông báo',
              onTap: () => nav.go(AppPage.notifs),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: C.surface, shape: BoxShape.circle, border: Border.all(color: C.border)),
                child: Stack(alignment: Alignment.center, children: [
                  const Icon(Icons.notifications_none_rounded, size: 22),
                  if (store.unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 11,
                      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: context.accent, shape: BoxShape.circle)),
                    ),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          if (first != null)
            Tap(
              onTap: () => nav.go(AppPage.special),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: context.accent, borderRadius: BorderRadius.circular(24)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Flexible(child: Text('NGÀY ĐẶC BIỆT SẮP TỚI', style: ts(12, w: FontWeight.w600, color: Colors.white, ls: 0.7))),
                    const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22),
                  ]),
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(first.sd.name, style: ts(22, w: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                            '${wdFull(first.date)}, ${dm(first.date)} · ${first.sd.remindOffsetsDays.isEmpty ? 'không nhắc' : 'nhắc ${offsetLabel((first.sd.remindOffsetsDays.toList()..sort()).first)}'}',
                            style: ts(14, color: Colors.white)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${first.daysLeft}', style: ts(44, w: FontWeight.w700, color: Colors.white, h: 1)),
                      Text(first.daysLeft == 0 ? 'hôm nay' : 'ngày nữa', style: ts(13, color: Colors.white)),
                    ]),
                  ]),
                ]),
              ),
            ),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text('Lịch hôm nay', style: ts(18, w: FontWeight.w700))),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Tap(
                label: 'Thêm sự kiện',
                onTap: () => showEventSheet(context, t),
                child: Padding(padding: const EdgeInsets.all(10), child: Text('+ Thêm', style: ts(14, w: FontWeight.w600, color: context.accent))),
              ),
              Tap(
                onTap: () => nav.go(AppPage.calendar),
                child: Padding(padding: const EdgeInsets.all(10), child: Text('Xem lịch', style: ts(14, w: FontWeight.w600, color: context.accent))),
              ),
            ]),
          ]),
          Box(
            child: events.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Hôm nay chưa có việc nào.', style: ts(14, color: C.muted)),
                  )
                : Column(children: [for (final e in events) EventRow(e, on: t)]),
          ),
          const SizedBox(height: 24),
          Text('Đếm ngược', style: ts(18, w: FontWeight.w700)),
          const SizedBox(height: 12),
          if (rest.isEmpty)
            Text('Chưa có ngày đặc biệt nào khác.', style: ts(14, color: C.muted))
          else
            Row(children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: i < rest.length
                      ? Box(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          child: Column(children: [
                            Text('${rest[i].daysLeft}', style: ts(26, w: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(rest[i].sd.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(12, color: C.muted)),
                          ]),
                        )
                      : const SizedBox(),
                ),
              ],
            ]),
        ]);
      },
    );
  }
}
