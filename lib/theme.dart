import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFFF7F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1A1F);
  static const muted = Color(0xFF5F5E66);
  static const border = Color(0xFFE7E5E0);
  static const borderInput = Color(0xFFDAD7D0);
  static const segmentBg = Color(0xFFECEAE5);
  static const accentDefault = Color(0xFFD9472B);
  static const accentSoftDefault = Color(0xFFFBE7E2);
  static const blue = Color(0xFF2F5BD3);
  static const green = Color(0xFF1F8A5B);
  static const amber = Color(0xFFC77700);
  static const sunday = Color(0xFFB3361F);
  static const successBg = Color(0xFFE3F3EA);
  static const successText = Color(0xFF145C3C);
  static const errorBg = Color(0xFFFBE7E2);
  static const errorText = Color(0xFF8E2A17);
  static const streakBg = Color(0xFFFFF1D6);
  static const streakText = Color(0xFF8A5300);
  static const accents = [Color(0xFFD9472B), Color(0xFF2F5BD3), Color(0xFF1F8A5B), Color(0xFF7A4FD1)];

  static (Color, Color) typeColors(String type) {
    switch (type) {
      case 'birthday':
        return (const Color(0xFFFBE7E2), const Color(0xFFB3361F));
      case 'anniversary':
        return (const Color(0xFFEFE7FB), const Color(0xFF5F3AAE));
      case 'holiday':
        return (const Color(0xFFE4EBFB), const Color(0xFF244BB0));
      default:
        return (const Color(0xFFECEAE5), const Color(0xFF3A3A40));
    }
  }

  static Color categoryColor(String c) {
    switch (c) {
      case 'study':
        return blue;
      case 'personal':
        return green;
      case 'habit':
        return amber;
      default:
        return const Color(0xFF8A8892);
    }
  }
}

extension AccentX on BuildContext {
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get accentSoft => Color.alphaBlend(accent.withValues(alpha: 0.14), Colors.white);
}

ThemeData buildTheme(Color accent) {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: accent, primary: accent, surface: C.surface),
    splashFactory: NoSplash.splashFactory,
    textTheme: ThemeData.light().textTheme.apply(fontFamily: 'BeVietnamPro', bodyColor: C.ink, displayColor: C.ink),
  );
  return base.copyWith(
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.ink,
      contentTextStyle: const TextStyle(fontFamily: 'BeVietnamPro', color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color color = C.ink, double? h, double? ls, FontStyle? style}) =>
    TextStyle(fontSize: size, fontWeight: w, color: color, height: h, letterSpacing: ls, fontStyle: style);

// ---------- widget dùng chung ----------

class Tap extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final String? label;
  const Tap({super.key, required this.onTap, required this.child, this.onLongPress, this.label});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onTap != null,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, onLongPress: onLongPress, child: child),
    );
  }
}

class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final bool bordered;
  const Box({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = C.surface,
    this.radius = 18,
    this.bordered = true,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: bordered ? Border.all(color: C.border) : null,
        ),
        child: child,
      );
}

class IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool bordered;
  final double size;
  const IconBtn(this.icon, this.label, this.onTap, {super.key, this.bordered = true, this.size = 44});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        label: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bordered ? C.surface : Colors.transparent,
            shape: BoxShape.circle,
            border: bordered ? Border.all(color: C.border) : null,
          ),
          child: Icon(icon, size: 22, color: onTap == null ? C.borderInput : C.ink),
        ),
      );
}

class Pill extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dashed;
  final Color? selColor;
  final bool compact;
  const Pill(this.text,
      {super.key, this.selected = false, this.onTap, this.onLongPress, this.dashed = false, this.selColor, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final sel = selColor ?? C.ink;
    return Tap(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? sel : C.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? sel : C.borderInput),
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(text,
              style: ts(14, w: FontWeight.w600, color: selected ? Colors.white : (dashed ? C.muted : C.ink))),
        ),
      ),
    );
  }
}

class Segmented extends StatelessWidget {
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  const Segmented(this.items, this.index, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: C.segmentBg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Tap(
                onTap: () => onChanged(i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? C.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: i == index
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
                        : null,
                  ),
                  child: Text(items[i],
                      style: ts(14, w: FontWeight.w600, color: i == index ? C.ink : C.muted)),
                ),
              ),
            ),
        ]),
      );
}

class BigButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color? color;
  final Color textColor;
  final bool outlined;
  const BigButton(this.text, this.onTap, {super.key, this.color, this.textColor = Colors.white, this.outlined = false});
  @override
  Widget build(BuildContext context) {
    final bg = outlined ? C.surface : (color ?? C.ink);
    return Tap(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: outlined ? Border.all(color: C.borderInput) : null,
          ),
          child: Text(text, style: ts(16, w: FontWeight.w700, color: textColor)),
        ),
      ),
    );
  }
}

class Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const Field(this.label, this.controller,
      {super.key, this.hint, this.keyboard, this.maxLines = 1, this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ts(13, w: FontWeight.w600, color: C.muted)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            minLines: 1,
            onChanged: onChanged,
            style: ts(16),
            decoration: inputDeco(hint),
          ),
        ],
      );
}

InputDecoration inputDeco(String? hint) => InputDecoration(
      hintText: hint,
      hintStyle: ts(15, color: const Color(0xFF8A8892)),
      filled: true,
      fillColor: C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.borderInput)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.borderInput)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.ink, width: 1.5)),
    );

class Switch2 extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  const Switch2(this.value, this.onChanged, this.label, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        toggled: value,
        child: Tap(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 32,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? context.accent : const Color(0xFFCFCCC5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      );
}

class StreakBadge extends StatelessWidget {
  final int days;
  const StreakBadge(this.days, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: C.streakBg, borderRadius: BorderRadius.circular(17)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFE8730C)),
          const SizedBox(width: 4),
          Text('$days ngày liên tiếp',
              softWrap: false, style: ts(13, w: FontWeight.w700, color: C.streakText)),
        ]),
      );
}

/// Khung màn hình: chừa lề trái cho thanh bên (đã do Shell lo), cuộn dọc.
class ScreenBody extends StatelessWidget {
  final List<Widget> children;
  final double top;
  const ScreenBody({super.key, required this.children, this.top = 20});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, top, 16, 40),
          children: children,
        ),
      );
}

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const ScreenHeader(this.title, {super.key, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: ts(26, w: FontWeight.w700, ls: -0.5)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: ts(13, color: C.muted)),
              ],
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: msg.length > 40 ? 5 : 2)));
}

Future<bool> confirm(BuildContext context, String title, String body, {String ok = 'Xoá'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title, style: ts(18, w: FontWeight.w700)),
      content: Text(body, style: ts(15, color: C.muted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Huỷ', style: ts(15, w: FontWeight.w600, color: C.muted))),
        TextButton(onPressed: () => Navigator.pop(c, true), child: Text(ok, style: ts(15, w: FontWeight.w700, color: C.sunday))),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> promptText(BuildContext context, String title, {String initial = '', String hint = ''}) {
  final ctl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title, style: ts(18, w: FontWeight.w700)),
      content: TextField(controller: ctl, autofocus: true, decoration: inputDeco(hint), style: ts(16)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text('Huỷ', style: ts(15, w: FontWeight.w600, color: C.muted))),
        TextButton(onPressed: () => Navigator.pop(c, ctl.text), child: Text('Lưu', style: ts(15, w: FontWeight.w700))),
      ],
    ),
  );
}
