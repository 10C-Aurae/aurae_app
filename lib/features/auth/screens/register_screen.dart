import 'package:flutter/material.dart';
import '../data/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  List<String> selectedInterests = [];

  final List<String> interests = [
    "Meditation",
    "Spirituality",
    "Creativity",
    "Mindfulness",
    "Personal Growth",
    "Technology",
    "Nature",
    "Philosophy"
  ];

  Future<void> register() async {

    setState(() {
      loading = true;
    });

    try {

      await AuthService.register(
        nameController.text,
        emailController.text,
        passwordController.text,
        selectedInterests,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully"),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error creating account"),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      setState(() {
        loading = false;
      });

    }

  }

  void toggleInterest(String interest) {

    setState(() {

      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else {
        selectedInterests.add(interest);
      }

    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Create Account"),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Register",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Select your interests",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: interests.map((interest) {

                final selected = selectedInterests.contains(interest);

                return ChoiceChip(

                  label: Text(interest),

                  selected: selected,

                  onSelected: (_) {
                    toggleInterest(interest);
                  },

                );

              }).toList(),
            ),

            const SizedBox(height: 40),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed: loading ? null : register,

                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Register"),

              ),

            )

          ],

        ),

      ),

    );

  }

}