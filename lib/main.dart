import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'notifications.dart';
import 'screens/shell.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await store.load();
  runApp(const SoNgayApp());
  // Xin quyền ngay lần mở đầu, nếu không các lịch nhắc sẽ không bao giờ hiện.
  if (store.settings.pushEnabled) await NotificationService.instance.requestPermission();
  store.rescheduleNotifications();
}

class SoNgayApp extends StatefulWidget {
  const SoNgayApp({super.key});
  @override
  State<SoNgayApp> createState() => _SoNgayAppState();
}

class _SoNgayAppState extends State<SoNgayApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    store.addListener(_syncTheme);
    C.dark = _wantDark();
    _applyStatusBar();
  }

  @override
  void dispose() {
    store.removeListener(_syncTheme);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _wantDark() => switch (store.settings.themeMode) {
        'dark' => true,
        'light' => false,
        _ => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
      };

  void _applyStatusBar() =>
      SystemChrome.setSystemUIOverlayStyle(C.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark);

  /// Màu đọc từ C.xxx lúc build và nhiều widget là const, nên phải dựng lại cả
  /// cây. Giữ nguyên trạng thái (form đang nhập, bảng đang mở), vì iOS có thể
  /// đổi sáng/tối thoáng qua mỗi khi app xuống nền.
  void _syncTheme() {
    final want = _wantDark();
    if (want == C.dark) return;
    C.dark = want;
    _applyStatusBar();
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  void didChangePlatformBrightness() => _syncTheme();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.resumed) store.flushStudyPlan();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        title: 'Sổ Ngày',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Color(store.settings.accent)),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: const Shell(),
      ),
    );
  }
}
