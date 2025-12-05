import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:food_recipes_app/helper/theme_provider.dart';
import 'package:food_recipes_app/screens/Splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("✅ Firebase Connected Successfully!");

  // ✅ Wrap the app with Provider for Theme Management
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
    // ✅ Get ThemeProvider instance
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ Switch between light & dark themes
      theme: themeProvider.currentTheme,

      // ✅ App Entry Point
      home: const SplashScreen(),
    );
  }
}
