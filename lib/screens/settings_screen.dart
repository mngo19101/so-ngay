import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic.dart';
import '../store.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = store.settings;
        return ScreenBody(top: 12, children: [
          const ScreenHeader('Cài đặt'),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tên hiển thị', style: ts(13, w: FontWeight.w600, color: C.muted)),
              const SizedBox(height: 8),
              Tap(
                onTap: () async {
                  final v = await promptText(context, 'Tên của bạn', initial: s.displayName);
                  if (v != null && v.trim().isNotEmpty) store.updateSettings((x) => x.displayName = v.trim());
                },
                child: Row(children: [
                  Expanded(child: Text(s.displayName, style: ts(16, w: FontWeight.w600))),
                  Icon(Icons.edit_outlined, size: 20, color: C.muted),
                ]),
              ),
              const SizedBox(height: 18),
              Text('Màu chủ đạo', style: ts(13, w: FontWeight.w600, color: C.muted)),
              const SizedBox(height: 10),
              Row(children: [
                for (final c in C.accents)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Tap(
                      label: 'Màu chủ đạo',
                      onTap: () => store.updateSettings((x) => x.accent = c.toARGB32()),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: s.accent == c.toARGB32() ? C.ink : Colors.transparent, width: 3),
                        ),
                        child: s.accent == c.toARGB32() ? const Icon(Icons.check_rounded, color: Colors.white) : null,
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Giao diện', style: ts(15, w: FontWeight.w700)),
              const SizedBox(height: 12),
              Segmented(const ['Theo máy', 'Sáng', 'Tối'], const ['system', 'light', 'dark'].indexOf(s.themeMode),
                  (i) => store.updateSettings((x) => x.themeMode = const ['system', 'light', 'dark'][i])),
            ]),
          ),
          const SizedBox(height: 14),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mục tiêu học', style: ts(15, w: FontWeight.w700)),
              const SizedBox(height: 12),
              _goal('Mỗi ngày', fmtMin(s.dailyGoalMin), () => _bump(s.dailyGoalMin, -30, 30, 720, (v) => store.updateSettings((x) => x.dailyGoalMin = v)),
                  () => _bump(s.dailyGoalMin, 30, 30, 720, (v) => store.updateSettings((x) => x.dailyGoalMin = v))),
              const SizedBox(height: 8),
              _goal('Mỗi tuần', fmtMin(s.weeklyGoalMin), () => _bump(s.weeklyGoalMin, -60, 60, 4200, (v) => store.updateSettings((x) => x.weeklyGoalMin = v)),
                  () => _bump(s.weeklyGoalMin, 60, 60, 4200, (v) => store.updateSettings((x) => x.weeklyGoalMin = v))),
            ]),
          ),
          const SizedBox(height: 14),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sao lưu dữ liệu', style: ts(15, w: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Xuất toàn bộ dữ liệu ra JSON (sao chép vào bộ nhớ tạm) hoặc dán JSON để khôi phục.', style: ts(13, color: C.muted)),
              const SizedBox(height: 12),
              BigButton('Sao chép bản sao lưu', () async {
                await Clipboard.setData(ClipboardData(text: store.exportJson()));
                if (context.mounted) toast(context, 'Đã sao chép dữ liệu — hãy dán vào Ghi chú để lưu');
              }, outlined: true, textColor: C.ink),
              const SizedBox(height: 10),
              BigButton('Khôi phục từ JSON', () => _import(context), outlined: true, textColor: C.ink),
            ]),
          ),
          const SizedBox(height: 20),
          Center(child: Text('Sổ Ngày · dữ liệu lưu trên máy, hoạt động ngoại tuyến', style: ts(12, color: C.muted))),
        ]);
      },
    );
  }

  void _bump(int cur, int delta, int min, int max, void Function(int) set) {
    final v = (cur + delta).clamp(min, max);
    set(v);
  }

  Widget _goal(String label, String value, VoidCallback dec, VoidCallback inc) => Row(children: [
        Expanded(child: Text(label, style: ts(15))),
        IconBtn(Icons.remove_rounded, 'Giảm $label', dec),
        SizedBox(width: 72, child: Center(child: Text(value, style: ts(16, w: FontWeight.w700)))),
        IconBtn(Icons.add_rounded, 'Tăng $label', inc),
      ]);

  Future<void> _import(BuildContext context) async {
    final clip = await Clipboard.getData('text/plain');
    final ctl = TextEditingController(text: clip?.text ?? '');
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Khôi phục dữ liệu', style: ts(18, w: FontWeight.w700)),
        content: SizedBox(
          height: 180,
          child: TextField(controller: ctl, maxLines: null, expands: true, decoration: inputDeco('Dán JSON vào đây')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Huỷ', style: ts(15, color: C.muted))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Khôi phục', style: ts(15, w: FontWeight.w700, color: C.sunday))),
        ],
      ),
    );
    if (ok == true) {
      final err = store.importJson(ctl.text);
      if (context.mounted) toast(context, err ?? 'Đã khôi phục dữ liệu');
    }
  }
}
