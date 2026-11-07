import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

class _Bucket {
  final String label;
  final String aria;
  final DateTime from, to; // bao gồm
  final int minutes;
  final bool elapsed;
  _Bucket(this.label, this.aria, this.from, this.to, this.minutes, this.elapsed);
}

class StudyChartScreen extends StatefulWidget {
  const StudyChartScreen({super.key});
  @override
  State<StudyChartScreen> createState() => _StudyChartScreenState();
}

class _StudyChartScreenState extends State<StudyChartScreen> {
  bool monthMode = false;
  int offset = 0;
  int kind = 0; // 0 cột, 1 mục tiêu
  int? sel;
  bool editGoal = false;

  int _sum(DateTime from, DateTime to) {
    var t = 0;
    for (final s in store.sessions) {
      final d = parseDate(s.date);
      if (!d.isBefore(from) && !d.isAfter(to)) t += s.minutes;
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = store.today;
        final st = store.settings;
        late DateTime pFrom, pTo;
        final buckets = <_Bucket>[];
        late String title, sub;
        late int goalPer, goalTotal;
        if (!monthMode) {
          pFrom = addDays(mondayOf(t), -7 * offset);
          pTo = addDays(pFrom, 6);
          for (var i = 0; i < 7; i++) {
            final d = addDays(pFrom, i);
            buckets.add(_Bucket(weekdayShort[i], '${weekdayFull[i]} ${dm(d)}', d, d, store.dayTotal(d), !d.isAfter(t)));
          }
          title = 'Tuần ${dm(pFrom)}–${dm(pTo)}';
          sub = offset == 0 ? 'Tuần này' : offset == 1 ? 'Tuần trước' : '$offset tuần trước';
          goalPer = st.dailyGoalMin;
          goalTotal = st.weeklyGoalMin;
        } else {
          final m = DateTime(t.year, t.month - offset);
          pFrom = DateTime(m.year, m.month, 1);
          pTo = DateTime(m.year, m.month + 1, 0);
          var mon = mondayOf(pFrom);
          while (!mon.isAfter(pTo)) {
            final a = mon.isBefore(pFrom) ? pFrom : mon;
            var b = addDays(mon, 6);
            if (b.isAfter(pTo)) b = pTo;
            buckets.add(_Bucket(dm(mon), 'Tuần từ ${dm(mon)}', a, b, _sum(a, b), !mon.isAfter(t)));
            mon = addDays(mon, 7);
          }
          title = 'Tháng ${m.month}/${m.year}';
          sub = offset == 0 ? 'Tháng này' : offset == 1 ? 'Tháng trước' : '$offset tháng trước';
          goalPer = st.weeklyGoalMin;
          goalTotal = st.weeklyGoalMin * math.max(1, buckets.where((b) => b.elapsed).length);
        }
        final elapsedN = buckets.where((b) => b.elapsed).length;
        final total = buckets.fold<int>(0, (a, b) => a + b.minutes);
        final hit = buckets.where((b) => b.elapsed && b.minutes >= goalPer).length;
        final studiedDays = monthMode
            ? elapsedN
            : buckets.where((b) => b.minutes > 0).length;
        final avg = studiedDays == 0 ? 0 : (total / studiedDays).round();
        int defaultSel() {
          for (var i = buckets.length - 1; i >= 0; i--) {
            if (buckets[i].elapsed) return i;
          }
          return 0;
        }

        final si = (sel != null && sel! < buckets.length) ? sel! : defaultSel();
        final b = buckets[si];
        final goalLabel = monthMode ? '${fmtMin(st.weeklyGoalMin)}/tuần' : '${fmtMin(st.dailyGoalMin)}/ngày';

        return ScreenBody(top: 12, children: [
          ScreenHeader('Biểu đồ', subtitle: '$title · $sub', trailing: StreakBadge(store.streak())),
          Row(children: [
            _stat(monthMode ? 'Cả tháng' : 'Cả tuần', fmtMin(total)),
            const SizedBox(width: 8),
            _stat(monthMode ? 'TB mỗi tuần' : 'TB mỗi ngày học', fmtMin(avg)),
            const SizedBox(width: 8),
            _stat('Đạt mục tiêu', '$hit/$elapsedN'),
          ]),
          const SizedBox(height: 14),
          Box(
            radius: 22,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Segmented(const ['Theo tuần', 'Theo tháng'], monthMode ? 1 : 0, (i) => setState(() {
                    monthMode = i == 1;
                    offset = 0;
                    sel = null;
                  })),
              const SizedBox(height: 12),
              Row(children: [
                IconBtn(Icons.chevron_left_rounded, 'Kỳ trước', () => setState(() {
                      offset++;
                      sel = null;
                    })),
                Expanded(
                  child: Column(children: [
                    Text(title, style: ts(15, w: FontWeight.w700)),
                    Text(sub, style: ts(12, color: C.muted)),
                  ]),
                ),
                IconBtn(Icons.chevron_right_rounded, 'Kỳ sau', offset == 0 ? null : () => setState(() {
                      offset--;
                      sel = null;
                    })),
              ]),
              const SizedBox(height: 12),
              _goalRow(context, st),
              const SizedBox(height: 14),
              Row(children: [
                for (final k in const [(0, 'Cột'), (1, 'Mục tiêu')]) ...[
                  Semantics(
                    selected: kind == k.$1,
                    child: Pill(k.$2, selected: kind == k.$1, onTap: () => setState(() => kind = k.$1)),
                  ),
                  const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 14),
              Text(b.elapsed ? '${b.aria} — ${fmtMin(b.minutes)}' : '${b.aria} — chưa tới', style: ts(15, w: FontWeight.w700)),
              Text(
                  !b.elapsed
                      ? 'Mục tiêu $goalLabel'
                      : b.minutes >= goalPer
                          ? 'Đạt mục tiêu $goalLabel'
                          : 'Còn thiếu ${fmtMin(goalPer - b.minutes)} so với mục tiêu $goalLabel',
                  style: ts(13, color: C.muted)),
              const SizedBox(height: 14),
              if (kind == 0) _bars(buckets, goalPer, si, goalLabel) else _goalView(buckets, goalPer, goalTotal, total, si),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Theo môn học', style: ts(17, w: FontWeight.w700)),
          const SizedBox(height: 10),
          _bySubject(pFrom, pTo),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: C.streakBg, borderRadius: BorderRadius.circular(18)),
            child: Text(_hint(buckets, goalTotal, total, elapsedN), style: ts(14, color: C.streakText, h: 1.4)),
          ),
        ]);
      },
    );
  }

  String _hint(List<_Bucket> bs, int goalTotal, int total, int elapsedN) {
    if (total <= 0) return 'Kỳ này chưa có giờ học nào được ghi lại.';
    final best = bs.reduce((a, b) => a.minutes >= b.minutes ? a : b);
    final bestName = monthMode ? 'tuần ${best.label}' : weekdayFull[best.from.weekday - 1];
    final left = goalTotal - total;
    final tail = left > 0 ? ' Còn thiếu ${fmtMin(left)} để đạt mục tiêu ${monthMode ? 'tháng' : 'tuần'}.' : ' Bạn đã đạt mục tiêu của kỳ này, tuyệt vời!';
    return 'Bạn học nhiều nhất vào $bestName (${fmtMin(best.minutes)}).$tail';
  }

  Widget _stat(String label, String value) => Expanded(
        child: Box(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Column(children: [
            Text(value, style: ts(18, w: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: ts(11, color: C.muted)),
          ]),
        ),
      );

  Widget _goalRow(BuildContext context, Settings st) {
    if (!editGoal) {
      return Container(
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(child: Text('Mục tiêu học · ${fmtMin(st.dailyGoalMin)}/ngày · ${fmtMin(st.weeklyGoalMin)}/tuần', style: ts(13, color: C.muted))),
          Tap(
            onTap: () => setState(() => editGoal = true),
            child: Padding(padding: const EdgeInsets.all(14), child: Text('Sửa', style: ts(14, w: FontWeight.w700, color: context.accent))),
          ),
        ]),
      );
    }
    Widget row(String label, String value, VoidCallback dec, VoidCallback inc) => Row(children: [
          Expanded(child: Text(label, style: ts(14, w: FontWeight.w600))),
          IconBtn(Icons.remove_rounded, 'Giảm $label', dec),
          SizedBox(width: 64, child: Center(child: Text(value, style: ts(15, w: FontWeight.w700)))),
          IconBtn(Icons.add_rounded, 'Tăng $label', inc),
        ]);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        row('Mỗi ngày', fmtMin(st.dailyGoalMin), () => store.updateSettings((x) => x.dailyGoalMin = math.max(30, x.dailyGoalMin - 30)),
            () => store.updateSettings((x) => x.dailyGoalMin = math.min(720, x.dailyGoalMin + 30))),
        row('Mỗi tuần', fmtMin(st.weeklyGoalMin), () => store.updateSettings((x) => x.weeklyGoalMin = math.max(60, x.weeklyGoalMin - 60)),
            () => store.updateSettings((x) => x.weeklyGoalMin = math.min(4200, x.weeklyGoalMin + 60))),
        const SizedBox(height: 4),
        Text('Mục tiêu tuần ${fmtMin(st.weeklyGoalMin)} ≈ ${fmtMin((st.weeklyGoalMin / 7).round())} mỗi ngày', style: ts(12, color: C.muted)),
        Align(
          alignment: Alignment.centerRight,
          child: Tap(
            onTap: () => setState(() => editGoal = false),
            child: Padding(padding: const EdgeInsets.all(10), child: Text('Xong', style: ts(14, w: FontWeight.w700, color: context.accent))),
          ),
        ),
      ]),
    );
  }

  Widget _bars(List<_Bucket> bs, int goalPer, int si, String goalLabel) {
    final maxV = bs.fold<int>(0, (a, b) => math.max(a, b.minutes));
    final scale = math.max(maxV, goalPer) * 1.1;
    const h = 170.0;
    return Column(children: [
      SizedBox(
        height: h + 38,
        child: Stack(children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 38 + h * (goalPer / scale),
            child: CustomPaint(size: const Size(double.infinity, 1), painter: _DashPainter()),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < bs.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  label: '${bs[i].aria}: ${bs[i].elapsed ? fmtMin(bs[i].minutes) : 'chưa tới'}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => sel = i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(bs[i].elapsed ? (bs[i].minutes > 0 ? fmtMin(bs[i].minutes) : '0') : '—', style: ts(10, color: C.muted)),
                      const SizedBox(height: 4),
                      Container(
                        width: math.min(30.0, 100),
                        height: math.max(2.0, bs[i].elapsed ? h * (math.max(0, bs[i].minutes) / scale) * 0.85 : 2),
                        decoration: BoxDecoration(
                          color: bs[i].elapsed ? (i == si ? C.barSelected : C.bar) : C.segmentBg,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(bs[i].label, style: ts(11, w: i == si ? FontWeight.w700 : FontWeight.w400, color: C.muted)),
                      const SizedBox(height: 10),
                    ]),
                  ),
                ),
              ),
          ]),
        ]),
      ),
      Row(children: [
        SizedBox(width: 22, child: CustomPaint(size: const Size(22, 1), painter: _DashPainter())),
        const SizedBox(width: 8),
        Text('Mục tiêu $goalLabel', style: ts(12, color: C.muted)),
      ]),
    ]);
  }

  Widget _goalView(List<_Bucket> bs, int goalPer, int goalTotal, int total, int si) {
    final frac = goalTotal == 0 ? 0.0 : (total / goalTotal).clamp(0.0, 1.0);
    return SizedBox(
      width: double.infinity,
      child: Column(children: [
      SizedBox(
        width: 170,
        height: 170,
        child: CustomPaint(
          painter: _RingPainter(frac, C.green, C.segmentBg, 14),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${goalTotal == 0 ? 0 : (total * 100 / goalTotal).round()}%', style: ts(32, w: FontWeight.w700)),
              Text('${fmtMin(total)} / ${fmtMin(goalTotal)}', style: ts(12, color: C.muted)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
        for (var i = 0; i < bs.length; i++) _miniRing(bs[i], goalPer, i == si, () => setState(() => sel = i)),
      ]),
      const SizedBox(height: 14),
      Wrap(spacing: 14, runSpacing: 6, alignment: WrapAlignment.center, children: [
        _legend(C.green, 'Đạt', true),
        _legend(C.borderInput, 'Chưa đạt', false),
        _legend(C.borderInput, 'Chưa tới', false, dashed: true),
      ]),
    ]));
  }

  Widget _miniRing(_Bucket b, int goalPer, bool selected, VoidCallback tap) {
    final hit = b.elapsed && b.minutes >= goalPer;
    final pct = goalPer == 0 ? 0 : (b.minutes * 100 / goalPer).round();
    return Semantics(
      button: true,
      label: '${b.aria}: ${b.elapsed ? fmtMin(b.minutes) : 'chưa tới'}',
      child: GestureDetector(
        onTap: tap,
        child: Column(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hit ? C.green : Colors.transparent,
              border: Border.all(color: b.elapsed ? (hit ? C.green : C.borderInput) : C.borderInput, width: selected ? 3 : 1.5),
            ),
            alignment: Alignment.center,
            child: Text(!b.elapsed ? '—' : hit ? 'Đạt' : '$pct%', style: ts(11, w: FontWeight.w700, color: hit ? Colors.white : C.muted)),
          ),
          const SizedBox(height: 4),
          Text(b.label, style: ts(11, color: C.muted)),
        ]),
      ),
    );
  }

  Widget _legend(Color c, String t, bool filled, {bool dashed = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: filled ? c : Colors.transparent, border: Border.all(color: c, width: 1.5)),
        ),
        const SizedBox(width: 6),
        Text(t, style: ts(12, color: C.muted)),
      ]);

  Widget _bySubject(DateTime from, DateTime to) {
    final per = <String, int>{};
    for (final s in store.sessions) {
      final d = parseDate(s.date);
      if (!d.isBefore(from) && !d.isAfter(to)) per[s.subjectId] = (per[s.subjectId] ?? 0) + s.minutes;
    }
    final entries = per.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    final sum = entries.fold<int>(0, (a, e) => a + e.value);
    if (entries.isEmpty) return Text('Chưa có dữ liệu trong kỳ này.', style: ts(14, color: C.muted));
    return Column(children: [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${store.subjectById(e.key)?.name ?? 'Khác'} — ${fmtMin(e.value)} · ${(e.value * 100 / sum).round()}%', style: ts(13, w: FontWeight.w600)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: e.value / sum,
                minHeight: 10,
                backgroundColor: C.segmentBg,
                color: Color(store.subjectById(e.key)?.color ?? 0xFF8A8892),
              ),
            ),
          ]),
        ),
    ]);
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF8A8892)
      ..strokeWidth = 1.5;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 5, size.width), 0), p);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _RingPainter extends CustomPainter {
  final double frac;
  final Color color, track;
  final double width;
  _RingPainter(this.frac, this.color, this.track, this.width);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(width / 2);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = track;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(r, 0, math.pi * 2, false, bg);
    if (frac > 0) canvas.drawArc(r, -math.pi / 2, math.pi * 2 * frac, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.frac != frac || old.color != color || old.track != track;
}
