import 'package:flutter/material.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/data/profile_service.dart';
import '../widgets/aura_card.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {

  UserProfile? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {

    try {

      final result = await ProfileService.getProfile();

      setState(() {
        profile = result;
        loading = false;
      });

    } catch (e) {

        print("ERROR PROFILE: $e");

        setState(() {
            loading = false;
        });

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Aurae"),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(

              padding: const EdgeInsets.all(20),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Welcome back",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (profile != null)
                    AuraCard(profile: profile!),

                  const SizedBox(height: 30),

                  const Text(
                    "Recommended for you",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ListTile(
                    leading: const Icon(Icons.self_improvement),
                    title: const Text("Meditation"),
                    subtitle: const Text("Balance your aura energy"),
                  ),

                  ListTile(
                    leading: const Icon(Icons.lightbulb),
                    title: const Text("Creative thinking"),
                    subtitle: const Text("Boost your indigo aura"),
                  ),

                  ListTile(
                    leading: const Icon(Icons.menu_book),
                    title: const Text("Reflection"),
                    subtitle: const Text("Understand your archetype"),
                  ),

                ],

              ),
            ),

    );

  }

}