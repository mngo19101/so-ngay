import 'package:flutter/material.dart';

class C {
  /// Do SoNgayApp đặt; đổi giá trị này phải dựng lại toàn bộ cây widget.
  static bool dark = false;

  static Color _c(int light, int night) => Color(dark ? night : light);

  static Color get bg => _c(0xFFF7F6F3, 0xFF141418);
  static Color get surface => _c(0xFFFFFFFF, 0xFF1F1F25);
  static Color get ink => _c(0xFF1A1A1F, 0xFFF1F0EC);
  static Color get muted => _c(0xFF5F5E66, 0xFFA9A8B0);
  static Color get border => _c(0xFFE7E5E0, 0xFF2F2F37);
  static Color get borderInput => _c(0xFFDAD7D0, 0xFF43434D);
  static Color get segmentBg => _c(0xFFECEAE5, 0xFF2A2A31);
  static Color get segmentSel => _c(0xFFFFFFFF, 0xFF44444F);
  static Color get switchOff => _c(0xFFCFCCC5, 0xFF55555F);

  /// Nền của nút và ô đang chọn, luôn đi với chữ trắng (khác [ink] là màu chữ).
  static Color get fill => _c(0xFF1A1A1F, 0xFF3D3D47);
  static Color get blue => _c(0xFF2F5BD3, 0xFF4F76E0);
  static Color get green => _c(0xFF1F8A5B, 0xFF2BA471);
  static Color get amber => _c(0xFFC77700, 0xFFD98A1A);
  static Color get sunday => _c(0xFFB3361F, 0xFFE8674F);
  static Color get successBg => _c(0xFFE3F3EA, 0xFF14342A);
  static Color get successText => _c(0xFF145C3C, 0xFF7FDDB0);
  static Color get errorBg => _c(0xFFFBE7E2, 0xFF3D1E18);
  static Color get errorText => _c(0xFF8E2A17, 0xFFF4A796);
  static Color get streakBg => _c(0xFFFFF1D6, 0xFF3A2C12);
  static Color get streakText => _c(0xFF8A5300, 0xFFF0C274);
  static Color get barSelected => _c(0xFF2F5BD3, 0xFF7B9BF0);
  static Color get bar => _c(0xFF6F8DE0, 0xFF3F5FB8);
  static const accents = [Color(0xFFD9472B), Color(0xFF2F5BD3), Color(0xFF1F8A5B), Color(0xFF7A4FD1)];

  static (Color, Color) typeColors(String type) {
    switch (type) {
      case 'birthday':
        return (_c(0xFFFBE7E2, 0xFF3D1E18), _c(0xFFB3361F, 0xFFF4A796));
      case 'anniversary':
        return (_c(0xFFEFE7FB, 0xFF2E2545), _c(0xFF5F3AAE, 0xFFC5AEF5));
      case 'holiday':
        return (_c(0xFFE4EBFB, 0xFF1E2A4A), _c(0xFF244BB0, 0xFFA3BBF7));
      default:
        return (_c(0xFFECEAE5, 0xFF2A2A31), _c(0xFF3A3A40, 0xFFC9C8CF));
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
  Color get accentSoft => Color.alphaBlend(accent.withValues(alpha: C.dark ? 0.22 : 0.14), C.surface);
}

ThemeData buildTheme(Color accent) {
  // Màu chủ đạo vừa làm chữ vừa làm nền chữ trắng; nền tối cần sáng hơn một chút.
  final primary = C.dark ? Color.alphaBlend(Colors.white.withValues(alpha: 0.18), accent) : accent;
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: C.dark ? Brightness.dark : Brightness.light,
      primary: primary,
      surface: C.surface,
    ),
    splashFactory: NoSplash.splashFactory,
    textTheme: (C.dark ? ThemeData.dark() : ThemeData.light())
        .textTheme
        .apply(fontFamily: 'BeVietnamPro', bodyColor: C.ink, displayColor: C.ink),
  );
  return base.copyWith(
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.fill,
      contentTextStyle: const TextStyle(fontFamily: 'BeVietnamPro', color: Colors.white),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color? color, double? h, double? ls, FontStyle? style}) =>
    TextStyle(fontSize: size, fontWeight: w, color: color ?? C.ink, height: h, letterSpacing: ls, fontStyle: style);

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
  final Color? color;
  final double radius;
  final bool bordered;
  const Box({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.radius = 18,
    this.bordered = true,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? C.surface,
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
    final sel = selColor ?? C.fill;
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
                    color: i == index ? C.segmentSel : Colors.transparent,
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
    final bg = outlined ? C.surface : (color ?? C.fill);
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.borderInput)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.borderInput)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.ink, width: 1.5)),
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
              color: value ? context.accent : C.switchOff,
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
