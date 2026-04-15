import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
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

  final List<String> allInterests = [
    'Creativity', 'Technology', 'Nature', 'Music',
    'Fitness', 'Business', 'Art', 'Travel', 'Personal Growth', 'Gaming',
  ];

  List<String> selectedInterests = [];

  @override
  void initState() {
    super.initState();
    nameController   = TextEditingController(text: widget.profile.nombre);
    avatarController = TextEditingController(text: widget.profile.avatarUrl);
    selectedInterests = List.from(widget.profile.intereses ?? []);
  }

  Future<void> saveProfile() async {
    setState(() => loading = true);
    final token = await TokenService().getToken();
    if (token == null) return;
    try {
      await ProfileService().updateProfile(token, nameController.text, avatarController.text, selectedInterests);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      print('UPDATE ERROR: $e');
    }
    setState(() => loading = false);
  }

  void _toggle(String interest) {
    setState(() {
      selectedInterests.contains(interest)
          ? selectedInterests.remove(interest)
          : selectedInterests.add(interest);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Avatar preview
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 30)],
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.card,
                  backgroundImage: avatarController.text.isNotEmpty ? NetworkImage(avatarController.text) : null,
                  child: avatarController.text.isEmpty
                      ? const Icon(Icons.person_rounded, size: 45, color: AppColors.muted) : null,
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: avatarController,
              style: const TextStyle(color: AppColors.ink),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Avatar URL',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.ink),
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              enabled: false,
              controller: TextEditingController(text: widget.profile.email),
              style: const TextStyle(color: AppColors.faint),
              decoration: const InputDecoration(
                labelText: 'Email (no editable)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 28),

            const Text('Intereses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 5),
            const Text('Elige los que más te representen', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),

            Wrap(
              spacing: 10, runSpacing: 10,
              children: allInterests.map((interest) {
                final selected = selectedInterests.contains(interest);
                return GestureDetector(
                  onTap: () => _toggle(interest),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.brandGradient : null,
                      color: selected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? Colors.transparent : AppColors.border),
                    ),
                    child: Text(interest,
                        style: TextStyle(
                          fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? Colors.white : AppColors.muted,
                        )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity, height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: loading ? null : AppColors.brandGradient,
                  color: loading ? AppColors.faint : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: loading ? [] : [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: ElevatedButton(
                  onPressed: loading ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar cambios', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}