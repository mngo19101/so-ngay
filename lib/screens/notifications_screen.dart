import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../notifications.dart';
import '../store.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _denied = 'Chưa có quyền. Vào Cài đặt iPhone > Thông báo > Sổ Ngày và bật Cho phép thông báo';

  String _when(String iso) {
    final d = DateTime.parse(iso);
    final t = store.today;
    final day = dateOnly(d);
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (day == t) return 'Hôm nay $hm';
    if (day == addDays(t, -1)) return 'Hôm qua $hm';
    return '${dm(d)} $hm';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = store.settings;
        final up = store.upcoming().where((o) => o.sd.repeat != 'weekly').toList();
        final prev = up.isEmpty ? null : up.first;
        final previewBody = prev == null
            ? 'Chưa có ngày đặc biệt nào để nhắc.'
            : '${reminderText(prev.sd.remindOffsetsDays.isEmpty ? 0 : (prev.sd.remindOffsetsDays.toList()..sort()).first, prev.sd.name)} — ${wdFull(prev.date)} ${dm(prev.date)}';
        return ScreenBody(top: 12, children: [
          const ScreenHeader('Thông báo'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: context.accent, borderRadius: BorderRadius.circular(5)),
                    ),
                    const SizedBox(width: 8),
                    Text('SỔ NGÀY · ${prev?.sd.notifyTime ?? '08:00'}', style: ts(11, w: FontWeight.w600, color: Colors.white70, ls: 0.5)),
                  ]),
                  const SizedBox(height: 8),
                  Text(previewBody, style: ts(14, color: Colors.white, h: 1.35)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              _sw('Thông báo đẩy', 'Bật/tắt tất cả thông báo', s.pushEnabled, (v) async {
                if (v) await NotificationService.instance.requestPermission();
                store.updateSettings((x) => x.pushEnabled = v, reschedule: true);
              }),
              const Divider(height: 1, color: C.border),
              _sw('Nhắc mỗi sáng', 'Lúc ${s.morningTime} · nhắc xem việc hôm nay', s.morningEnabled,
                  (v) => store.updateSettings((x) => x.morningEnabled = v, reschedule: true),
                  trailing: Tap(
                    onTap: () async {
                      final p = s.morningTime.split(':');
                      final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])));
                      if (t != null) {
                        store.updateSettings((x) => x.morningTime = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}', reschedule: true);
                      }
                    },
                    label: 'Đổi giờ tóm tắt',
                    child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.schedule_rounded, size: 20, color: C.muted)),
                  )),
              const Divider(height: 1, color: C.border),
              _sw('Nhắc ôn từ vựng', 'Mỗi tối 20:00', s.studyReminder,
                  (v) => store.updateSettings((x) => x.studyReminder = v, reschedule: true)),
              const Divider(height: 1, color: C.border),
              _sw('Âm thanh', 'Phát tiếng khi có thông báo', s.sound, (v) => store.updateSettings((x) => x.sound = v, reschedule: true)),
            ]),
          ),
          if (store.droppedReminders > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Box(
                color: C.errorBg,
                bordered: false,
                child: Text(
                  'iPhone chỉ giữ tối đa 64 lịch nhắc nên còn ${store.droppedReminders} nhắc chưa xếp được. Hãy tắt bớt ngày không cần, hoặc bớt số lần nhắc trước.',
                  style: ts(13, color: C.errorText, h: 1.35),
                ),
              ),
            ),
          const SizedBox(height: 12),
          BigButton('Gửi thông báo thử', () async {
            final ok = await store.sendTest();
            if (context.mounted) toast(context, ok ? 'Đã gửi thông báo thử' : _denied);
          }, outlined: true, textColor: C.ink),
          const SizedBox(height: 8),
          BigButton('Thử khi thoát app (sau 10 giây)', () async {
            final ok = await store.sendTest(delay: const Duration(seconds: 10));
            if (context.mounted) toast(context, ok ? 'Thoát ra màn hình chính hoặc khoá máy, thông báo đến sau 10 giây' : _denied);
          }, outlined: true, textColor: C.ink),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Gần đây', style: ts(18, w: FontWeight.w700)),
            if (store.unreadCount > 0)
              Tap(
                onTap: store.markAllRead,
                child: Padding(padding: const EdgeInsets.all(10), child: Text('Đánh dấu đã đọc', style: ts(14, w: FontWeight.w600, color: context.accent))),
              ),
          ]),
          const SizedBox(height: 8),
          if (store.notifLogs.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text('Chưa có thông báo nào được gửi.', style: ts(14, color: C.muted)))
          else
            for (final n in store.notifLogs.take(30)) _logRow(context, n),
        ]);
      },
    );
  }

  Widget _logRow(BuildContext context, NotificationLog n) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Tap(
          onTap: () {
            n.read = true;
            store.changed();
          },
          child: Box(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 10),
                decoration: BoxDecoration(color: n.read ? Colors.transparent : context.accent, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.body, style: ts(14, w: n.read ? FontWeight.w400 : FontWeight.w600, h: 1.35)),
                  const SizedBox(height: 4),
                  Text('${n.title} · ${_when(n.sentAt)}', style: ts(12, color: C.muted)),
                ]),
              ),
            ]),
          ),
        ),
      );

  Widget _sw(String title, String sub, bool v, ValueChanged<bool> on, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: ts(15, w: FontWeight.w600)),
              Text(sub, style: ts(12, color: C.muted)),
            ]),
          ),
          if (trailing != null) trailing,
          Switch2(v, on, title),
        ]),
      );
}
