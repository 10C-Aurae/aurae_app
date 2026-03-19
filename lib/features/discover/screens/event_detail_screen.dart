import 'package:flutter/material.dart';
import '../models/event.dart';

class EventDetailScreen extends StatelessWidget {

  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Column(
        children: [

          /// 🔥 HEADER IMAGE + BACK
          Stack(
            children: [

              SizedBox(
                height: 260,
                width: double.infinity,
                child: event.imagenUrl.isNotEmpty
                    ? Image.network(
                        event.imagenUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(color: Colors.grey.shade300),
              ),

              /// DEGRADADO
              Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),

              /// BACK BUTTON
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ],
          ),

          /// 🔥 CONTENIDO
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -20),

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// NOMBRE
                      Text(
                        event.nombre,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// UBICACIÓN
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18),
                          const SizedBox(width: 5),
                          Expanded(child: Text(event.ubicacionNombre)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// FECHA
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            "${event.fechaInicio.toLocal()}".split(".")[0],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// PRECIO
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: event.esGratuito
                              ? Colors.green
                              : Colors.deepPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.esGratuito
                              ? "GRATIS"
                              : "\$${event.precio}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// DESCRIPCIÓN
                      const Text(
                        "Descripción",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(event.descripcion),

                      const SizedBox(height: 30),

                      /// BOTÓN
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // futuro: comprar ticket
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text("Obtener Ticket"),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}