import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:barberia/app/router.dart';
import 'package:barberia/common/prefs/reminder_prefs.dart';
import 'package:barberia/common/utils/form_validators.dart';
import 'package:barberia/common/utils/gt_phone_formatter.dart';
import 'package:barberia/features/booking/models/booking_draft.dart';
import 'package:barberia/features/booking/models/service.dart';
import 'package:barberia/features/booking/providers/booking_providers.dart';
import 'package:barberia/l10n/app_localizations.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool? _acceptRemindersCache; // null hasta que se lea provider
  final FocusNode _nameNode = FocusNode();
  final FocusNode _phoneNode = FocusNode();
  final FocusNode _emailNode = FocusNode();
  final FocusNode _notesNode = FocusNode();
  // Persistencia y máscaras
  static const String _kDraftName = 'draft_name';
  static const String _kDraftPhone = 'draft_phone';
  static const String _kDraftEmail = 'draft_email';
  static const String _kDraftNotes = 'draft_notes';
  String? _rawPhone;
  String? _rawEmail;
  bool _phoneMasked = false;
  bool _emailMasked = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _nameCtrl.addListener(_persistDebounced);
    _phoneCtrl.addListener(_onPhoneChanged);
    _emailCtrl.addListener(_onEmailChanged);
    _notesCtrl.addListener(_persistDebounced);
    _phoneNode.addListener(() {
      if (_phoneNode.hasFocus && _phoneMasked) {
        _phoneCtrl.text = _rawPhone ?? '';
        _phoneMasked = false;
        _moveCursorToEnd(_phoneCtrl);
      }
    });
    _emailNode.addListener(() {
      if (_emailNode.hasFocus && _emailMasked) {
        _emailCtrl.text = _rawEmail ?? '';
        _emailMasked = false;
        _moveCursorToEnd(_emailCtrl);
      }
    });
  }

  void _moveCursorToEnd(TextEditingController c) {
    c.selection = TextSelection.collapsed(offset: c.text.length);
  }

  Future<void> _loadDraft() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!mounted) {
        return;
      }
      final String? name = prefs.getString(_kDraftName);
      final String? phone = prefs.getString(_kDraftPhone);
      final String? email = prefs.getString(_kDraftEmail);
      final String? notes = prefs.getString(_kDraftNotes);
      if (name != null) {
        _nameCtrl.text = name;
      }
      if (phone != null && phone.isNotEmpty) {
        _rawPhone = phone;
        _phoneCtrl.text = _maskPhone(phone);
        _phoneMasked = true;
      }
      if (email != null && email.isNotEmpty) {
        _rawEmail = email;
        _emailCtrl.text = _maskEmail(email);
        _emailMasked = true;
      }
      if (notes != null) {
        _notesCtrl.text = notes;
      }
      setState(() {});
    } catch (_) {
      /* ignore */
    }
  }

  String _maskPhone(String raw) {
    if (raw.length != 8) {
      return '•••• ••••';
    }
    return '${raw.substring(0, 4)} ••••';
  }

  String _maskEmail(String raw) {
    final int at = raw.indexOf('@');
    if (at <= 1) {
      return '***';
    }
    final String local = raw.substring(0, at);
    final String domain = raw.substring(at);
    final String visible = local.length <= 3 ? local[0] : local.substring(0, 2);
    return '$visible***$domain';
  }

  DateTime? _lastPersist;
  void _persistDebounced() {
    final DateTime now = DateTime.now();
    if (_lastPersist != null &&
        now.difference(_lastPersist!).inMilliseconds < 350) {
      return; // throttle
    }
    _lastPersist = now;
    _persist();
  }

  Future<void> _persist() async {
    if (_saving) {
      return; // simple guard
    }
    _saving = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDraftName, _nameCtrl.text);
      await prefs.setString(
        _kDraftPhone,
        _rawPhone ??
            (_phoneMasked
                ? (_rawPhone ?? '')
                : _phoneCtrl.text.replaceAll(' ', '')),
      );
      await prefs.setString(
        _kDraftEmail,
        _rawEmail ?? (_emailMasked ? (_rawEmail ?? '') : _emailCtrl.text),
      );
      await prefs.setString(_kDraftNotes, _notesCtrl.text);
    } catch (_) {
      /* ignore */
    }
    _saving = false;
  }

  void _onPhoneChanged() {
    if (_phoneMasked) {
      return; // ignore masked representation
    }
    final String digits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    _rawPhone = digits;
    _persistDebounced();
  }

  void _onEmailChanged() {
    if (_emailMasked) {
      return;
    }
    _rawEmail = _emailCtrl.text;
    _persistDebounced();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    _nameNode.dispose();
    _phoneNode.dispose();
    _emailNode.dispose();
    _notesNode.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final BookingDraft draft = ref.watch(bookingDraftProvider);
    final bool optIn = ref.watch(reminderOptInProvider);
    _acceptRemindersCache ??= optIn; // inicializar una vez
    final bool ready = draft.dateTime != null && draft.service != null;
    String? disabledReason;
    if (!ready) {
      if (draft.service == null) {
        disabledReason = 'Selecciona un servicio primero';
      } else if (draft.dateTime == null) {
        disabledReason = 'Selecciona fecha y hora';
      }
    }

    void submit() {
      if (!ready) {
        return;
      }
      if (!_formKey.currentState!.validate()) {
        return;
      }
      if (_phoneCtrl.text.isEmpty && _emailCtrl.text.isEmpty) {
        // Forzamos al menos uno.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa Teléfono o Email.')),
        );
        return;
      }
      // Validación de conflicto horario
      final Service service = draft.service!;
      final DateTime start = draft.dateTime!;
      final Duration dur = Duration(minutes: service.durationMinutes);
      final bool conflict = ref
          .read(bookingsProvider.notifier)
          .hasConflict(start, dur);
      if (conflict) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horario no disponible, selecciona otra hora.'),
          ),
        );
        return;
      }
      ref
          .read(bookingDraftProvider.notifier)
          .setCustomerInfo(
            name: _nameCtrl.text,
            phone: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
            email: _emailCtrl.text.isEmpty ? null : _emailCtrl.text,
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          );
      // Animación de éxito antes de navegar.
      // Capture navigators early.
      final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);
      void goToConfirmation() => context.goNamed(RouteNames.confirmation);
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'success',
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionDuration: const Duration(milliseconds: 480),
        transitionBuilder:
            (BuildContext dialogCtx, Animation<double> anim, _, Widget child) {
              final CurvedAnimation curved = CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutBack,
              );
              // Use dialogCtx instead of outer context to avoid accessing deactivated ancestor.
              final ColorScheme cs = Theme.of(dialogCtx).colorScheme;
              return Opacity(
                opacity: anim.value,
                child: ScaleTransition(
                  scale: curved,
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.check_circle, size: 72, color: cs.primary),
                        const SizedBox(height: 16),
                        const Text(
                          'Reserva lista',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Generando confirmación...',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
      );
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) {
          return; // still mounted; safe to use captured references
        }
        rootNav.pop();
        goToConfirmation();
      });
    }

    final S tr = S.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr.details_client_title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: <Widget>[
              // Progress indicator (Step 3 of 3)
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Paso 3 de 3',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // miniature visual progress bars
                  const _StepDot(done: true),
                  const SizedBox(width: 4),
                  const _StepDot(done: true),
                  const SizedBox(width: 4),
                  const _StepDot(done: true, current: true),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tr.details_form_intro,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                tr.details_contact_hint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              _SummaryBlock(draft: draft),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                focusNode: _nameNode,
                autofocus: true,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _phoneNode.requestFocus(),
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: FormValidators.validateName,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                focusNode: _phoneNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _emailNode.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Teléfono (8 dígitos)',
                  hintText: '1234 5678',
                ),
                inputFormatters: <TextInputFormatter>[GtPhoneFormatter()],
                validator: (final String? v) {
                  if (v == null || v.isEmpty) {
                    return null; // opcional si email
                  }
                  return FormValidators.validatePhone(v);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                focusNode: _emailNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _notesNode.requestFocus(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'ejemplo@correo.com',
                ),
                validator: (final String? v) {
                  if (v == null || v.isEmpty) {
                    return null; // opcional si teléfono
                  }
                  return FormValidators.validateEmail(v);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notesCtrl,
                focusNode: _notesNode,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Alergias, preferencias, etc.',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Checkbox(
                    value: _acceptRemindersCache ?? false,
                    onChanged: (final bool? v) {
                      setState(() => _acceptRemindersCache = v ?? false);
                      ref.read(reminderOptInProvider.notifier).set(v ?? false);
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: <TextSpan>[
                          TextSpan(text: tr.details_reminders_label),
                          TextSpan(
                            text: tr.privacy_title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.pushNamed(RouteNames.privacy);
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Tooltip(
                message: disabledReason ?? tr.details_confirm,
                waitDuration: const Duration(milliseconds: 400),
                child: FilledButton(
                  onPressed: ready ? submit : null,
                  child: Text(tr.details_confirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, this.current = false});
  final bool done;
  final bool current;
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fill = done
        ? (current ? cs.primary : cs.primaryContainer)
        : cs.surfaceContainerHighest;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: current ? 22 : 12,
      height: 12,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.draft});
  final BookingDraft draft;

  @override
  Widget build(BuildContext context) {
    final TextTheme txt = Theme.of(context).textTheme;
    if (draft.service == null || draft.dateTime == null) {
      return const SizedBox();
    }
    final DateTime dt = draft.dateTime!;
    final String dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final String timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final double price = draft.service!.price;
    final String priceStr = NumberFormat.currency(
      name: 'GTQ',
      symbol: 'Q',
    ).format(price);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(90),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  draft.service!.name,
                  style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('$dateStr • $timeStr', style: txt.bodySmall),
                const SizedBox(height: 4),
                Text(
                  'Total: $priceStr',
                  style: txt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
