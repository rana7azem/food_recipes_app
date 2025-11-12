import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_recipes_app/helper/pref.dart';
import 'package:food_recipes_app/screens/splash_screen.dart';
import 'package:food_recipes_app/theme/app_theme.dart';
import 'package:food_recipes_app/widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Pref.init();
  
  // Set system UI mode and orientation
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  
  runApp(const FoodRecipesApp());
}

// Global variable for theme state
bool isDarkMode = false;

class FoodRecipesApp extends StatefulWidget {
  const FoodRecipesApp({Key? key}) : super(key: key);

  @override
  State<FoodRecipesApp> createState() => _FoodRecipesAppState();
}

class _FoodRecipesAppState extends State<FoodRecipesApp> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    // You can load theme preference from SharedPreferences here if needed
    // bool savedTheme = await Pref.getBool('isDarkMode') ?? false;
    // setState(() {
    //   _isDark = savedTheme;
    //   isDarkMode = savedTheme;
    // });
  }

  void toggleTheme(bool value) {
    setState(() {
      _isDark = value;
      isDarkMode = value;
    });
    // Save theme preference
    // Pref.setBool('isDarkMode', value);
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
