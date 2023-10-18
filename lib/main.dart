import 'package:flutter/material.dart';
import 'package:woggle/pages/main_page.dart';
import 'package:woggle/utils/constants.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Constants.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Constants.primaryColor,
          brightness: Brightness.dark,
          primary: Constants.primaryColor,
          secondary: Constants.secondaryColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        sliderTheme: const SliderThemeData(
          valueIndicatorColor: Constants.primaryColor,
          valueIndicatorTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: Builder(builder: (builderContext) => const MainPage()),
    );
  }
}
