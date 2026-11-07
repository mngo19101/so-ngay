import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

class StudyInputScreen extends StatefulWidget {
  const StudyInputScreen({super.key});
  @override
  State<StudyInputScreen> createState() => _StudyInputScreenState();
}

class _StudyInputScreenState extends State<StudyInputScreen> {
  String? subjectId;
  bool subtract = false;
  DateTime date = store.today;
  final hours = TextEditingController(), mins = TextEditingController();
  String? saved;
  String? lastId;
  bool adding = false;
  final newSubject = TextEditingController();

  int get total => (int.tryParse(hours.text) ?? 0) * 60 + (int.tryParse(mins.text) ?? 0);

  void _edited() => setState(() => saved = null);

  void _save() {
    final sid = subjectId ?? (store.subjects.isNotEmpty ? store.subjects.first.id : null);
    if (sid == null) return;
    var amount = total;
    if (subtract) {
      final avail = store.minutesOn(sid, date);
      if (amount > avail) amount = avail;
      if (amount <= 0) return;
      final s = store.addSession(sid, date, -amount);
      lastId = s.id;
      saved = 'Đã trừ ${fmtMin(amount)}';
    } else {
      if (amount <= 0) return;
      final s = store.addSession(sid, date, amount);
      lastId = s.id;
      saved = 'Đã lưu ${fmtMin(amount)}';
    }
    hours.clear();
    mins.clear();
    setState(() {});
  }

  Future<void> _pickDate() async {
    final d = await showDialog<DateTime>(context: context, builder: (c) => _CalendarPopup(selected: date));
    if (d != null) {
      setState(() {
        date = d;
        saved = null;
      });
    }
  }

  Future<void> _subjectMenu(Subject s) async {
    final act = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(s.name, style: ts(17, w: FontWeight.w700))),
          ListTile(leading: const Icon(Icons.edit_outlined), title: Text('Đổi tên', style: ts(15)), onTap: () => Navigator.pop(c, 'rename')),
          ListTile(leading: const Icon(Icons.delete_outline_rounded, color: C.sunday), title: Text('Xoá môn', style: ts(15, color: C.sunday)), onTap: () => Navigator.pop(c, 'delete')),
        ]),
      ),
    );
    if (!mounted) return;
    if (act == 'rename') {
      final n = await promptText(context, 'Đổi tên môn', initial: s.name);
      if (n != null) store.renameSubject(s, n);
    } else if (act == 'delete') {
      if (await confirm(context, 'Xoá môn "${s.name}"?', 'Mọi giờ học đã ghi của môn này cũng sẽ bị xoá.')) {
        if (subjectId == s.id) subjectId = null;
        store.deleteSubject(s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = store.today;
        if (subjectId != null && store.subjectById(subjectId!) == null) subjectId = null;
        final sid = subjectId ?? (store.subjects.isNotEmpty ? store.subjects.first.id : null);
        final avail = sid == null ? 0 : store.minutesOn(sid, date);
        final canSave = sid != null && total > 0 && (!subtract || avail > 0);
        final isToday = date == t;
        final list = store.sessionsOn(date);
        return ScreenBody(top: 12, children: [
          ScreenHeader('Giờ học', subtitle: '${wdFull(t)}, ${dm(t)}', trailing: StreakBadge(store.streak())),
          Box(
            radius: 22,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Môn học'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in store.subjects)
                  Pill(s.name,
                      selected: s.id == sid,
                      selColor: Color(s.color),
                      onTap: () => setState(() {
                            subjectId = s.id;
                            saved = null;
                          }),
                      onLongPress: () => _subjectMenu(s)),
                Pill('+ Thêm môn', dashed: true, onTap: () => setState(() => adding = !adding)),
              ]),
              if (adding) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    TextField(controller: newSubject, decoration: inputDeco('Tên môn mới'), style: ts(16)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: BigButton('Lưu môn này', () {
                          if (newSubject.text.trim().isEmpty) return;
                          final s = store.addSubject(newSubject.text);
                          setState(() {
                            subjectId = s.id;
                            adding = false;
                            newSubject.clear();
                          });
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: BigButton('Huỷ', () => setState(() => adding = false), outlined: true, textColor: C.ink)),
                    ]),
                  ]),
                ),
              ],
              const SizedBox(height: 18),
              _label('Chế độ'),
              Segmented(const ['+ Cộng', '− Trừ'], subtract ? 1 : 0, (i) => setState(() {
                    subtract = i == 1;
                    saved = null;
                  })),
              const SizedBox(height: 18),
              _label('Ngày'),
              Row(children: [
                IconBtn(Icons.chevron_left_rounded, 'Ngày trước', () => setState(() {
                      date = addDays(date, -1);
                      saved = null;
                    })),
                const SizedBox(width: 8),
                Expanded(
                  child: Tap(
                    label: 'Chọn ngày',
                    onTap: _pickDate,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(22), border: Border.all(color: C.border)),
                      child: Text('${wdShort(date)}, ${dm(date)}${isToday ? ' · Hôm nay' : ''} ▾',
                          softWrap: false, overflow: TextOverflow.ellipsis, style: ts(14, w: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconBtn(Icons.chevron_right_rounded, 'Ngày sau', isToday ? null : () => setState(() {
                      date = addDays(date, 1);
                      saved = null;
                    })),
              ]),
              const SizedBox(height: 18),
              _label(subtract ? 'Thời gian trừ (tối đa ${fmtMin(avail)})' : 'Thời gian'),
              Row(children: [
                Expanded(child: _num(hours, 'giờ', 'Số giờ')),
                const SizedBox(width: 12),
                Expanded(child: _num(mins, 'phút', 'Số phút')),
              ]),
              const SizedBox(height: 18),
              BigButton(subtract ? 'Trừ giờ đã chọn' : 'Lưu phiên học', canSave ? _save : null, color: context.accent),
              if (saved != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.check_circle_rounded, size: 18, color: C.green),
                    const SizedBox(width: 6),
                    Text(saved!, style: ts(14, w: FontWeight.w600, color: C.successText)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 22),
          Text('Đã ghi · ${isToday ? 'Hôm nay' : '${wdShort(date)}, ${dm(date)}'}', style: ts(17, w: FontWeight.w700)),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Padding(padding: const EdgeInsets.all(8), child: Text('Chưa có giờ học nào trong ngày này', style: ts(14, color: C.muted)))
          else
            for (final s in list) _sessionRow(s),
        ]);
      },
    );
  }

  Widget _sessionRow(StudySession s) {
    final sub = store.subjectById(s.subjectId);
    final neg = s.minutes < 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(s.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: C.sunday, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          final ok = store.deleteSession(s);
          if (!ok) toast(context, 'Không thể xoá: sẽ làm tổng giờ của môn này bị âm');
          return false;
        },
        child: Box(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(sub?.color ?? 0xFF8A8892), shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(sub?.name ?? 'Khác', style: ts(15, w: FontWeight.w600))),
            if (s.id == lastId)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: context.accentSoft, borderRadius: BorderRadius.circular(8)),
                child: Text('Mới', style: ts(11, w: FontWeight.w700, color: context.accent)),
              ),
            Text('${neg ? '−' : '+'}${fmtMin(s.minutes.abs())}', style: ts(15, w: FontWeight.w700, color: neg ? C.sunday : C.green)),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: ts(13, w: FontWeight.w600, color: C.muted)));

  Widget _num(TextEditingController c, String unit, String label) => Semantics(
        label: label,
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          onChanged: (_) => _edited(),
          style: ts(20, w: FontWeight.w700),
          decoration: inputDeco('0').copyWith(suffixText: unit, suffixStyle: ts(14, color: C.muted)),
        ),
      );
}

class _CalendarPopup extends StatefulWidget {
  final DateTime selected;
  const _CalendarPopup({required this.selected});
  @override
  State<_CalendarPopup> createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<_CalendarPopup> {
  late DateTime month = DateTime(widget.selected.year, widget.selected.month);

  @override
  Widget build(BuildContext context) {
    final t = store.today;
    final first = DateTime(month.year, month.month, 1);
    final start = addDays(first, -(first.weekday - 1));
    final canNext = DateTime(month.year, month.month + 1).isBefore(DateTime(t.year, t.month + 1));
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            IconBtn(Icons.chevron_left_rounded, 'Tháng trước', () => setState(() => month = DateTime(month.year, month.month - 1))),
            Expanded(child: Center(child: Text('Tháng ${month.month}, ${month.year}', style: ts(16, w: FontWeight.w700)))),
            IconBtn(Icons.chevron_right_rounded, 'Tháng sau', canNext ? () => setState(() => month = DateTime(month.year, month.month + 1)) : null),
          ]),
          const SizedBox(height: 8),
          Row(children: [for (final w in weekdayShort) Expanded(child: Center(child: Text(w, style: ts(12, color: C.muted))))]),
          for (var r = 0; r < 6; r++)
            Row(children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Builder(builder: (context) {
                    final d = addDays(start, r * 7 + c);
                    final future = d.isAfter(t);
                    final inM = d.month == month.month;
                    final sel = d == widget.selected;
                    final has = store.dayTotalCached(d) > 0;
                    return Opacity(
                      opacity: future ? 0.3 : (inM ? 1 : 0.45),
                      child: Tap(
                        onTap: future ? null : () => Navigator.pop(context, d),
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(color: sel ? C.ink : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('${d.day}', style: ts(14, w: FontWeight.w600, color: sel ? Colors.white : C.ink)),
                            SizedBox(height: 6, child: has ? Container(width: 5, height: 5, decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle)) : null),
                          ]),
                        ),
                      ),
                    );
                  }),
                ),
            ]),
        ]),
      ),
    );
  }
}
