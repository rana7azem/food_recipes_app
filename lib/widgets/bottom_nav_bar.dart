import 'package:flutter/material.dart';
import '../screens/Recipes.dart';
import '../screens/CheckList.dart';
import '../screens/Add.dart';
import '../screens/profile.dart';


class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});
  
  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
  const RecipesScreen(),
  const CheckListScreen(),
  const AddScreen(),
  const ProfileScreen(),
];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
           BottomNavigationBarItem(icon: Icon(Icons.book), label: "Recipes"),
           BottomNavigationBarItem(icon: Icon(Icons.checklist), label: "Checklist"),
           BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Add"),
           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ],
      ),
    );
  }
}
