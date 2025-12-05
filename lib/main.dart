import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_recipes_app/helper/pref.dart';
import 'package:food_recipes_app/helper/theme_provider.dart';
import 'package:food_recipes_app/theme/app_theme.dart';
import 'package:food_recipes_app/screens/Splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Pref.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const FoodRecipesApp(),
    ),
  );
}

class FoodRecipesApp extends StatelessWidget {
  const FoodRecipesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Recipes App',
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
