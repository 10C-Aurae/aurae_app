import 'package:flutter/material.dart';
import '../data/event_service.dart';
import '../models/event.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {

  List<Event> events = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {

    try {

      final result = await EventService().getEvents();

      setState(() {
        events = result;
        loading = false;
      });

    } catch (e) {

      print("EVENTS ERROR: $e");

      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(

      appBar: AppBar(title: const Text("Eventos")),

      body: RefreshIndicator(
        onRefresh: loadEvents,

        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,

          itemBuilder: (context, index) {

            final event = events[index];

            return EventCard(
              event: event,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EventDetailScreen(event: event),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}