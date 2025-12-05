import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:food_recipes_app/helper/theme_provider.dart';
import 'package:food_recipes_app/screens/Splash_screen.dart';
import 'package:food_recipes_app/screens/login_screen.dart';
import 'package:food_recipes_app/screens/signup_screen.dart';
import 'package:food_recipes_app/widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase Connected Successfully!");
  } catch (e) {
    print("⚠️ Firebase initialization warning: $e");
    // Continue anyway - Firebase might initialize on first use
  }
  
  runApp(const FoodRecipesApp());
}

class FoodRecipesApp extends StatelessWidget {
  const FoodRecipesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const BottomNavBar(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}
