import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../data/profile_service.dart';
import '../../../core/auth/token_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  late TextEditingController nameController;
  late TextEditingController avatarController;

  bool loading = false;

  /// 🔥 TODOS LOS INTERESES DISPONIBLES
  final List<String> allInterests = [
    "Creativity",
    "Technology",
    "Nature",
    "Music",
    "Fitness",
    "Business",
    "Art",
    "Travel",
    "Personal Growth",
    "Gaming"
  ];

  List<String> selectedInterests = [];

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.profile.nombre);
    avatarController = TextEditingController(text: widget.profile.avatarUrl);

    selectedInterests = List.from(widget.profile.intereses ?? []);
  }

  /// 💾 GUARDAR PERFIL
  Future<void> saveProfile() async {

    setState(() => loading = true);

    final token = await TokenService().getToken();

    if (token == null) return;

    try {

      await ProfileService().updateProfile(
        token,
        nameController.text,
        avatarController.text, // ⚠️ solo URL
        selectedInterests,
      );

      Navigator.pop(context);

    } catch (e) {
      print("UPDATE ERROR: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 AVATAR PREVIEW
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundImage: avatarController.text.isNotEmpty
                    ? NetworkImage(avatarController.text)
                    : null,
                child: avatarController.text.isEmpty
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            /// AVATAR URL
            TextField(
              controller: avatarController,
              decoration: const InputDecoration(
                labelText: "Avatar URL",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {}); // refresca preview
              },
            ),

            const SizedBox(height: 25),

            /// NOMBRE
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            /// EMAIL (SOLO VISUAL)
            TextField(
              enabled: false,
              controller: TextEditingController(text: widget.profile.email),
              decoration: const InputDecoration(
                labelText: "Email (no editable)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            /// 🔥 INTERESES
            const Text(
              "Selecciona tus intereses",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allInterests.map((interest) {

                final isSelected = selectedInterests.contains(interest);

                return ChoiceChip(
                  label: Text(interest),
                  selected: isSelected,

                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        selectedInterests.remove(interest);
                      } else {
                        selectedInterests.add(interest);
                      }
                    });
                  },
                );

              }).toList(),
            ),

            const SizedBox(height: 35),

            /// 🔥 BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : saveProfile,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Guardar cambios"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}