import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'screens/home_screen.dart';

void main() async {                                    // ← add async
  WidgetsFlutterBinding.ensureInitialized();           // ← add this
  runApp(const AIDetectorApp());
}

class AIDetectorApp extends StatelessWidget {
  const AIDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PixelTruth — AI Image Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          secondary: kAccentBlue,
          surface: kSurface,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}