import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_bar.dart';

void main() {
  runApp(const FoodRecipesApp());
}

class FoodRecipesApp extends StatefulWidget {
  const FoodRecipesApp({super.key});

  @override
  State<FoodRecipesApp> createState() => _FoodRecipesAppState();
}

class _FoodRecipesAppState extends State<FoodRecipesApp> {
  bool _isDark = false;

  void toggleTheme(bool value) {
    setState(() {
      _isDark = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Recipes App',
      debugShowCheckedModeBanner: false,
      theme: _isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const BottomNavBar(),
    );
  }
}
