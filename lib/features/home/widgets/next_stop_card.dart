import 'package:flutter/material.dart';

class NextStopCard extends StatelessWidget {
  const NextStopCard({super.key});

  @override
  Widget build(BuildContext context) {

    /// ⚠️ MOCK (hasta que haya IA real)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [

          Text(
            "Siguiente parada",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          SizedBox(height: 10),

          Text(
            "Stand de Tecnología",
            style: TextStyle(fontSize: 18),
          ),

          SizedBox(height: 5),

          Text(
            "Recomendado según tu aura",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}