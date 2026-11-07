import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'add_special.dart';
import 'calendar.dart';
import 'flashcards.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'special_days.dart';
import 'study_chart.dart';
import 'study_input.dart';
import 'today.dart';

enum AppPage { today, calendar, special, add, studyInput, studyChart, notifs, cards, settings }

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

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  bool expanded = false;
  bool studyOpen = false; // nhóm Giờ học (khi mở rộng)
  bool flyout = false; // bảng nhỏ khi thu gọn

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
      case AppPage.notifs:
        return const NotificationsScreen();
      case AppPage.cards:
        return const FlashcardsScreen();
      case AppPage.settings:
        return const SettingsScreen();
    }
  }

  void _go(AppPage p) {
    nav.go(p);
    setState(() {
      expanded = false;
      flyout = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: nav,
      builder: (context, _) {
        final inStudy = nav.page == AppPage.studyInput || nav.page == AppPage.studyChart;
        return Scaffold(
          body: Stack(children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 64),
                child: GestureDetector(
                  onTap: flyout ? () => setState(() => flyout = false) : null,
                  behavior: HitTestBehavior.translucent,
                  child: _page(),
                ),
              ),
            ),
            if (expanded)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => expanded = false),
                  child: Semantics(
                    label: 'Đóng menu',
                    child: Container(color: const Color(0x521A1A1F)),
                  ),
                ),
              ),
            if (flyout && !expanded)
              Positioned(
                left: 68,
                top: MediaQuery.of(context).padding.top + 8 + 44 + 8 + 52 + 17 + 3 * 52.0 + 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(children: [
                    _flyBtn(Icons.edit_note_rounded, 'Nhập giờ học', AppPage.studyInput),
                    _flyBtn(Icons.bar_chart_rounded, 'Biểu đồ', AppPage.studyChart),
                  ]),
                ),
              ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: expanded ? 224 : 64,
                decoration: BoxDecoration(
                  color: C.surface,
                  border: Border(right: BorderSide(color: C.border)),
                  boxShadow: expanded
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24)]
                      : null,
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                    physics: const ClampingScrollPhysics(),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        IconBtn(expanded ? Icons.close_rounded : Icons.menu_rounded,
                            expanded ? 'Thu gọn thanh bên' : 'Mở rộng thanh bên',
                            () => setState(() {
                                  expanded = !expanded;
                                  flyout = false;
                                }),
                            bordered: false),
                        if (expanded) ...[
                          const SizedBox(width: 8),
                          Expanded(child: Text('Sổ Ngày', overflow: TextOverflow.clip, softWrap: false, style: ts(18, w: FontWeight.w700))),
                        ],
                      ]),
                      const SizedBox(height: 8),
                      _item(Icons.add_rounded, 'Thêm ngày mới', AppPage.add, dark: true),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: C.border),
                      ),
                      _item(Icons.today_rounded, 'Hôm nay', AppPage.today),
                      _item(Icons.calendar_month_rounded, 'Lịch', AppPage.calendar),
                      _item(Icons.card_giftcard_rounded, 'Ngày đặc biệt', AppPage.special),
                      _studyItem(inStudy),
                      if (expanded && (studyOpen || inStudy)) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(children: [
                            _item(Icons.edit_note_rounded, 'Nhập giờ học', AppPage.studyInput),
                            _item(Icons.bar_chart_rounded, 'Biểu đồ', AppPage.studyChart),
                          ]),
                        ),
                      ],
                      _item(Icons.style_rounded, 'Flashcard', AppPage.cards),
                      _item(Icons.notifications_none_rounded, 'Thông báo', AppPage.notifs),
                      _item(Icons.settings_outlined, 'Cài đặt', AppPage.settings),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _flyBtn(IconData icon, String label, AppPage p) {
    final sel = nav.page == p;
    return Tap(
      label: label,
      onTap: () => _go(p),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(color: sel ? context.accentSoft : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Tooltip(message: label, child: Icon(icon, size: 22, color: sel ? context.accent : C.ink)),
      ),
    );
  }

  Widget _studyItem(bool inStudy) {
    final open = studyOpen || inStudy;
    return Tap(
      label: 'Giờ học',
      onTap: () => setState(() {
        if (expanded) {
          studyOpen = !studyOpen;
        } else {
          flyout = !flyout;
        }
      }),
      child: _row(Icons.schedule_rounded, 'Giờ học', inStudy,
          trailing: expanded
              ? Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20, color: C.muted)
              : null),
    );
  }

  Widget _item(IconData icon, String label, AppPage p, {bool dark = false}) {
    final sel = nav.page == p && !dark;
    return Tap(label: label, onTap: () => _go(p), child: _row(icon, label, sel, dark: dark));
  }

  Widget _row(IconData icon, String label, bool sel, {bool dark = false, Widget? trailing}) {
    final fg = dark ? Colors.white : (sel ? context.accent : C.ink);
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
      decoration: BoxDecoration(
        color: dark ? C.fill : (sel ? context.accentSoft : Colors.transparent),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: fg),
          if (expanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: ts(15, w: sel || dark ? FontWeight.w700 : FontWeight.w500, color: fg)),
            ),
            if (trailing != null) trailing,
          ],
        ],
      ),
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
