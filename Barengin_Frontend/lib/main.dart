import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/app_shell.dart';
import 'screens/auth_screen.dart';
import 'state/session_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/common_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final session = SessionController();
  await session.restore();
  runApp(
    ChangeNotifierProvider.value(value: session, child: const BarenginApp()),
  );
}

class BarenginApp extends StatelessWidget {
  const BarenginApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Barengin',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Consumer<SessionController>(
      builder: (context, session, _) {
        if (session.isBooting) return const _BootScreen();
        if (session.user == null) return const AuthScreen();
        return const MainShell();
      },
    ),
  );
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(),
          SizedBox(height: 22),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    ),
  );
}
