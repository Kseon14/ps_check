import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeInt with ChangeNotifier{
  static bool isDark = true;

  static ThemeInt themeInternal = ThemeInt();

  static ThemeInt instance(){
    return themeInternal;
  }

  ThemeMode currentTheme() {
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void switchTheme () {
    isDark = !isDark;
    notifyListeners();
  }
}