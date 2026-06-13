import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:barberia/app/router.dart';

/// Wordmark, tagline and link row shown at the bottom of the customer-facing
/// pages.
class GentlemanFooter extends StatelessWidget {
  const GentlemanFooter({super.key});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme txt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('THE GENTLEMAN', style: txt.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Crafting Confidence Since 1924',
            style: txt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: <Widget>[
              GestureDetector(
                onTap: () => context.pushNamed(RouteNames.privacy),
                child: Text(
                  'POLÍTICA DE PRIVACIDAD',
                  style: txt.labelSmall?.copyWith(color: cs.primary),
                ),
              ),
              Text('TÉRMINOS DE SERVICIO', style: txt.labelSmall),
              Text('CARRERAS', style: txt.labelSmall),
              Text('CONTACTO', style: txt.labelSmall),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '© 2026 THE GENTLEMAN. TODOS LOS DERECHOS RESERVADOS.',
            style: txt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
