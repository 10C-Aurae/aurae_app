import 'package:flutter/material.dart';
import '../data/profile_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();

}

class _ProfileScreenState extends State<ProfileScreen> {

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

      print(e);

      setState(() {
        loading = false;
      });

    }

  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null) {
      return const Center(child: Text("Error loading profile"));
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("Profile"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.center,

          children: [

            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),

            const SizedBox(height: 16),

            Text(
              profile!.nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              profile!.email,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                title: const Text("Aura Color"),
                subtitle: Text(profile!.auraColor),
              ),
            ),

            Card(
              child: ListTile(
                title: const Text("Aura Level"),
                subtitle: Text(profile!.auraLevel.toString()),
              ),
            ),

            Card(
              child: ListTile(
                title: const Text("Aura Points"),
                subtitle: Text(profile!.auraPoints.toString()),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Interests",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: profile!.interests.map((interest) {

                return Chip(
                  label: Text(interest.toString()),
                );

              }).toList(),
            )

          ],

        ),

      ),

    );

  }

}