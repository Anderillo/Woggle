import 'package:boggle_solver/pages/main_page.dart';
import 'package:boggle_solver/utils/constants.dart';
import 'package:flutter/material.dart';

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
      home: Builder(builder: (builderContext) => MainPage()),
    );
  }
}
