import 'package:flutter/material.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../profile/data/profile_service.dart';
import '../../profile/models/user_profile.dart';
import '../widgets/aura_display.dart';
import '../widgets/next_stop_card.dart';

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
    loadData();
  }

  Future<void> loadData() async {

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
      print("HOME ERROR: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null) {
      return const Center(child: Text("Error cargando datos"));
    }

    final auraColor = ColorUtils.hexToColor(profile!.auraColorActual);

    return Scaffold(

      body: Container(

        width: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              auraColor.withOpacity(0.25),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(

          child: RefreshIndicator(
            onRefresh: loadData,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),

              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [

                    const SizedBox(height: 20),

                    /// 🔥 AURA
                    AuraDisplay(
                      auraColor: auraColor,
                      nombre: profile!.nombre,
                    ),

                    const SizedBox(height: 30),

                    /// 🔥 CARD IA (MOCK)
                    const NextStopCard(),

                    const SizedBox(height: 25),

                    /// 🔥 INFO EXTRA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        _infoItem("Nivel", "${profile!.auraNivel}"),
                        _infoItem("Puntos", "${profile!.auraPuntos}"),

                      ],
                    ),

                    const SizedBox(height: 30),

                    /// 🔥 BOTONES RÁPIDOS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        _quickButton(Icons.qr_code, "Mi QR"),
                        _quickButton(Icons.event, "Eventos"),
                        _quickButton(Icons.map, "Mapa"),

                      ],
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
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _quickButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          child: Icon(icon),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}