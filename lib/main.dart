import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'providers/project_state.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectState()..init()),
      ],
      child: MaterialApp(
        title: 'SignFrame',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00D9FF), // Vibrant cyan
            brightness: Brightness.dark,
            surface: const Color(0xFF0D1117), // GitHub-like dark
            primary: const Color(0xFF00D9FF),
            secondary: const Color(0xFF7C3AED), // Purple accent
            error: const Color(0xFFEF4444),
          ),
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF161B22),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF161B22),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(foregroundColor: Colors.white70),
          ),
          sliderTheme: SliderThemeData(
            activeTrackColor: const Color(0xFF00D9FF),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: const Color(0xFF00D9FF),
            overlayColor: const Color(0xFF00D9FF).withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          dividerTheme: DividerThemeData(
            color: Colors.white.withValues(alpha: 0.1),
            thickness: 1,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF21262D),
            contentTextStyle: const TextStyle(color: Colors.white),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
