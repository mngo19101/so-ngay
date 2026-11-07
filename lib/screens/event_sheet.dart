import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

const categoryNames = {'study': 'Học tập', 'personal': 'Cá nhân', 'habit': 'Thói quen', 'other': 'Khác'};

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Future<void> showEventSheet(BuildContext context, DateTime date, {Event? edit}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: C.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: _EventForm(date: date, edit: edit),
    ),
  );
}

class _EventForm extends StatefulWidget {
  final DateTime date;
  final Event? edit;
  const _EventForm({required this.date, this.edit});
  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  late final title = TextEditingController(text: widget.edit?.title ?? '');
  late final location = TextEditingController(text: widget.edit?.location ?? '');
  late final duration = TextEditingController(text: (widget.edit?.durationMin ?? 60).toString());
  late DateTime date = dateOnly(widget.edit?.start ?? widget.date);
  late TimeOfDay time = widget.edit != null
      ? TimeOfDay(hour: widget.edit!.start.hour, minute: widget.edit!.start.minute)
      : const TimeOfDay(hour: 9, minute: 0);
  late String category = widget.edit?.category ?? 'personal';
  late int remind = (widget.edit?.remindBeforeMin.isNotEmpty ?? false) ? widget.edit!.remindBeforeMin.first : 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(widget.edit == null ? 'Thêm sự kiện' : 'Sửa sự kiện', style: ts(20, w: FontWeight.w700))),
            if (widget.edit != null)
              IconBtn(Icons.delete_outline_rounded, 'Xoá sự kiện', () async {
                if (await confirm(context, 'Xoá "${widget.edit!.title}"?', 'Sự kiện và nhắc nhở của nó sẽ bị xoá.')) {
                  store.deleteEvent(widget.edit!.id);
                  if (context.mounted) Navigator.pop(context);
                }
              }),
            const SizedBox(width: 8),
            IconBtn(Icons.close_rounded, 'Đóng', () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          Field('Tiêu đề', title, hint: 'Ví dụ: Học Python'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _pick('Ngày', '${wdShort(date)}, ${dm(date)}', () async {
                final d = await showDatePicker(
                    context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (d != null) setState(() => date = d);
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pick('Giờ', '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', () async {
                final t = await showTimePicker(context: context, initialTime: time);
                if (t != null) setState(() => time = t);
              }),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Field('Thời lượng (phút)', duration, keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: Field('Địa điểm', location, hint: 'Không bắt buộc')),
          ]),
          const SizedBox(height: 14),
          Text('Loại', style: ts(13, w: FontWeight.w600, color: C.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in categoryNames.entries)
              Pill(e.value, selected: category == e.key, selColor: C.categoryColor(e.key), onTap: () => setState(() => category = e.key)),
          ]),
          const SizedBox(height: 14),
          Text('Nhắc trước', style: ts(13, w: FontWeight.w600, color: C.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in const [0, 10, 30, 60])
              Pill(m == 0 ? 'Không' : m == 60 ? '1 giờ' : '$m phút', selected: remind == m, onTap: () => setState(() => remind = m)),
          ]),
          const SizedBox(height: 20),
          BigButton('Lưu sự kiện', () {
            if (title.text.trim().isEmpty) {
              toast(context, 'Hãy nhập tiêu đề');
              return;
            }
            final e = widget.edit ?? Event(id: store.newId(), title: '', start: date);
            e.title = title.text.trim();
            e.start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            e.durationMin = int.tryParse(duration.text.trim());
            e.location = location.text.trim().isEmpty ? null : location.text.trim();
            e.category = category;
            e.remindBeforeMin = remind == 0 ? [] : [remind];
            store.saveEvent(e);
            Navigator.pop(context);
          }),
        ]),
      ),
    );
  }

  Widget _pick(String label, String value, VoidCallback onTap) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ts(13, w: FontWeight.w600, color: C.muted)),
          const SizedBox(height: 6),
          Tap(
            onTap: onTap,
            child: Container(
              height: 52,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.borderInput)),
              child: Text(value, style: ts(16)),
            ),
          ),
        ],
      );
}

class EventRow extends StatelessWidget {
  final Event e;
  const EventRow(this.e, {super.key});
  @override
  Widget build(BuildContext context) {
    final sub = [
      if (e.location != null && e.location!.isNotEmpty) e.location!,
      if (e.location == null || e.location!.isEmpty) categoryNames[e.category] ?? '',
      if (e.durationMin != null) fmtMin(e.durationMin!),
    ].join(' · ');
    return Tap(
      onTap: () => showEventSheet(context, e.start, edit: e),
      onLongPress: () async {
        if (await confirm(context, 'Xoá "${e.title}"?', 'Sự kiện và nhắc nhở của nó sẽ bị xoá.')) store.deleteEvent(e.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(width: 48, child: Text(hhmm(e.start), style: ts(14, w: FontWeight.w600, color: C.muted))),
          Container(width: 4, height: 40, decoration: BoxDecoration(color: C.categoryColor(e.category), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title, style: ts(15, w: FontWeight.w600)),
              Text(sub, style: ts(12, color: C.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
