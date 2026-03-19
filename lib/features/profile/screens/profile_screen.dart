import 'package:flutter/material.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/utils/color_utils.dart';
import '../data/profile_service.dart';
import '../models/user_profile.dart';
import 'edit_profile_screen.dart';

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
    final token = await TokenService().getToken();

    if (token == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final result = await ProfileService().getMyProfile(token);

      setState(() {
        profile = result;
        loading = false;
      });
    } catch (e) {
      print("PROFILE ERROR: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text("No profile found")),
      );
    }

    final auraColor = ColorUtils.hexToColor(profile!.auraColorActual);

    return Scaffold(
      appBar: AppBar(
        // title: const Text("Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(profile: profile!),
                ),
              );
              loadProfile();
            },
          )
        ],
      ),

      body: Container(
        width: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              auraColor.withOpacity(0.18),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),

                child: Column(
                  children: [

                    const SizedBox(height: 20),

                    /// 🔥 AVATAR HERO
                    Stack(
                      alignment: Alignment.center,
                      children: [

                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: auraColor.withOpacity(0.5),
                                blurRadius: 60,
                                spreadRadius: 15,
                              )
                            ],
                          ),
                        ),

                        CircleAvatar(
                          radius: 60,
                          backgroundColor: auraColor.withOpacity(0.2),
                          backgroundImage: profile!.avatarUrl.isNotEmpty
                              ? NetworkImage(profile!.avatarUrl)
                              : null,
                          child: profile!.avatarUrl.isEmpty
                              ? const Icon(Icons.person, size: 55)
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    /// NOMBRE
                    Text(
                      profile!.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    /// EMAIL
                    Text(
                      profile!.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// 🔥 CARD PRINCIPAL
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(24),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: auraColor.withOpacity(0.25),
                            blurRadius: 30,
                            spreadRadius: 4,
                          )
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// NIVEL + PUNTOS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _infoItem("Nivel", "${profile!.auraNivel}"),
                              _infoItem("Puntos", "${profile!.auraPuntos}"),
                            ],
                          ),

                          const SizedBox(height: 25),

                          const Text(
                            "Intereses",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: (profile!.intereses ?? []).map((e) {
                              return Chip(
                                label: Text(e),
                                backgroundColor: auraColor.withOpacity(0.18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 ITEM INFO
  Widget _infoItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}