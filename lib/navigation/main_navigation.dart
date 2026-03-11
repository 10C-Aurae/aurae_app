import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/discover_screen.dart';
import '../screens/ai_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int currentIndex = 0;

  final screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const AIScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: currentIndex,

        onTap: (index) {
            setState(() {
                currentIndex = index;
            });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xFF6C63FF),

        unselectedItemColor: Colors.grey,

        items: const [

            BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
            ),

            BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: "Discover",
            ),

            BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: "AI",
            ),

            BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
            ),

            BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
            ),

        ],

        ),

    );
  }
}