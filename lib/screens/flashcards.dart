import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_tts/flutter_tts.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int tab = 0;
  late String deckId = store.decks.first.id;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.decks.any((d) => d.id == deckId)) deckId = store.decks.first.id;
        final deck = store.decks.firstWhere((d) => d.id == deckId);
        final total = store.deckCards(deckId).length;
        final due = store.dueCards(deckId).length;
        return ScreenBody(top: 12, children: [
          ScreenHeader('Flashcard',
              subtitle: 'Bộ ${deck.name} · $total từ · cần ôn $due', trailing: StreakBadge(store.streak())),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final d in store.decks) ...[
                Pill(d.name, selected: d.id == deckId, onTap: () => setState(() => deckId = d.id)),
                const SizedBox(width: 8),
              ],
              Pill('+ Bộ mới', dashed: true, onTap: () async {
                final n = await promptText(context, 'Tên bộ thẻ mới', hint: 'Ví dụ: TOEIC');
                if (n != null && n.trim().isNotEmpty) setState(() => deckId = store.addDeck(n).id);
              }),
            ]),
          ),
          const SizedBox(height: 14),
          Segmented(const ['Học', 'Thêm từ', 'Dò lại'], tab, (i) => setState(() => tab = i)),
          const SizedBox(height: 16),
          if (tab == 0) StudyTab(key: ValueKey('study$deckId'), deckId: deckId),
          if (tab == 1) AddWordTab(key: ValueKey('add$deckId'), deckId: deckId),
          if (tab == 2) QuizTab(key: ValueKey('quiz$deckId'), deckId: deckId),
        ]);
      },
    );
  }
}

String _days(int n) => n >= 60 ? '${(n / 30).round()} tháng' : '$n ngày';

DateTime? _nextDue(List<Card> cards) {
  DateTime? best;
  for (final c in cards) {
    if (c.dueDate.isAfter(store.today) && (best == null || c.dueDate.isBefore(best))) best = c.dueDate;
  }
  return best;
}

String _whenText(DateTime d) {
  final n = d.difference(store.today).inDays;
  return n == 1 ? 'ngày mai (${dm(d)})' : 'sau $n ngày (${dm(d)})';
}

// ---------------- Học ----------------
class StudyTab extends StatefulWidget {
  final String deckId;
  const StudyTab({super.key, required this.deckId});
  @override
  State<StudyTab> createState() => _StudyTabState();
}

class _StudyTabState extends State<StudyTab> {
  late List<Card> queue = store.dueCards(widget.deckId);
  int i = 0, known = 0, unknown = 0;
  bool flipped = false;

  void _answer(bool k) {
    store.review(queue[i], k);
    setState(() {
      if (k) {
        known++;
      } else {
        unknown++;
      }
      i++;
      flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty || i >= queue.length) {
      final all = store.deckCards(widget.deckId);
      return Box(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Icon(Icons.check_circle_outline_rounded, size: 48, color: C.green),
          const SizedBox(height: 12),
          Text(queue.isEmpty ? 'Không có thẻ nào cần ôn hôm nay' : 'Xong lượt ôn!', style: ts(17, w: FontWeight.w700)),
          if (_nextDue(all) != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Lượt ôn kế tiếp: ${_whenText(_nextDue(all)!)}', style: ts(14, color: C.muted)),
            ),
          if (queue.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Đã nhớ $known · Chưa nhớ $unknown', style: ts(14, color: C.muted))),
          const SizedBox(height: 16),
          if (all.isNotEmpty)
            BigButton('Ôn lại toàn bộ bộ thẻ', () {
              setState(() {
                queue = [...all]..shuffle();
                i = 0;
                known = 0;
                unknown = 0;
                flipped = false;
              });
            }),
        ]),
      );
    }
    final c = queue[i];
    return Column(children: [
      Row(children: [
        Text('Thẻ ${i + 1} / ${queue.length}', style: ts(14, w: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Đã nhớ $known', style: ts(13, w: FontWeight.w600, color: C.green)),
              const SizedBox(width: 12),
              Text('Chưa nhớ $unknown', style: ts(13, w: FontWeight.w600, color: C.sunday)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: i / queue.length, minHeight: 6, backgroundColor: C.segmentBg, color: context.accent),
      ),
      const SizedBox(height: 16),
      Tap(
        label: flipped ? 'Mặt sau, chạm để lật' : 'Mặt trước, chạm để lật',
        onTap: () => setState(() => flipped = !flipped),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (w, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(a), child: w)),
          child: Container(
            key: ValueKey(flipped),
            width: double.infinity,
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: flipped ? C.fill : C.surface,
              borderRadius: BorderRadius.circular(26),
              border: flipped ? null : Border.all(color: C.border),
            ),
            child: flipped ? _back(c) : _front(c),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        c.dueDate.isAfter(store.today)
            ? 'Ôn sớm — không đổi lịch ôn (lần tới ${dm(c.dueDate)})'
            : 'Nhớ → ôn lại sau ${_days(srsSchedule[math.min(c.stage, srsSchedule.length - 1)])} · Chưa nhớ → ngày mai',
        textAlign: TextAlign.center,
        style: ts(12, color: C.muted),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: BigButton('Chưa nhớ', () => _answer(false), outlined: true, textColor: C.sunday)),
        const SizedBox(width: 12),
        Expanded(child: BigButton('Đã nhớ', () => _answer(true), color: C.green)),
      ]),
    ]);
  }

  Widget _front(Card c) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (c.partOfSpeech != null) Text(c.partOfSpeech!, style: ts(14, color: C.muted, style: FontStyle.italic)),
        const SizedBox(height: 8),
        Text(c.word, textAlign: TextAlign.center, style: ts(38, w: FontWeight.w700, ls: -0.5)),
        if (c.ipa != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(c.ipa!, style: ts(17, color: C.muted))),
        const SizedBox(height: 28),
        Text('Chạm để lật thẻ', style: ts(13, color: C.muted)),
      ]);

  Widget _back(Card c) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(c.word, style: ts(16, color: Colors.white70)),
        const SizedBox(height: 10),
        Text(c.meaning, textAlign: TextAlign.center, style: ts(30, w: FontWeight.w700, color: Colors.white)),
        if (c.example != null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(c.example!, textAlign: TextAlign.center, style: ts(15, color: Colors.white70, style: FontStyle.italic, h: 1.4)),
          ),
      ]);
}

// ---------------- Thêm từ ----------------
class AddWordTab extends StatefulWidget {
  final String deckId;
  const AddWordTab({super.key, required this.deckId});
  @override
  State<AddWordTab> createState() => _AddWordTabState();
}

class _AddWordTabState extends State<AddWordTab> {
  final word = TextEditingController(), ipa = TextEditingController(), pos = TextEditingController();
  final meaning = TextEditingController(), example = TextEditingController(), bulk = TextEditingController();

  void _save() {
    if (word.text.trim().isEmpty || meaning.text.trim().isEmpty) {
      toast(context, 'Cần nhập từ vựng và nghĩa');
      return;
    }
    store.addCard(widget.deckId, word.text, meaning.text, ipa: ipa.text, pos: pos.text, example: example.text);
    for (final c in [word, ipa, pos, meaning, example]) {
      c.clear();
    }
    toast(context, 'Đã lưu thẻ mới');
  }

  void _bulk() {
    var n = 0;
    for (final line in bulk.text.split('\n')) {
      final m = RegExp(r'^\s*(.+?)\s*(?:–|—|-|:|\t)\s*(.+?)\s*$').firstMatch(line);
      if (m != null) {
        store.addCard(widget.deckId, m.group(1)!, m.group(2)!);
        n++;
      }
    }
    bulk.clear();
    toast(context, n == 0 ? 'Không đọc được dòng nào (dạng "từ – nghĩa")' : 'Đã thêm $n thẻ');
  }

  @override
  Widget build(BuildContext context) {
    final total = store.deckCards(widget.deckId).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Field('Từ vựng *', word),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Field('Phiên âm', ipa, hint: '/həˈləʊ/')),
        const SizedBox(width: 12),
        Expanded(child: Field('Từ loại', pos, hint: 'noun')),
      ]),
      const SizedBox(height: 12),
      Field('Nghĩa tiếng Việt *', meaning),
      const SizedBox(height: 12),
      Field('Câu ví dụ', example, maxLines: 3),
      const SizedBox(height: 16),
      BigButton('Lưu thẻ mới', _save, color: context.accent),
      const SizedBox(height: 20),
      Box(
        color: C.streakBg,
        bordered: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mẹo: thêm nhiều từ một lúc', style: ts(14, w: FontWeight.w700, color: C.streakText)),
          const SizedBox(height: 4),
          Text('Dán danh sách "từ – nghĩa", mỗi dòng một từ.', style: ts(13, color: C.streakText)),
          const SizedBox(height: 10),
          TextField(controller: bulk, maxLines: 5, minLines: 3, decoration: inputDeco('apple – quả táo\nbook – quyển sách'), style: ts(15)),
          const SizedBox(height: 10),
          BigButton('Thêm tất cả', _bulk),
        ]),
      ),
      const SizedBox(height: 20),
      Tap(
        label: 'Mở kho từ vựng',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VocabBankScreen(deckId: widget.deckId)),
        ),
        child: Box(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: context.accentSoft, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.inventory_2_outlined, size: 22, color: context.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kho từ vựng', style: ts(16, w: FontWeight.w700)),
                Text('$total từ · tìm kiếm và xoá', style: ts(13, color: C.muted)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: C.muted),
          ]),
        ),
      ),
    ]);
  }
}

// ---------------- Kho từ vựng (mỗi bộ một kho) ----------------
class VocabBankScreen extends StatefulWidget {
  final String deckId;
  const VocabBankScreen({super.key, required this.deckId});
  @override
  State<VocabBankScreen> createState() => _VocabBankScreenState();
}

class _VocabBankScreenState extends State<VocabBankScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _delete(Card c) async {
    if (await confirm(context, 'Xoá "${c.word}"?', 'Từ này sẽ bị xoá khỏi kho, không khôi phục được.')) {
      store.deleteCard(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final all = store.deckCards(widget.deckId).reversed.toList();
            final q = search.text.trim().toLowerCase();
            final found = q.isEmpty
                ? all
                : all.where((c) => c.word.toLowerCase().contains(q) || c.meaning.toLowerCase().contains(q)).toList();
            final deck = store.decks.where((d) => d.id == widget.deckId);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(children: [
                  IconBtn(Icons.chevron_left_rounded, 'Quay lại', () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kho từ vựng', style: ts(22, w: FontWeight.w700, ls: -0.3)),
                      Text('Bộ ${deck.isEmpty ? '' : deck.first.name} · ${all.length} từ', style: ts(13, color: C.muted)),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: search,
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: inputDeco('Tìm từ hoặc nghĩa').copyWith(
                    prefixIcon: Icon(Icons.search_rounded, color: C.muted),
                    suffixIcon: q.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xoá nội dung tìm',
                            icon: Icon(Icons.close_rounded, color: C.muted),
                            onPressed: () => setState(search.clear),
                          ),
                  ),
                  style: ts(16),
                ),
              ),
              Expanded(
                child: found.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(all.isEmpty ? 'Kho trống. Hãy thêm từ mới trước.' : 'Không tìm thấy từ nào',
                              textAlign: TextAlign.center, style: ts(14, color: C.muted)),
                        ),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: found.length,
                        itemBuilder: (context, i) => _row(context, found[i]),
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Card c) {
    final later = c.dueDate.isAfter(store.today);
    final status = c.stage == 0 && c.correctCount == 0 ? 'Mới' : (later ? 'Ôn ${dm(c.dueDate)}' : 'Cần ôn');
    return Padding(
      key: ValueKey(c.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Box(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.word, style: ts(15, w: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(c.meaning, style: ts(14, color: C.muted)),
            ]),
          ),
          const SizedBox(width: 10),
          Text(status, style: ts(12, w: FontWeight.w600, color: later ? C.green : context.accent)),
          IconBtn(Icons.delete_outline_rounded, 'Xoá ${c.word}', () => _delete(c), bordered: false),
        ]),
      ),
    );
  }
}

// ---------------- Dò lại ----------------
enum QuizMode { viEn, enVi, listenPick, listenType }

const _modeInfo = {
  QuizMode.viEn: ('Việt → Anh', 'Gõ từ tiếng Anh', Icons.translate_rounded),
  QuizMode.enVi: ('Anh → Việt', 'Chọn nghĩa đúng', Icons.swap_horiz_rounded),
  QuizMode.listenPick: ('Nghe chọn từ', 'Nghe rồi chọn từ', Icons.headphones_rounded),
  QuizMode.listenType: ('Nghe viết từ', 'Nghe rồi gõ lại', Icons.keyboard_alt_outlined),
};

int levenshtein(String a, String b) {
  if (a == b) return 0;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0);
    cur[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
    }
    prev = cur;
  }
  return prev[b.length];
}

String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class QuizTab extends StatefulWidget {
  final String deckId;
  const QuizTab({super.key, required this.deckId});
  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  QuizMode? mode;
  List<Card> qs = [];
  List<String> options = [];
  int q = 0, score = 0, streak = 0;
  bool answered = false, lastOk = false, near = false, finished = false;
  String? picked;
  final input = TextEditingController();
  final rnd = math.Random();
  FlutterTts? _tts;

  bool get _choice => mode == QuizMode.enVi || mode == QuizMode.listenPick;
  bool get _listen => mode == QuizMode.listenPick || mode == QuizMode.listenType;

  Future<void> _speak(String text, {double rate = 0.9}) async {
    try {
      if (_tts == null) {
        _tts = FlutterTts();
        await _tts!.setLanguage('en-US');
        await _tts!.setSharedInstance(true);
        await _tts!.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback, [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker]);
      }
      await _tts!.setSpeechRate(rate * 0.5 + (rate > 0.7 ? 0 : 0));
      await _tts!.speak(text);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }

  void _start(QuizMode m) {
    final pool = store.deckCards(widget.deckId);
    final need = (m == QuizMode.enVi || m == QuizMode.listenPick) ? 2 : 1;
    if (pool.length < need) {
      toast(context, 'Bộ thẻ cần ít nhất $need từ cho trò này');
      return;
    }
    pool.shuffle(rnd);
    setState(() {
      mode = m;
      qs = pool.take(math.min(10, pool.length)).toList();
      q = 0;
      score = 0;
      streak = 0;
      finished = false;
    });
    _prepare();
  }

  void _prepare() {
    final c = qs[q];
    input.clear();
    answered = false;
    picked = null;
    options = [];
    if (_choice) {
      final others = store.deckCards(widget.deckId).where((x) => x.id != c.id).toList()..shuffle(rnd);
      final list = [
        mode == QuizMode.enVi ? c.meaning : c.word,
        ...others.take(3).map((x) => mode == QuizMode.enVi ? x.meaning : x.word),
      ]..shuffle(rnd);
      options = list;
    }
    setState(() {});
    if (_listen) _speak(c.word);
  }

  void _check() {
    final c = qs[q];
    bool ok;
    var nearMiss = false;
    if (_choice) {
      final correct = mode == QuizMode.enVi ? c.meaning : c.word;
      ok = picked == correct;
    } else {
      final a = _norm(input.text), b = _norm(c.word);
      ok = a == b;
      if (!ok && mode == QuizMode.viEn && a.isNotEmpty && levenshtein(a, b) <= 1) {
        ok = true;
        nearMiss = true;
      }
    }
    store.review(c, ok, sameDay: true);
    setState(() {
      answered = true;
      lastOk = ok;
      near = nearMiss;
      if (ok) {
        score++;
        streak++;
      } else {
        streak = 0;
      }
    });
  }

  void _next() {
    if (q + 1 >= qs.length) {
      setState(() => finished = true);
      return;
    }
    q++;
    _prepare();
  }

  @override
  Widget build(BuildContext context) {
    if (mode == null) return _menu();
    if (finished) {
      return Box(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('$score / ${qs.length}', style: ts(44, w: FontWeight.w700)),
          Text('câu đúng', style: ts(14, color: C.muted)),
          const SizedBox(height: 20),
          BigButton('Chơi lại', () => _start(mode!), color: context.accent),
          const SizedBox(height: 10),
          BigButton('Chọn trò khác', () => setState(() => mode = null), outlined: true, textColor: C.ink),
        ]),
      );
    }
    final c = qs[q];
    final canCheck = _choice ? picked != null : input.text.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Tap(
          label: 'Chọn trò khác',
          onTap: () => setState(() => mode = null),
          child: const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.arrow_back_rounded, size: 22)),
        ),
        Text('Câu ${q + 1} / ${qs.length}', style: ts(14, w: FontWeight.w600)),
        const Spacer(),
        Text('Đúng $score · chuỗi $streak', style: ts(13, w: FontWeight.w600, color: C.muted)),
      ]),
      const SizedBox(height: 12),
      Box(
        padding: const EdgeInsets.all(20),
        radius: 22,
        child: SizedBox(width: double.infinity, child: _prompt(c)),
      ),
      const SizedBox(height: 14),
      if (_choice)
        for (final o in options) _option(o, c)
      else
        TextField(
          controller: input,
          enabled: !answered,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (!answered && canCheck) _check();
          },
          decoration: inputDeco('Gõ từ tiếng Anh'),
          style: ts(18, w: FontWeight.w600),
        ),
      if (answered) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: lastOk ? C.successBg : C.errorBg, borderRadius: BorderRadius.circular(14)),
          child: Text(
            lastOk
                ? (near ? 'Gần đúng! Đáp án: ${c.word} — ${c.meaning}' : 'Chính xác! ${c.word} — ${c.meaning}')
                : 'Chưa đúng — đáp án: ${c.word} (${c.meaning})',
            style: ts(15, w: FontWeight.w600, color: lastOk ? C.successText : C.errorText),
          ),
        ),
      ],
      const SizedBox(height: 14),
      BigButton(answered ? (q + 1 >= qs.length ? 'Xem kết quả' : 'Câu tiếp theo') : 'Kiểm tra',
          answered ? _next : (canCheck ? _check : null),
          color: context.accent),
    ]);
  }

  Widget _prompt(Card c) {
    switch (mode!) {
      case QuizMode.viEn:
        final hint = c.word.split('').asMap().entries.map((e) => e.key == 0 ? e.value : (e.value == ' ' ? '/' : '_')).join(' ');
        return Column(children: [
          Text('Nghĩa tiếng Việt', style: ts(12, color: C.muted)),
          const SizedBox(height: 6),
          Text(c.meaning, textAlign: TextAlign.center, style: ts(28, w: FontWeight.w700)),
          if (c.partOfSpeech != null) Text(c.partOfSpeech!, style: ts(14, color: C.muted, style: FontStyle.italic)),
          const SizedBox(height: 10),
          Text(hint, style: ts(18, color: C.muted, ls: 1)),
        ]);
      case QuizMode.enVi:
        return Column(children: [
          if (c.partOfSpeech != null) Text(c.partOfSpeech!, style: ts(14, color: C.muted, style: FontStyle.italic)),
          Text(c.word, textAlign: TextAlign.center, style: ts(34, w: FontWeight.w700)),
          if (c.ipa != null) Text(c.ipa!, style: ts(16, color: C.muted)),
        ]);
      case QuizMode.listenPick:
      case QuizMode.listenType:
        return Column(children: [
          Tap(
            label: 'Nghe',
            onTap: () => _speak(c.word),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: context.accentSoft, shape: BoxShape.circle),
              child: Icon(Icons.volume_up_rounded, size: 34, color: context.accent),
            ),
          ),
          const SizedBox(height: 10),
          Tap(
            onTap: () => _speak(c.word, rate: 0.55),
            child: Padding(padding: const EdgeInsets.all(8), child: Text('Nghe chậm', style: ts(14, w: FontWeight.w600, color: context.accent))),
          ),
          if (mode == QuizMode.listenType) Text('${c.word.length} chữ cái', style: ts(13, color: C.muted)),
        ]);
    }
  }

  Widget _option(String o, Card c) {
    final correct = mode == QuizMode.enVi ? c.meaning : c.word;
    Color border = picked == o ? C.ink : C.borderInput;
    Color bg = C.surface;
    if (answered) {
      if (o == correct) {
        border = C.green;
        bg = C.successBg;
      } else if (o == picked) {
        border = C.sunday;
        bg = C.errorBg;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tap(
        onTap: answered ? null : () => setState(() => picked = o),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 1.5)),
          child: Text(o, style: ts(16, w: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _menu() {
    final modes = QuizMode.values;
    return Column(children: [
      for (var r = 0; r < 2; r++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            for (var c = 0; c < 2; c++) ...[
              if (c > 0) const SizedBox(width: 12),
              Expanded(
                child: Tap(
                  onTap: () => _start(modes[r * 2 + c]),
                  child: Box(
                    padding: const EdgeInsets.all(16),
                    radius: 20,
                    child: SizedBox(
                      height: 100,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(_modeInfo[modes[r * 2 + c]]!.$3, size: 26, color: context.accent),
                        const Spacer(),
                        Text(_modeInfo[modes[r * 2 + c]]!.$1, style: ts(15, w: FontWeight.w700)),
                        Text(_modeInfo[modes[r * 2 + c]]!.$2, style: ts(12, color: C.muted)),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
    ]);
  }
}
