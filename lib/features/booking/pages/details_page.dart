import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/utils/form_validators.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';

class DetailsPage extends ConsumerStatefulWidget {
  const DetailsPage({super.key});

  @override
  ConsumerState<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends ConsumerState<DetailsPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final BookingDraft draft = ref.watch(bookingDraftProvider);
    final bool ready = draft.dateTime != null && draft.service != null;

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Cliente')),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (final String? v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (final String? v) => FormValidators.validatePhone(v),
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (final String? v) => v == null || v.isEmpty
                    ? null
                    : FormValidators.validateEmail(v),
              ),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                ),
                maxLines: 2,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: !ready
                    ? null
                    : () {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        ref
                            .read(bookingDraftProvider.notifier)
                            .setCustomerInfo(
                              name: _nameCtrl.text,
                              phone: _phoneCtrl.text,
                              email: _emailCtrl.text.isEmpty
                                  ? null
                                  : _emailCtrl.text,
                              notes: _notesCtrl.text.isEmpty
                                  ? null
                                  : _notesCtrl.text,
                            );
                        context.goNamed(RouteNames.confirmation);
                      },
                child: const Text('Confirmar Reserva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
