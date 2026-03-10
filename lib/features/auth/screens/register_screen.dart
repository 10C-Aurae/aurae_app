import 'package:flutter/material.dart';
import '../data/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String? message;

  Future<void> register() async {

    setState(() {
      loading = true;
      message = null;
    });

    try {

      await AuthService.register(
        nombreController.text,
        emailController.text,
        passwordController.text,
      );

      setState(() {
        message = "Account created successfully!";
      });

    } catch (e) {

      print(e);

      setState(() {
        message = e.toString();
      });

    } finally {

      setState(() {
        loading = false;
      });

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: const Text("Create Account")),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Name",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(

                onPressed: loading ? null : register,

                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Register"),

              ),
            ),

            const SizedBox(height: 20),

            if (message != null)
              Text(message!)

          ],
        ),
      ),
    );
  }
}