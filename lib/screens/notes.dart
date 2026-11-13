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

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _open(Note? n) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditorScreen(note: n)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.notesSorted(query);
        return Stack(children: [
          ScreenBody(top: 12, children: [
            ScreenHeader('Ghi chú', subtitle: '${store.notes.length} ghi chú'),
            if (store.notes.isNotEmpty) ...[
              TextField(
                controller: search,
                onChanged: (v) => setState(() => query = v),
                style: ts(15),
                decoration: inputDeco('Tìm ghi chú…').copyWith(
                  prefixIcon: Icon(Icons.search_rounded, color: C.muted),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (list.isEmpty)
              Box(
                child: Text(
                  store.notes.isEmpty ? 'Chưa có ghi chú nào. Bấm + để viết ghi chú đầu tiên.' : 'Không tìm thấy ghi chú phù hợp.',
                  style: ts(14, color: C.muted),
                ),
              ),
            for (final n in list)
              Padding(
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
              ),
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
