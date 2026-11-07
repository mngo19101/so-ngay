import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

const categoryNames = {'study': 'Học tập', 'personal': 'Cá nhân', 'habit': 'Thói quen', 'other': 'Khác'};

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Future<void> showEventSheet(BuildContext context, DateTime date, {Event? edit, DateTime? on}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: C.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: _EventForm(date: date, edit: edit, on: on),
    ),
  );
}

class _EventForm extends StatefulWidget {
  final DateTime date;
  final Event? edit;
  final DateTime? on; // ngày đang xem của chuỗi lặp, để xoá riêng ngày đó
  const _EventForm({required this.date, this.edit, this.on});
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
  late String repeat = widget.edit?.repeat ?? 'none';
  late Set<int> weekdays = {...?widget.edit?.repeatWeekdays};
  late DateTime? until = widget.edit?.repeatUntil;

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
                if (await confirmDeleteEvent(context, widget.edit!, widget.on) && context.mounted) Navigator.pop(context);
              }),
            const SizedBox(width: 8),
            IconBtn(Icons.close_rounded, 'Đóng', () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 16),
          Field('Tiêu đề', title, hint: 'Ví dụ: Học Python'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _pick(repeat == 'none' ? 'Ngày' : 'Bắt đầu từ', '${wdShort(date)}, ${dm(date)}', () async {
                final d = await showDatePicker(
                    context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                if (d != null) {
                  setState(() {
                    date = d;
                    if (weekdays.length <= 1) weekdays = {d.weekday};
                  });
                }
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
          const SizedBox(height: 14),
          Text('Lặp lại', style: ts(13, w: FontWeight.w600, color: C.muted)),
          const SizedBox(height: 8),
          Segmented(const ['Không', 'Hằng ngày', 'Hằng tuần'], const ['none', 'daily', 'weekly'].indexOf(repeat), (i) {
            setState(() {
              repeat = const ['none', 'daily', 'weekly'][i];
              if (repeat == 'weekly' && weekdays.isEmpty) weekdays = {date.weekday};
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
          if (repeat != 'none') ...[
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: _pick('Đến ngày', until == null ? 'Không kết thúc' : '${wdShort(until!)}, ${dm(until!)}/${until!.year}', () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: until != null && !until!.isBefore(date) ? until! : date,
                      firstDate: date,
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => until = d);
                }),
              ),
              if (until != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: IconBtn(Icons.close_rounded, 'Bỏ ngày kết thúc', () => setState(() => until = null)),
                ),
              ],
            ]),
            if (widget.edit?.repeats ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Thay đổi sẽ áp dụng cho cả chuỗi.', style: ts(12, color: C.muted)),
              ),
          ],
          const SizedBox(height: 20),
          BigButton('Lưu sự kiện', () {
            if (title.text.trim().isEmpty) {
              toast(context, 'Hãy nhập tiêu đề');
              return;
            }
            if (repeat == 'weekly' && weekdays.isEmpty) {
              toast(context, 'Chọn ít nhất 1 thứ trong tuần');
              return;
            }
            if (repeat != 'none' && until != null && until!.isBefore(date)) {
              toast(context, 'Ngày kết thúc phải sau ngày bắt đầu');
              return;
            }
            final e = widget.edit ?? Event(id: store.newId(), title: '', start: date);
            e.title = title.text.trim();
            e.start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            e.durationMin = int.tryParse(duration.text.trim());
            e.location = location.text.trim().isEmpty ? null : location.text.trim();
            e.category = category;
            e.remindBeforeMin = remind == 0 ? [] : [remind];
            e.repeat = repeat;
            e.repeatWeekdays = repeat == 'weekly' ? (weekdays.toList()..sort()) : [];
            e.repeatUntil = repeat == 'none' ? null : until;
            if (repeat == 'none') e.skipDates = [];
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

/// Xác nhận rồi xoá. Sự kiện lặp được chọn xoá riêng ngày [on] hoặc cả chuỗi.
/// Trả về true nếu đã xoá.
Future<bool> confirmDeleteEvent(BuildContext context, Event e, DateTime? on) async {
  if (!e.repeats || on == null) {
    final ok = await confirm(context, 'Xoá "${e.title}"?', 'Sự kiện và nhắc nhở của nó sẽ bị xoá.');
    if (ok) store.deleteEvent(e.id);
    return ok;
  }
  final choice = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('Xoá "${e.title}"?', style: ts(18, w: FontWeight.w700)),
      content: Text('Đây là sự kiện lặp lại.', style: ts(15, color: C.muted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text('Huỷ', style: ts(15, w: FontWeight.w600, color: C.muted))),
        TextButton(onPressed: () => Navigator.pop(c, 'one'), child: Text('Chỉ ngày ${dm(on)}', style: ts(15, w: FontWeight.w700, color: C.sunday))),
        TextButton(onPressed: () => Navigator.pop(c, 'all'), child: Text('Cả chuỗi', style: ts(15, w: FontWeight.w700, color: C.sunday))),
      ],
    ),
  );
  if (choice == 'one') store.skipEventOn(e, on);
  if (choice == 'all') store.deleteEvent(e.id);
  return choice != null;
}

class EventRow extends StatelessWidget {
  final Event e;

  /// Ngày đang hiển thị (sự kiện lặp có nhiều ngày).
  final DateTime? on;
  const EventRow(this.e, {super.key, this.on});
  @override
  Widget build(BuildContext context) {
    final sub = [
      if (e.location != null && e.location!.isNotEmpty) e.location!,
      if (e.location == null || e.location!.isEmpty) categoryNames[e.category] ?? '',
      if (e.durationMin != null) fmtMin(e.durationMin!),
      if (e.repeats) e.repeat == 'daily' ? 'Hằng ngày' : 'Hằng tuần',
    ].join(' · ');
    return Tap(
      onTap: () => showEventSheet(context, e.start, edit: e, on: on),
      onLongPress: () => confirmDeleteEvent(context, e, on),
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
