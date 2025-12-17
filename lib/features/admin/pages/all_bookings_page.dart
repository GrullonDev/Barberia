import 'package:flutter/material.dart';

import 'package:barberia/core/database/database_helper.dart';
import 'package:barberia/features/booking/models/booking.dart';

class AllBookingsPage extends StatefulWidget {
  const AllBookingsPage({super.key});

  @override
  State<AllBookingsPage> createState() => _AllBookingsPageState();
}

class _AllBookingsPageState extends State<AllBookingsPage> {
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    _bookingsFuture = _fetchBookings();
  }

  Future<List<Booking>> _fetchBookings() async {
    final DatabaseHelper dbHelper = DatabaseHelper.instance;
    final List<Map<String, dynamic>> bookingMaps = await dbHelper
        .getAllBookings();
    return bookingMaps
        .map((Map<String, dynamic> map) => Booking.fromMap(map))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todas las Reservas')),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Booking>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay reservas.'));
          }

          final List<Booking> bookings = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadBookings();
              });
            },
            child: ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (BuildContext context, int index) {
                final Booking booking = bookings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(booking.serviceName),
                    subtitle: Text(
                      'Cliente: ${booking.customerName}\nFecha: ${booking.dateTime}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
