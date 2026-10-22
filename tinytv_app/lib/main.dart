import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'controllers/tv_controller.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit audio/video engine
  MediaKit.ensureInitialized();

  // Initialize SharedPreferences storage
  final storageService = await StorageService.init();

  runApp(TinyTvApp(storageService: storageService));
}

class TinyTvApp extends StatelessWidget {
  final StorageService storageService;

  const TinyTvApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TvController(storage: storageService),
      child: MaterialApp(
        title: 'TinyTV - Live TV Player',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF050507),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFF43F5E),
            secondary: Color(0xFFFB7185),
            surface: Color(0xFF0F1016),
          ),
          fontFamily: 'Segoe UI',
          useMaterial3: true,
          tooltipTheme: TooltipThemeData(
            decoration: BoxDecoration(
              color: const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF181926),
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF2E3146)),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
