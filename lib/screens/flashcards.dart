import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_tts/flutter_tts.dart';

import '../logic.dart';
import '../models.dart';
import '../srs.dart';
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
              const SizedBox(width: 8),
              Pill('Quản lý bộ',
                  dashed: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeckManagerScreen()))),
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

/// Danh sách mọi bộ thẻ: đổi tên, xoá (kèm thẻ trong bộ), thêm bộ mới.
class DeckManagerScreen extends StatelessWidget {
  const DeckManagerScreen({super.key});

  Future<void> _rename(BuildContext context, Deck d) async {
    final n = await promptText(context, 'Đổi tên bộ', initial: d.name);
    if (n == null || !context.mounted || n.trim() == d.name) return;
    if (n.trim().isEmpty) {
      toast(context, 'Tên bộ không được để trống');
    } else if (!store.renameDeck(d.id, n)) {
      toast(context, 'Đã có bộ tên "${n.trim()}"');
    }
  }

  Future<void> _delete(BuildContext context, Deck d) async {
    final count = store.deckCards(d.id).length;
    final ok = await confirm(
      context,
      'Xoá bộ "${d.name}"?',
      count == 0 ? 'Bộ này chưa có từ nào.' : '$count từ trong bộ cũng sẽ bị xoá. Không thể hoàn tác.',
    );
    if (!ok || !context.mounted) return;
    if (store.deleteDeck(d.id)) toast(context, 'Đã xoá bộ ${d.name}');
  }

  Widget _action(IconData icon, String label, VoidCallback? onTap, Color bg, Color fg) => Tap(
        label: label,
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: onTap == null ? C.bg : bg, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: onTap == null ? C.borderInput : fg),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final canDelete = store.decks.length > 1;
            return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
              Row(children: [
                IconBtn(Icons.chevron_left_rounded, 'Quay lại', () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Quản lý bộ', style: ts(22, w: FontWeight.w700, ls: -0.3)),
                    Text('${store.decks.length} bộ', style: ts(13, color: C.muted)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              for (final d in store.decks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Box(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15, w: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('${store.deckCards(d.id).length} từ', style: ts(12, color: C.muted)),
                        ]),
                      ),
                      _action(Icons.edit_outlined, 'Đổi tên bộ ${d.name}', () => _rename(context, d), C.segmentBg, C.ink),
                      const SizedBox(width: 8),
                      _action(Icons.delete_outline_rounded, 'Xoá bộ ${d.name}', canDelete ? () => _delete(context, d) : null,
                          C.errorBg, C.errorText),
                    ]),
                  ),
                ),
              if (!canDelete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Text('Cần giữ lại ít nhất một bộ.', style: ts(12, color: C.muted)),
                ),
              const SizedBox(height: 6),
              BigButton('+ Bộ mới', () async {
                final n = await promptText(context, 'Tên bộ thẻ mới', hint: 'Ví dụ: TOEIC');
                if (n != null && n.trim().isNotEmpty) store.addDeck(n);
              }, outlined: true, textColor: C.ink),
            ]);
          },
        ),
      ),
    );
  }
}

/// Khoảng ôn dễ đọc: 3 ngày · 2 tháng · 1,5 năm.
String _ivl(int n) {
  if (n <= 0) return 'hôm nay';
  if (n < 30) return '$n ngày';
  if (n < 365) return '${(n / 30).round()} tháng';
  final y = n / 365;
  return '${y < 2 ? y.toStringAsFixed(1).replaceAll('.', ',') : y.round()} năm';
}

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

/// Độ nhớ trung bình (0–1) của các từ đã học; null nếu chưa học từ nào.
double? _avgMemory(List<Card> cards) {
  final l = cards.where((c) => c.stability > 0).toList();
  if (l.isEmpty) return null;
  return l.map(store.memoryOf).reduce((a, b) => a + b) / l.length;
}

FlutterTts? _ttsInst;

/// Đọc phát âm tiếng Anh (bỏ qua lỗi nếu máy không hỗ trợ).
Future<void> speakWord(String text, {double rate = 0.9}) async {
  try {
    if (_ttsInst == null) {
      final t = FlutterTts();
      await t.setLanguage('en-US');
      await t.setSharedInstance(true);
      await t.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback, [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker]);
      _ttsInst = t;
    }
    await _ttsInst!.setSpeechRate(rate * 0.5);
    await _ttsInst!.speak(text);
  } catch (_) {}
}

Future<void> stopSpeaking() async {
  try {
    await _ttsInst?.stop();
  } catch (_) {}
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
  final Map<String, int> _again = {};
  int i = 0, known = 0, unknown = 0;
  bool flipped = false;

  void _answer(int g) {
    final c = queue[i];
    store.grade(c, g);
    setState(() {
      if (g == Fsrs.again) {
        unknown++;
        // Quên thì ôn lại ngay cuối lượt cho tới khi nhớ (tối đa 3 lần mỗi từ).
        final n = _again[c.id] = (_again[c.id] ?? 0) + 1;
        if (n <= 3) queue.add(c);
      } else {
        known++;
      }
      i++;
      flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty || i >= queue.length) {
      final all = store.deckCards(widget.deckId);
      final avg = _avgMemory(all);
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
          if (queue.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Nhớ $known · Quên $unknown', style: ts(14, color: C.muted))),
          if (avg != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Độ nhớ trung bình của bộ: ${(avg * 100).round()}%', style: ts(14, color: C.muted)),
            ),
          const SizedBox(height: 16),
          if (all.isNotEmpty)
            BigButton('Ôn lại toàn bộ bộ thẻ', () {
              setState(() {
                queue = [...all]..shuffle();
                _again.clear();
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
              Text('Nhớ $known', style: ts(13, w: FontWeight.w600, color: C.green)),
              const SizedBox(width: 12),
              Text('Quên $unknown', style: ts(13, w: FontWeight.w600, color: C.sunday)),
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
      if (!flipped) ...[
        Text('Nhớ lại nghĩa trong đầu trước, rồi lật thẻ và tự chấm', textAlign: TextAlign.center, style: ts(12, color: C.muted)),
        const SizedBox(height: 10),
        BigButton('Lật thẻ', () => setState(() => flipped = true), color: context.accent),
      ] else ...[
        Text('Bạn nhớ từ này thế nào? Số bên dưới là lần ôn tới', textAlign: TextAlign.center, style: ts(12, color: C.muted)),
        const SizedBox(height: 10),
        Row(children: [
          _rate(c, 'Quên', Fsrs.again, C.errorBg, C.errorText),
          const SizedBox(width: 8),
          _rate(c, 'Khó', Fsrs.hard, C.streakBg, C.streakText),
          const SizedBox(width: 8),
          _rate(c, 'Nhớ', Fsrs.good, C.successBg, C.successText),
          const SizedBox(width: 8),
          _rate(c, 'Dễ', Fsrs.easy, context.accentSoft, context.accent),
        ]),
      ],
    ]);
  }

  Widget _rate(Card c, String label, int g, Color bg, Color fg) {
    final when = g == Fsrs.again ? 'ôn lại ngay' : _ivl(store.previewGrade(c, g).days);
    return Expanded(
      child: Tap(
        label: '$label, $when',
        onTap: () => _answer(g),
        child: Container(
          height: 60,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: ts(15, w: FontWeight.w700, color: fg)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(when, style: ts(12, color: fg))),
          ]),
        ),
      ),
    );
  }

  Widget _front(Card c) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (c.partOfSpeech != null) Text(c.partOfSpeech!, style: ts(14, color: C.muted, style: FontStyle.italic)),
        const SizedBox(height: 8),
        Text(c.word, textAlign: TextAlign.center, style: ts(38, w: FontWeight.w700, ls: -0.5)),
        if (c.ipa != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(c.ipa!, style: ts(17, color: C.muted))),
        const SizedBox(height: 12),
        Tap(
          label: 'Nghe ${c.word}',
          onTap: () => speakWord(c.word),
          child: Padding(padding: const EdgeInsets.all(8), child: Icon(Icons.volume_up_rounded, size: 26, color: context.accent)),
        ),
        const SizedBox(height: 8),
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
    final status = c.stability <= 0 ? 'Mới' : (later ? 'Ôn ${dm(c.dueDate)}' : 'Cần ôn');
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
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(status, style: ts(12, w: FontWeight.w600, color: later ? C.green : context.accent)),
            if (c.stability > 0) Text('nhớ ${(store.memoryOf(c) * 100).round()}%', style: ts(11, color: C.muted)),
          ]),
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

const _sources = ['Thông minh', 'Hay sai', 'Mới thêm', 'Ngẫu nhiên'];
const _counts = [10, 20, 0];

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

/// So từ gõ [typed] với đáp án [answer]: trả về từng ký tự đã gõ kèm đúng/sai,
/// chữ bị thiếu hiện bằng '_' (căn theo khoảng cách sửa ít nhất).
List<(String, bool)> alignTyped(String typed, String answer) {
  final a = typed.trim(), b = answer.trim();
  bool eq(int i, int j) => a[i].toLowerCase() == b[j].toLowerCase();
  final d = List.generate(a.length + 1, (i) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      d[i][j] = math.min(math.min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + (eq(i - 1, j - 1) ? 0 : 1));
    }
  }
  final out = <(String, bool)>[];
  var i = a.length, j = b.length;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && d[i][j] == d[i - 1][j - 1] + (eq(i - 1, j - 1) ? 0 : 1)) {
      out.add((a[i - 1], eq(i - 1, j - 1)));
      i--;
      j--;
    } else if (i > 0 && d[i][j] == d[i - 1][j] + 1) {
      out.add((a[i - 1], false));
      i--;
    } else {
      out.add(('_', false));
      j--;
    }
  }
  return out.reversed.toList();
}

String _norm(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Mẫu gợi ý: hiện [shown] chữ cái đầu, còn lại là '_' ('/' cho dấu cách).
String _pattern(String w, int shown) {
  var k = 0;
  return w.split('').map((ch) {
    if (ch == ' ') return '/';
    k++;
    return k <= shown ? ch : '_';
  }).join(' ');
}

class _Q {
  final Card c;
  final QuizMode m;
  final bool retry;
  _Q(this.c, this.m, {this.retry = false});
}

class QuizTab extends StatefulWidget {
  final String deckId;
  const QuizTab({super.key, required this.deckId});
  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  bool started = false, finished = false, mixed = false;
  QuizMode mode = QuizMode.viEn;
  int source = 0, count = 10;
  List<_Q> qs = [];
  List<String> options = [];
  final List<Card> missed = [];
  final Map<String, int> _retries = {};
  int q = 0, score = 0, streak = 0, bestStreak = 0, hints = 0, _session = 0;
  bool answered = false, lastOk = false, near = false;
  String? picked;
  String typed = '';
  final input = TextEditingController();
  final focus = FocusNode();
  final rnd = math.Random();

  _Q get cur => qs[q];
  bool get _choice => cur.m == QuizMode.enVi || cur.m == QuizMode.listenPick;
  bool get _listen => cur.m == QuizMode.listenPick || cur.m == QuizMode.listenType;

  @override
  void dispose() {
    stopSpeaking();
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  void _start({QuizMode? m, bool mix = false, List<Card>? only}) {
    final deckSize = store.deckCards(widget.deckId).length;
    if (deckSize == 0) {
      toast(context, 'Bộ thẻ chưa có từ nào');
      return;
    }
    if (!mix && (m == QuizMode.enVi || m == QuizMode.listenPick) && deckSize < 2) {
      toast(context, 'Bộ thẻ cần ít nhất 2 từ cho trò này');
      return;
    }
    final pool = only ?? store.quizPick(widget.deckId, source, count, rnd);
    if (pool.isEmpty) {
      toast(context, 'Chưa có từ nào làm sai — thử "Thông minh" nhé');
      return;
    }
    final modes = deckSize < 2 ? const [QuizMode.viEn, QuizMode.listenType] : QuizMode.values;
    setState(() {
      mixed = mix;
      if (m != null) mode = m;
      qs = [for (final c in pool) _Q(c, mix ? modes[rnd.nextInt(modes.length)] : mode)];
      missed.clear();
      _retries.clear();
      q = 0;
      score = 0;
      streak = 0;
      bestStreak = 0;
      _session++;
      started = true;
      finished = false;
    });
    _prepare();
  }

  void _quit() {
    focus.unfocus();
    setState(() {
      _session++;
      started = false;
    });
  }

  void _prepare() {
    final c = cur.c;
    input.clear();
    typed = '';
    answered = false;
    picked = null;
    near = false;
    hints = 0;
    options = [];
    if (_choice) {
      String val(Card x) => cur.m == QuizMode.enVi ? x.meaning : x.word;
      final right = val(c);
      final others = store.deckCards(widget.deckId).where((x) => x.id != c.id).toList()..shuffle(rnd);
      // Ưu tiên đáp án nhiễu cùng từ loại: phải nhớ thật, không đoán mò được.
      final ordered = [
        ...others.where((x) => x.partOfSpeech == c.partOfSpeech),
        ...others.where((x) => x.partOfSpeech != c.partOfSpeech),
      ];
      final seen = {_norm(right)};
      final list = [right];
      for (final o in ordered) {
        if (list.length >= 4) break;
        if (seen.add(_norm(val(o)))) list.add(val(o));
      }
      options = list..shuffle(rnd);
    }
    setState(() {});
    if (_listen) speakWord(c.word);
    if (!_choice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && started && !finished) focus.requestFocus();
      });
    }
  }

  void _check({bool giveUp = false}) {
    if (answered) return;
    final c = cur.c;
    var ok = false, nearMiss = false;
    if (giveUp) {
      ok = false;
    } else if (_choice) {
      ok = picked == (cur.m == QuizMode.enVi ? c.meaning : c.word);
    } else {
      typed = input.text;
      final a = _norm(input.text), b = _norm(c.word);
      ok = a == b;
      // Sai một chữ ở từ dài vẫn tính đúng nhưng chấm "Khó"; từ ngắn phải đúng hẳn.
      if (!ok && b.length >= 5 && a.isNotEmpty && levenshtein(a, b) <= 1) {
        ok = true;
        nearMiss = true;
      }
    }
    store.grade(c, !ok ? Fsrs.again : (nearMiss || hints > 0 ? Fsrs.hard : Fsrs.good));
    setState(() {
      answered = true;
      lastOk = ok;
      near = nearMiss;
      if (ok) {
        if (!cur.retry) score++;
        streak++;
        bestStreak = math.max(bestStreak, streak);
      } else {
        streak = 0;
        if (!missed.any((x) => x.id == c.id)) missed.add(c);
        // Sai thì hỏi lại ở cuối lượt (tối đa 2 lần) — nhớ lại ngay khi vừa quên giúp nhớ lâu hơn.
        final n = _retries[c.id] = (_retries[c.id] ?? 0) + 1;
        if (n <= 2) qs.add(_Q(c, cur.m, retry: true));
      }
    });
    speakWord(c.word);
    if (ok) {
      final s = _session, at = q;
      Future.delayed(Duration(milliseconds: _choice ? 900 : 1300), () {
        if (mounted && _session == s && q == at && answered && !finished) _next();
      });
    }
  }

  void _next() {
    if (q + 1 >= qs.length) {
      focus.unfocus();
      setState(() => finished = true);
      return;
    }
    q++;
    _prepare();
  }

  void _hint() {
    if (answered || hints >= cur.c.word.replaceAll(' ', '').length - 1) return;
    setState(() => hints++);
  }

  @override
  Widget build(BuildContext context) {
    if (!started) return _menu();
    if (finished) return _result();
    final c = cur.c;
    final canCheck = input.text.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Tap(
          label: 'Chọn trò khác',
          onTap: _quit,
          child: const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.arrow_back_rounded, size: 22)),
        ),
        Text('Câu ${q + 1} / ${qs.length}', style: ts(14, w: FontWeight.w600)),
        if (cur.retry) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: C.errorBg, borderRadius: BorderRadius.circular(8)),
            child: Text('Làm lại', style: ts(12, w: FontWeight.w700, color: C.errorText)),
          ),
        ],
        const Spacer(),
        Text('Đúng $score · chuỗi $streak', style: ts(13, w: FontWeight.w600, color: C.muted)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
            value: (q + (answered ? 1 : 0)) / qs.length, minHeight: 6, backgroundColor: C.segmentBg, color: context.accent),
      ),
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
          focusNode: focus,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            // Đã chấm thì giữ nguyên chữ đã gõ, bàn phím vẫn mở để Enter sang câu.
            if (answered && input.text != typed) {
              input.value = TextEditingValue(text: typed, selection: TextSelection.collapsed(offset: typed.length));
            }
            setState(() {});
          },
          onEditingComplete: () {},
          onSubmitted: (_) {
            if (answered) {
              _next();
            } else if (input.text.trim().isNotEmpty) {
              _check();
            }
          },
          decoration: inputDeco('Gõ từ tiếng Anh'),
          style: ts(18, w: FontWeight.w600),
        ),
      if (answered) ...[
        const SizedBox(height: 12),
        _feedback(c),
      ],
      const SizedBox(height: 14),
      if (answered)
        BigButton(q + 1 >= qs.length ? 'Xem kết quả' : 'Câu tiếp theo', _next, color: context.accent)
      else if (_choice)
        BigButton('Không biết', () => _check(giveUp: true), outlined: true, textColor: C.muted)
      else
        Row(children: [
          Expanded(flex: 2, child: BigButton('Gợi ý', _hint, outlined: true, textColor: C.ink)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: BigButton('Không biết', () => _check(giveUp: true), outlined: true, textColor: C.muted)),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: BigButton('Kiểm tra', canCheck ? _check : null, color: context.accent)),
        ]),
    ]);
  }

  Widget _feedback(Card c) {
    final fg = lastOk ? C.successText : C.errorText;
    final title = !lastOk
        ? 'Chưa đúng'
        : near
            ? 'Gần đúng — chú ý chính tả'
            : hints > 0
                ? 'Đúng (có dùng gợi ý)'
                : 'Chính xác!';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(color: lastOk ? C.successBg : C.errorBg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(lastOk ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 20, color: fg),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: ts(15, w: FontWeight.w700, color: fg))),
        ]),
        if (!_choice && typed.trim().isNotEmpty && (!lastOk || near)) ...[
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Bạn gõ: ', style: ts(14, color: fg)),
            for (final (ch, good) in alignTyped(typed, c.word))
              TextSpan(
                text: ch,
                style: good
                    ? ts(16, w: FontWeight.w600, color: fg)
                    : ts(16, w: FontWeight.w700, color: C.sunday).copyWith(decoration: TextDecoration.underline),
              ),
          ])),
        ],
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: c.word, style: ts(17, w: FontWeight.w700, color: fg)),
              if (c.ipa != null) TextSpan(text: '  ${c.ipa}', style: ts(14, color: fg)),
              TextSpan(text: '  —  ${c.meaning}', style: ts(15, w: FontWeight.w600, color: fg)),
            ])),
          ),
          Tap(
            label: 'Nghe ${c.word}',
            onTap: () => speakWord(c.word),
            child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.volume_up_rounded, size: 22, color: fg)),
          ),
        ]),
        if (c.example != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 6),
            child: Text(c.example!, style: ts(13, color: fg, style: FontStyle.italic, h: 1.35)),
          ),
      ]),
    );
  }

  Widget _prompt(Card c) {
    switch (cur.m) {
      case QuizMode.viEn:
        return Column(children: [
          Text('Nghĩa tiếng Việt', style: ts(12, color: C.muted)),
          const SizedBox(height: 6),
          Text(c.meaning, textAlign: TextAlign.center, style: ts(28, w: FontWeight.w700)),
          if (c.partOfSpeech != null) Text(c.partOfSpeech!, style: ts(14, color: C.muted, style: FontStyle.italic)),
          const SizedBox(height: 10),
          Text(_pattern(c.word, 1 + hints), textAlign: TextAlign.center, style: ts(18, color: C.muted, ls: 1)),
        ]);
      case QuizMode.enVi:
        return Column(children: [
          if (c.partOfSpeech != null) Text(c.partOfSpeech!, style: ts(14, color: C.muted, style: FontStyle.italic)),
          Text(c.word, textAlign: TextAlign.center, style: ts(34, w: FontWeight.w700)),
          if (c.ipa != null) Text(c.ipa!, style: ts(16, color: C.muted)),
          Tap(
            label: 'Nghe ${c.word}',
            onTap: () => speakWord(c.word),
            child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.volume_up_rounded, size: 24, color: context.accent)),
          ),
        ]);
      case QuizMode.listenPick:
      case QuizMode.listenType:
        return Column(children: [
          Tap(
            label: 'Nghe',
            onTap: () => speakWord(c.word),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: context.accentSoft, shape: BoxShape.circle),
              child: Icon(Icons.volume_up_rounded, size: 34, color: context.accent),
            ),
          ),
          const SizedBox(height: 10),
          Tap(
            onTap: () => speakWord(c.word, rate: 0.55),
            child: Padding(padding: const EdgeInsets.all(8), child: Text('Nghe chậm', style: ts(14, w: FontWeight.w600, color: context.accent))),
          ),
          if (cur.m == QuizMode.listenType) ...[
            Text(_pattern(c.word, hints), textAlign: TextAlign.center, style: ts(18, color: C.muted, ls: 1)),
            Text('${c.word.replaceAll(' ', '').length} chữ cái', style: ts(13, color: C.muted)),
          ],
        ]);
    }
  }

  Widget _option(String o, Card c) {
    final correct = cur.m == QuizMode.enVi ? c.meaning : c.word;
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
        onTap: answered
            ? null
            : () {
                setState(() => picked = o);
                _check();
              },
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

  Widget _result() {
    final total = qs.where((x) => !x.retry).length;
    final pct = total == 0 ? 0 : (score * 100 / total).round();
    final msg = pct == 100
        ? 'Xuất sắc, thuộc hết rồi!'
        : pct >= 80
            ? 'Rất tốt!'
            : pct >= 50
                ? 'Khá ổn, ôn thêm chút nữa'
                : 'Cần ôn lại nhiều hơn';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Box(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text('$score / $total', style: ts(44, w: FontWeight.w700)),
          Text('đúng ngay lần đầu', style: ts(14, color: C.muted)),
          const SizedBox(height: 6),
          Text(msg, textAlign: TextAlign.center, style: ts(15, w: FontWeight.w600)),
          if (bestStreak >= 3)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('Chuỗi đúng dài nhất: $bestStreak', style: ts(13, color: C.muted))),
        ]),
      ),
      if (missed.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('TỪ CẦN ÔN THÊM · ${missed.length}', style: ts(12, w: FontWeight.w700, color: C.muted)),
        const SizedBox(height: 8),
        for (final c in missed)
          Padding(
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
                IconBtn(Icons.volume_up_rounded, 'Nghe ${c.word}', () => speakWord(c.word), bordered: false),
              ]),
            ),
          ),
        Text('Những từ này đã được đưa vào lượt Học hôm nay.', style: ts(12, color: C.muted)),
        const SizedBox(height: 12),
        BigButton('Ôn lại ${missed.length} từ sai', () => _start(m: mode, mix: mixed, only: [...missed]), color: context.accent),
        const SizedBox(height: 10),
        BigButton('Lượt mới', () => _start(m: mode, mix: mixed), outlined: true, textColor: C.ink),
      ] else ...[
        const SizedBox(height: 16),
        BigButton('Lượt mới', () => _start(m: mode, mix: mixed), color: context.accent),
      ],
      const SizedBox(height: 10),
      BigButton('Chọn trò khác', _quit, outlined: true, textColor: C.ink),
    ]);
  }

  Widget _stat(String v, String label) => Expanded(
        child: Column(children: [
          Text(v, style: ts(22, w: FontWeight.w700)),
          Text(label, style: ts(12, color: C.muted)),
        ]),
      );

  Widget _menu() {
    final all = store.deckCards(widget.deckId);
    final due = all.where((c) => !c.dueDate.isAfter(store.today)).length;
    final weak = all.where(store.isWeak).length;
    final avg = _avgMemory(all);
    final modes = QuizMode.values;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Box(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(children: [
          _stat('$due', 'đến hạn ôn'),
          _stat('$weak', 'từ hay sai'),
          _stat(avg == null ? '—' : '${(avg * 100).round()}%', 'độ nhớ TB'),
        ]),
      ),
      const SizedBox(height: 14),
      Text('ƯU TIÊN TỪ', style: ts(12, w: FontWeight.w700, color: C.muted)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (var i = 0; i < _sources.length; i++) Pill(_sources[i], selected: source == i, onTap: () => setState(() => source = i)),
      ]),
      const SizedBox(height: 12),
      Text('SỐ CÂU', style: ts(12, w: FontWeight.w700, color: C.muted)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final n in _counts) Pill(n == 0 ? 'Tất cả' : '$n câu', selected: count == n, onTap: () => setState(() => count = n)),
      ]),
      const SizedBox(height: 16),
      for (var r = 0; r < 2; r++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            for (var c = 0; c < 2; c++) ...[
              if (c > 0) const SizedBox(width: 12),
              Expanded(
                child: Tap(
                  onTap: () => _start(m: modes[r * 2 + c]),
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
      Tap(
        onTap: () => _start(mix: true),
        child: Box(
          padding: const EdgeInsets.all(16),
          radius: 20,
          child: Row(children: [
            Icon(Icons.shuffle_rounded, size: 26, color: context.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trộn tất cả', style: ts(15, w: FontWeight.w700)),
                Text('Đổi kiểu câu hỏi liên tục — nhớ sâu hơn', style: ts(12, color: C.muted)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: C.muted),
          ]),
        ),
      ),
    ]);
  }
}
