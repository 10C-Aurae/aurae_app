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

    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(

      child: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(
              "Welcome back ${profile?.nombre ?? ''}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (profile != null)
              AuraCard(profile: profile!),

          ],

        ),

      ),

    );

  }

}