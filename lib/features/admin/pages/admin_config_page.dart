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

  int _openHour = 9;
  int _closeHour = 19;
  List<bool> _openDays = List<bool>.filled(7, true);
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
    _openHour = config.openHour;
    _closeHour = config.closeHour;
    _openDays = List<bool>.from(config.openDays);
    _initialized = true;
  }

  Future<void> _pickHour({required bool isOpen}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: isOpen ? _openHour : _closeHour,
        minute: 0,
      ),
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isOpen) {
        _openHour = picked.hour;
        if (_closeHour <= _openHour) {
          _closeHour = (_openHour + 1).clamp(0, 23);
        }
      } else {
        if (picked.hour > _openHour) {
          _closeHour = picked.hour;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La hora de cierre debe ser mayor que la apertura'),
            ),
          );
        }
      }
    });
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
        whatsappPhone:
            _whatsappCtrl.text.isEmpty ? null : _whatsappCtrl.text.trim(),
        landingBaseUrl:
            _domainCtrl.text.isEmpty ? null : _domainCtrl.text.trim(),
        openHour: _openHour,
        closeHour: _closeHour,
        openDays: List<bool>.from(_openDays),
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
                const _SectionTitle('Personalización General'),
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
                const _SectionTitle('Contacto'),
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
                const _SectionTitle('Ubicación'),
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
                          signed: true,
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
                          signed: true,
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
                const _SectionTitle('Horario de Atención'),
                const SizedBox(height: 16),

                // ── Días de apertura ──────────────────────────────────────
                Text(
                  'Días abiertos',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                _DaySelector(
                  openDays: _openDays,
                  onChanged: (int index, bool value) {
                    setState(() => _openDays[index] = value);
                  },
                ),
                const SizedBox(height: 20),

                // ── Horario ───────────────────────────────────────────────
                Text(
                  'Horas de operación',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TimeCard(
                        label: 'Apertura',
                        hour: _openHour,
                        icon: Icons.wb_sunny_outlined,
                        onTap: () => _pickHour(isOpen: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeCard(
                        label: 'Cierre',
                        hour: _closeHour,
                        icon: Icons.nights_stay_outlined,
                        onTap: () => _pickHour(isOpen: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SchedulePreview(
                  openHour: _openHour,
                  closeHour: _closeHour,
                  openDays: _openDays,
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

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ─── Day selector ─────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.openDays, required this.onChanged});

  final List<bool> openDays;
  final void Function(int index, bool value) onChanged;

  static const List<String> _labels = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(7, (int i) {
        final bool selected = openDays[i];
        return GestureDetector(
          onTap: () => onChanged(i, !selected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 52,
            decoration: BoxDecoration(
              color: selected ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? cs.primary
                    : cs.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _labels[i],
                  style: TextStyle(
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  selected ? Icons.check_circle : Icons.remove_circle_outline,
                  size: 14,
                  color: selected
                      ? cs.onPrimary.withValues(alpha: 0.8)
                      : cs.outlineVariant,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─── Time card ────────────────────────────────────────────────────────────────

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.hour,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final int hour;
  final IconData icon;
  final VoidCallback onTap;

  String _fmt(int h) {
    final int h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final String suffix = h < 12 ? 'AM' : 'PM';
    return '${h12.toString().padLeft(2, '0')}:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _fmt(hour),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toca para cambiar',
              style: TextStyle(
                color: cs.primary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule preview ─────────────────────────────────────────────────────────

class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview({
    required this.openHour,
    required this.closeHour,
    required this.openDays,
  });

  final int openHour;
  final int closeHour;
  final List<bool> openDays;

  static const List<String> _dayNames = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  String _fmt(int h) {
    final int h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final String suffix = h < 12 ? 'AM' : 'PM';
    return '${h12.toString().padLeft(2, '0')}:00 $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<String> openLabels = <String>[];
    for (int i = 0; i < 7; i++) {
      if (openDays[i]) {
        openLabels.add(_dayNames[i]);
      }
    }
    final String daysText = openLabels.isEmpty ? 'Sin días abiertos' : openLabels.join(' · ');
    final String hoursText = '${_fmt(openHour)} – ${_fmt(closeHour)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  daysText,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  hoursText,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
