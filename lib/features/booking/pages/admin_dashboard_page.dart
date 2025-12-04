import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:barberia/common/design_tokens.dart';
import 'package:barberia/features/booking/models/booking.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/common/database_helper.dart';
import 'package:share_plus/share_plus.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Booking> _getBookingsForDay(DateTime day, List<Booking> allBookings) {
    return allBookings.where((Booking booking) {
      return isSameDay(booking.dateTime, day) &&
          booking.status == BookingStatus.active;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Booking> bookings = ref.watch(bookingsProvider);
    final List<Booking> selectedBookings = _getBookingsForDay(
      _selectedDay!,
      bookings,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Base de Datos',
            onPressed: () async {
              try {
                final String path = await DatabaseHelper.instance.dbPath;
                await Share.shareXFiles(<XFile>[
                  XFile(path),
                ], text: 'Barberia Database (SQLite)');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error exportando DB: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          TableCalendar<Booking>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (DateTime day) =>
                isSameDay(_selectedDay, day),
            eventLoader: (DateTime day) => _getBookingsForDay(day, bookings),
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (CalendarFormat format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (DateTime focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: selectedBookings.length,
              itemBuilder: (BuildContext context, int index) {
                final Booking booking = selectedBookings[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Text(
                        DateFormat('HH:mm').format(booking.dateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(booking.customerName),
                    subtitle: Text(
                      '${booking.service.name}\n${booking.customerPhone ?? "Sin teléfono"}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text('Cancelar Reserva'),
                            content: Text(
                              '¿Estás seguro de cancelar la reserva de ${booking.customerName}?',
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(bookingsProvider.notifier)
                                      .cancel(booking.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('Sí, Cancelar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
