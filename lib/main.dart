import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_recipes_app/helper/pref.dart';
import 'package:food_recipes_app/screens/splash_screen.dart';
import 'package:food_recipes_app/theme/app_theme.dart';
import 'package:food_recipes_app/widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Pref.init();
  } catch (e) {
    debugPrint('Error initializing SharedPreferences: $e');
  }
  
  // Set system UI mode and orientation
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  } catch (e) {
    debugPrint('Error setting system UI: $e');
  }
  
  runApp(const FoodRecipesApp());
}

// Global variable for theme state
bool isDarkMode = false;

class FoodRecipesApp extends StatefulWidget {
  const FoodRecipesApp({super.key});

  @override
  State<FoodRecipesApp> createState() => _FoodRecipesAppState();
}

class _FoodRecipesAppState extends State<FoodRecipesApp> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    // _loadTheme();
  }

  //Future<void> _loadTheme() async {
 // }

  void toggleTheme(bool value) {
    setState(() {
      _isDark = value;
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Recipes App',
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
