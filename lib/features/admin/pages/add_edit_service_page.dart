import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/repositories/service_repository.dart';

class AddEditServicePage extends ConsumerStatefulWidget {
  final Service? service; // If null, adding new service

  const AddEditServicePage({super.key, this.service});

  @override
  ConsumerState<AddEditServicePage> createState() => _AddEditServicePageState();
}

class _AddEditServicePageState extends ConsumerState<AddEditServicePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _descCtrl;
  ServiceCategory _selectedCategory = ServiceCategory.hair;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.service?.price.toString() ?? '',
    );
    _durationCtrl = TextEditingController(
      text: widget.service?.durationMinutes.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: widget.service?.extendedDescription ?? '',
    );
    if (widget.service != null) {
      _selectedCategory = widget.service!.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final String name = _nameCtrl.text.trim();
      final double price = double.parse(_priceCtrl.text);
      final int duration = int.parse(_durationCtrl.text);
      final String? desc = _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim();

      final Service newService = Service(
        id: widget.service?.id,
        name: name,
        price: price,
        durationMinutes: duration,
        category: _selectedCategory,
        extendedDescription: desc,
        isActive: true, // Default active
      );

      final ServiceRepository repo = ref.read(serviceRepositoryProvider);

      if (widget.service == null) {
        await repo.addService(newService);
      } else {
        await repo.updateService(newService);
      }

      ref.invalidate(servicesAsyncProvider); // Refresh list

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.service != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Servicio' : 'Nuevo Servicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre Servicio'),
                validator: (String? v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio (\$)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (String? v) =>
                          double.tryParse(v!) == null ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Duración (min)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (String? v) =>
                          int.tryParse(v!) == null ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ServiceCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: ServiceCategory.values.map((ServiceCategory c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (ServiceCategory? v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ResultText(isEditing: isEditing),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultText extends StatelessWidget {
  const ResultText({required this.isEditing, super.key});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Text(isEditing ? 'Guardar Cambios' : 'Crear Servicio');
  }
}
