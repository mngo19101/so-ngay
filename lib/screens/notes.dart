import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

String two(int v) => v.toString().padLeft(2, '0');

/// "Thứ Sáu, 13/11/2026 · 18:29"
String noteDateLabel(DateTime d) => '${wdFull(d)}, ${d.day}/${d.month}/${d.year} · ${two(d.hour)}:${two(d.minute)}';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final search = TextEditingController();
  String query = '';
  DateTime? month; // null = xem tất cả, chia nhóm theo tháng

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final r = await showModalBottomSheet<({DateTime? month})>(
      context: context,
      backgroundColor: C.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => NoteMonthPicker(selected: month),
    );
    if (r == null || !mounted) return;
    setState(() => month = r.month);
  }

  Widget _monthHeader(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Text(text.toUpperCase(), style: ts(12, w: FontWeight.w700, color: C.muted, ls: 0.6)),
      );

  Widget _card(Note n) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Tap(
          label: n.title.isEmpty ? 'Ghi chú không tiêu đề' : n.title,
          onTap: () => _open(n),
          child: Box(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.title.trim().isEmpty ? 'Không tiêu đề' : n.title.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(15, w: FontWeight.w700, color: n.title.trim().isEmpty ? C.muted : C.ink)),
              if (n.body.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(n.body.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(13, color: C.muted, h: 1.4)),
              ],
              const SizedBox(height: 8),
              Text(noteDateLabel(n.date), style: ts(12, w: FontWeight.w600, color: context.accent)),
            ]),
          ),
        ),
      );

  static bool _sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

  void _open(Note? n) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditorScreen(note: n)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final m = month;
        final list = store.notesSorted(query, m);
        return Stack(children: [
          ScreenBody(top: 12, children: [
            ScreenHeader('Ghi chú', subtitle: '${store.notes.length} ghi chú'),
            if (store.notes.isNotEmpty) ...[
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: TextField(
                      controller: search,
                      onChanged: (v) => setState(() => query = v),
                      style: ts(15),
                      decoration: inputDeco('Tìm ghi chú…').copyWith(
                        prefixIcon: Icon(Icons.search_rounded, color: C.muted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tap(
                    label: 'Xem ghi chú theo tháng',
                    onTap: _pickMonth,
                    child: Container(
                      width: 50,
                      decoration: BoxDecoration(
                        color: m == null ? C.surface : context.accentSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: m == null ? C.borderInput : context.accent),
                      ),
                      child: Icon(Icons.calendar_month_rounded, size: 22, color: m == null ? C.ink : context.accent),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            if (m != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Expanded(child: _monthHeader('Tháng ${m.month}, ${m.year} · ${list.length} ghi chú')),
                  Tap(
                    label: 'Xem tất cả ghi chú',
                    onTap: () => setState(() => month = null),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 2, 4, 6),
                      child: Text('Tất cả', style: ts(13, w: FontWeight.w600, color: context.accent)),
                    ),
                  ),
                ]),
              ),
            if (list.isEmpty)
              Box(
                child: Text(
                  store.notes.isEmpty
                      ? 'Chưa có ghi chú nào. Bấm + để viết ghi chú đầu tiên.'
                      : m != null && query.trim().isEmpty
                          ? 'Tháng ${m.month}/${m.year} chưa có ghi chú nào.'
                          : 'Không tìm thấy ghi chú phù hợp.',
                  style: ts(14, color: C.muted),
                ),
              ),
            for (var i = 0; i < list.length; i++) ...[
              if (m == null && (i == 0 || !_sameMonth(list[i - 1].date, list[i].date)))
                _monthHeader('Tháng ${list[i].date.month}, ${list[i].date.year}'),
              _card(list[i]),
            ],
            const SizedBox(height: 72), // chừa chỗ cho nút +
          ]),
          Positioned(
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: Tap(
              label: 'Thêm ghi chú',
              onTap: () => _open(null),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: context.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: context.accent.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

/// Bảng chọn tháng để xem ghi chú: chọn năm, bấm tháng rồi "Xem"; "Tất cả" để bỏ lọc.
/// Tháng có ghi chú hiện số lượng, tháng trống làm mờ. Trả về `(month: null)` khi chọn "Tất cả".
class NoteMonthPicker extends StatefulWidget {
  final DateTime? selected;
  const NoteMonthPicker({super.key, this.selected});
  @override
  State<NoteMonthPicker> createState() => _NoteMonthPickerState();
}

class _NoteMonthPickerState extends State<NoteMonthPicker> {
  late DateTime? pick = widget.selected;
  late int year = widget.selected?.year ?? _latestYear();

  static int _latestYear() {
    final now = DateTime.now();
    if (store.notes.isEmpty) return now.year;
    return store.notes.map((n) => n.date).reduce((a, b) => a.isAfter(b) ? a : b).year;
  }

  @override
  Widget build(BuildContext context) {
    final counts = store.noteCountsIn(year);
    final p = pick;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: C.borderInput, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 14),
            Text('Xem ghi chú theo tháng', style: ts(18, w: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                IconBtn(Icons.chevron_left_rounded, 'Năm trước', () => setState(() => year--)),
                Expanded(
                  child: Center(
                    child: Text('$year', style: ts(20, w: FontWeight.w700)),
                  ),
                ),
                IconBtn(Icons.chevron_right_rounded, 'Năm sau', () => setState(() => year++)),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [for (var mo = 1; mo <= 12; mo++) _cell(mo, counts[mo] ?? 0, p != null && p.year == year && p.month == mo)],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: BigButton('Tất cả', () => Navigator.pop(context, (month: null)), outlined: true, textColor: C.ink)),
                const SizedBox(width: 10),
                Expanded(child: BigButton('Xem', p == null ? null : () => Navigator.pop(context, (month: p)), color: context.accent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int mo, int count, bool on) {
    final empty = count == 0;
    final fg = on ? Colors.white : (empty ? C.muted.withValues(alpha: 0.55) : C.ink);
    return Tap(
      label: 'Tháng $mo năm $year, $count ghi chú',
      onTap: empty ? null : () => setState(() => pick = DateTime(year, mo)),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? context.accent : (empty ? C.bg : C.segmentBg), borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'T$mo',
              style: ts(15, w: empty ? FontWeight.w500 : FontWeight.w700, color: fg),
            ),
            if (!empty)
              Text(
                '$count',
                style: ts(11, w: FontWeight.w500, color: fg.withValues(alpha: 0.8)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Trang viết ghi chú. Ghi chú mới tự lấy ngày giờ lúc mở; bấm vào ngày để sửa.
/// Rời trang (Lưu hoặc quay lại) là tự lưu; ghi chú trống thì bỏ.
class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});
  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final Note n;
  late final TextEditingController title;
  late final TextEditingController body;
  bool deleted = false;

  bool get isNew => widget.note == null;

  @override
  void initState() {
    super.initState();
    final o = widget.note;
    final now = DateTime.now();
    n = Note(
      id: o?.id ?? store.newId(),
      title: o?.title ?? '',
      body: o?.body ?? '',
      date: o?.date ?? now,
      updatedAt: o?.updatedAt ?? now,
    );
    title = TextEditingController(text: n.title);
    body = TextEditingController(text: n.body);
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  void _save() {
    if (deleted) return;
    n.title = title.text;
    n.body = body.text;
    final o = widget.note;
    if (o == null && n.isEmpty) return;
    if (o != null && o.title == n.title && o.body == n.body && o.date == n.date) return;
    store.saveNote(n);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: n.date, firstDate: DateTime(1900), lastDate: DateTime(2100));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(n.date));
    if (!mounted) return;
    setState(() => n.date = DateTime(d.year, d.month, d.day, t?.hour ?? n.date.hour, t?.minute ?? n.date.minute));
  }

  Future<void> _delete() async {
    if (!await confirm(context, 'Xoá ghi chú này?', 'Không thể hoàn tác.')) return;
    deleted = true;
    store.deleteNote(n.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                IconBtn(Icons.chevron_left_rounded, 'Quay lại', () => Navigator.of(context).maybePop()),
                const SizedBox(width: 12),
                Expanded(child: Text(isNew ? 'Ghi chú mới' : 'Sửa ghi chú', style: ts(18, w: FontWeight.w700))),
                if (!isNew) ...[
                  IconBtn(Icons.delete_outline_rounded, 'Xoá ghi chú', _delete, bordered: false),
                  const SizedBox(width: 4),
                ],
                Tap(
                  label: 'Lưu ghi chú',
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: context.accent, borderRadius: BorderRadius.circular(14)),
                    child: Text('Lưu', style: ts(14, w: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Tap(
                      label: 'Đổi ngày giờ ghi chú',
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: context.accentSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.accent.withValues(alpha: 0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.event_rounded, size: 18, color: context.accent),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(noteDateLabel(n.date),
                                style: ts(14, w: FontWeight.w600, color: context.accent)),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down_rounded, size: 22, color: context.accent),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: title,
                    autofocus: isNew,
                    textCapitalization: TextCapitalization.sentences,
                    style: ts(22, w: FontWeight.w700),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Tiêu đề',
                      hintStyle: ts(22, w: FontWeight.w600, color: C.muted),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: C.border)),
                  TextField(
                    controller: body,
                    maxLines: null,
                    minLines: 12,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: ts(15, h: 1.6),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Viết ghi chú ở đây…',
                      hintStyle: ts(15, color: C.muted, h: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
