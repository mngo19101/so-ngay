import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'notifications.dart';
import 'screens/shell.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  await NotificationService.instance.init();
  await store.load();
  runApp(const SoNgayApp());
  // Xin quyền ngay lần mở đầu, nếu không các lịch nhắc sẽ không bao giờ hiện.
  if (store.settings.pushEnabled) await NotificationService.instance.requestPermission();
  store.rescheduleNotifications();
}

class SoNgayApp extends StatelessWidget {
  const SoNgayApp({super.key});
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
