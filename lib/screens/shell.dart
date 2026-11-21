import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'add_special.dart';
import 'calendar.dart';
import 'flashcards.dart';
import 'notes.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'special_days.dart';
import 'study_chart.dart';
import 'study_input.dart';
import 'today.dart';

enum AppPage { today, calendar, special, add, studyInput, studyChart, notes, notifs, cards, settings }

class Nav extends ChangeNotifier {
  AppPage page = AppPage.today;
  SpecialDay? editing;
  void go(AppPage p, {SpecialDay? edit}) {
    store.flushStudyPlan();
    page = p;
    editing = edit;
    notifyListeners();
  }
}

final nav = Nav();

/// Nội dung chiếm toàn màn hình; các tab nằm trong ngăn kéo, chỉ hiện khi bấm ☰.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _scaffold = GlobalKey<ScaffoldState>();
  bool studyOpen = false; // nhóm Giờ học trong ngăn kéo

  @override
  void initState() {
    super.initState();
    openMenu = () => _scaffold.currentState?.openDrawer();
  }

  @override
  void dispose() {
    openMenu = null;
    super.dispose();
  }

  Widget _page() {
    switch (nav.page) {
      case AppPage.today:
        return const TodayScreen();
      case AppPage.calendar:
        return const CalendarScreen();
      case AppPage.special:
        return const SpecialDaysScreen();
      case AppPage.add:
        return AddSpecialScreen(key: ValueKey(nav.editing?.id ?? 'new'), editing: nav.editing);
      case AppPage.studyInput:
        return const StudyInputScreen();
      case AppPage.studyChart:
        return const StudyChartScreen();
      case AppPage.notes:
        return const NotesScreen();
      case AppPage.notifs:
        return const NotificationsScreen();
      case AppPage.cards:
        return const FlashcardsScreen();
      case AppPage.settings:
        return const SettingsScreen();
    }
  }

  void _go(AppPage p) {
    _scaffold.currentState?.closeDrawer();
    nav.go(p);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: nav,
      builder: (context, _) => Scaffold(
        key: _scaffold,
        drawer: _drawer(),
        drawerEdgeDragWidth: 24,
        drawerScrimColor: Colors.black.withValues(alpha: 0.45),
        body: _page(),
      ),
    );
  }

  Widget _drawer() {
    final inStudy = nav.page == AppPage.studyInput || nav.page == AppPage.studyChart;
    return Drawer(
      width: 272,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          children: [
            Row(children: [
              Expanded(child: Text('Sổ Ngày', style: ts(20, w: FontWeight.w700))),
              IconBtn(Icons.close_rounded, 'Đóng menu', () => _scaffold.currentState?.closeDrawer(), bordered: false),
            ]),
            const SizedBox(height: 8),
            Tap(
              label: 'Thêm ngày mới',
              onTap: () => _go(AppPage.add),
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: context.accent, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Thêm ngày mới', style: ts(15, w: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: C.border)),
            _item(Icons.today_rounded, 'Hôm nay', AppPage.today),
            _item(Icons.calendar_month_rounded, 'Lịch', AppPage.calendar),
            _item(Icons.card_giftcard_rounded, 'Ngày đặc biệt', AppPage.special),
            Tap(
              label: 'Giờ học',
              onTap: () => setState(() => studyOpen = !studyOpen),
              child: _row(Icons.schedule_rounded, 'Giờ học', inStudy,
                  trailing: Icon(studyOpen || inStudy ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 20, color: C.muted)),
            ),
            if (studyOpen || inStudy)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(children: [
                  _item(Icons.edit_note_rounded, 'Nhập giờ học', AppPage.studyInput),
                  _item(Icons.bar_chart_rounded, 'Biểu đồ', AppPage.studyChart),
                ]),
              ),
            _item(Icons.style_rounded, 'Flashcard', AppPage.cards),
            _item(Icons.sticky_note_2_outlined, 'Ghi chú', AppPage.notes),
            _item(Icons.notifications_none_rounded, 'Thông báo', AppPage.notifs),
            _item(Icons.settings_outlined, 'Cài đặt', AppPage.settings),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, AppPage p) =>
      Tap(label: label, onTap: () => _go(p), child: _row(icon, label, nav.page == p));

  Widget _row(IconData icon, String label, bool sel, {Widget? trailing}) {
    final fg = sel ? context.accent : C.ink;
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: sel ? context.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(icon, size: 22, color: fg),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: ts(15, w: sel ? FontWeight.w700 : FontWeight.w500, color: fg)),
        ),
        if (trailing != null) trailing,
      ]),
    );
  }
}

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 11) return 'Chào buổi sáng';
  if (h < 14) return 'Chào buổi trưa';
  if (h < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

String get displayName => store.settings.displayName;
