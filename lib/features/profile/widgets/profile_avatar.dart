import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {

  final String avatarUrl;

  const ProfileAvatar({super.key, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {

    return CircleAvatar(
      radius: 50,
      backgroundImage: avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl.isEmpty
          ? const Icon(Icons.person, size: 50)
          : null,
    );

  }

}