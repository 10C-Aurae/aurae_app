import 'package:flutter/material.dart';

import '../features/home/screens/home_screen.dart';
import '../features/discover/screens/discover_screen.dart';
import '../features/ai/screens/ai_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/tickets/screens/ticket_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int currentIndex = 0;

  final screens = const [
    HomeScreen(),
    DiscoverScreen(),
    AIScreen(),
    TicketsScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  final titles = const [
    "Aurae",
    "Discover",
    "AI",
    "Tickets",
    "Profile",
    "Settings",
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(titles[currentIndex]),
      ),

      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

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
            icon: Icon(Icons.psychology),
            label: "AI",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num),
            label: "Tickets",
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