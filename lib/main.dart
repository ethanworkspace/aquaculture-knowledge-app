import 'package:material_ui/material_ui.dart';

import 'domain.dart';
import 'screens.dart';

void main() => runApp(AquacultureApp());

class AquacultureApp extends StatefulWidget {
  AquacultureApp({super.key, AppStore? store}) : store = store ?? AppStore();
  final AppStore store;
  @override
  State<AquacultureApp> createState() => _AquacultureAppState();
}

class _AquacultureAppState extends State<AquacultureApp> {
  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '養殖漁業知識平台',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff518bb1),
        surface: const Color(0xffedf7ff),
      ),
      scaffoldBackgroundColor: const Color(0xffdfeffb),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xffe4f2fc),
        foregroundColor: Color(0xff24445a),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xffe1f1fc),
        indicatorColor: Color(0xffc4e1f5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xfff6fbff),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xff518bb1),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    ),
    home: ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => widget.store.signedIn
          ? MainShell(store: widget.store)
          : LoginScreen(store: widget.store),
    ),
  );
}
