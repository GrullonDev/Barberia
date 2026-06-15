import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barberia/features/config/models/barberia_config.dart';
import 'package:barberia/features/config/providers/barberia_config_providers.dart';
import 'package:barberia/common/utils/responsive_helper.dart';

class AdminConfigPage extends ConsumerStatefulWidget {
  const AdminConfigPage({super.key});

  @override
  ConsumerState<AdminConfigPage> createState() => _AdminConfigPageState();
}

class _AdminConfigPageState extends ConsumerState<AdminConfigPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _whatsappCtrl;
  late final TextEditingController _domainCtrl;
  late final TextEditingController _openHourCtrl;
  late final TextEditingController _closeHourCtrl;

  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _businessNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lngCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _whatsappCtrl = TextEditingController();
    _domainCtrl = TextEditingController();
    _openHourCtrl = TextEditingController();
    _closeHourCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _domainCtrl.dispose();
    _openHourCtrl.dispose();
    _closeHourCtrl.dispose();
    super.dispose();
  }

  void _initFields(BarberiaConfig config) {
    if (_initialized) {
      return;
    }
    _businessNameCtrl.text = config.businessName;
    _addressCtrl.text = config.address;
    _latCtrl.text = config.lat?.toString() ?? '';
    _lngCtrl.text = config.lng?.toString() ?? '';
    _phoneCtrl.text = config.phone ?? '';
    _whatsappCtrl.text = config.whatsappPhone ?? '';
    _domainCtrl.text = config.landingBaseUrl ?? '';
    _openHourCtrl.text = config.openHour.toString();
    _closeHourCtrl.text = config.closeHour.toString();
    _initialized = true;
  }

  Future<void> _save(BarberiaConfig currentConfig) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final updatedConfig = currentConfig.copyWith(
        businessName: _businessNameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        lat: double.tryParse(_latCtrl.text),
        lng: double.tryParse(_lngCtrl.text),
        phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text.trim(),
        whatsappPhone: _whatsappCtrl.text.isEmpty
            ? null
            : _whatsappCtrl.text.trim(),
        landingBaseUrl: _domainCtrl.text.isEmpty
            ? null
            : _domainCtrl.text.trim(),
        openHour: int.parse(_openHourCtrl.text),
        closeHour: int.parse(_closeHourCtrl.text),
      );

      await ref.read(barberiaConfigRepositoryProvider).upsert(updatedConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la configuración: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(barberiaConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración del Negocio')),
      body: configAsync.when(
        data: (config) {
          _initFields(config);
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(
                ResponsiveHelper.getResponsivePadding(context),
              ),
              children: [
                Text(
                  'Personalización General',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Negocio *',
                    hintText: 'Ej. Clipz Barbería',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _domainCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dominio / URL Web de Citas',
                    hintText: 'Ej. https://mi-barberia.web.app',
                    prefixIcon: Icon(Icons.language),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return null;
                    }
                    if (!v.startsWith('http://') && !v.startsWith('https://')) {
                      return 'Debe iniciar con http:// o https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Contacto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de contacto',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whatsappCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono WhatsApp (Formato internacional)',
                    hintText: 'Ej. 50242909548',
                    prefixIcon: Icon(Icons.chat),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ubicación',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección física',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitud',
                          hintText: 'Ej. 14.503056',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return null;
                          }
                          if (double.tryParse(v) == null) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitud',
                          hintText: 'Ej. -90.577228',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return null;
                          }
                          if (double.tryParse(v) == null) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Horarios de Atención',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _openHourCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hora Apertura (0-23)',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final val = int.tryParse(v);
                          if (val == null || val < 0 || val > 23) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _closeHourCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hora Cierre (0-23)',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final val = int.tryParse(v);
                          if (val == null || val < 0 || val > 23) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(config),
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Guardar Configuración'),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error al cargar la configuración: $err')),
      ),
    );
  }
}
