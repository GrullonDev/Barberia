import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddServicePage extends ConsumerStatefulWidget {
  const AddServicePage({super.key});

  @override
  ConsumerState<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends ConsumerState<AddServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  ServiceCategory _selectedCategory = ServiceCategory.hair;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Service')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a duration';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              DropdownButton<ServiceCategory>(
                value: _selectedCategory,
                onChanged: (ServiceCategory? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                items: ServiceCategory.values
                    .map<DropdownMenuItem<ServiceCategory>>((
                      ServiceCategory value,
                    ) {
                      return DropdownMenuItem<ServiceCategory>(
                        value: value,
                        child: Text(value.toString().split('.').last),
                      );
                    })
                    .toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newService = Service(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      durationMinutes: int.parse(_durationController.text),
                      price: double.parse(_priceController.text),
                      extendedDescription: _descriptionController.text,
                      category: _selectedCategory,
                    );
                    await ref
                        .read(serviceRepositoryProvider)
                        .addService(newService);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                child: const Text('Add Service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
