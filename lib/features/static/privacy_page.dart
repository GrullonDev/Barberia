import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:barberia/l10n/app_localizations.dart';

/// Simple placeholder privacy policy screen.
/// Later this will be replaced / enriched with real company policy content.
// Placeholder future for remote markdown (disabled until dependency added)
final privacyMarkdownProvider = FutureProvider.autoDispose<String?>((ref) async {
  // Simple remote fetch (replace URL with real endpoint). If fails returns null.
  const String url = 'https://raw.githubusercontent.com/github/gitignore/main/README.md'; // placeholder file
  try {
    final http.Response resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200 && resp.body.isNotEmpty) {
      return utf8.decode(resp.bodyBytes);
    }
  } catch (_) {/* ignore */}
  return null;
});

class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  final ScrollController _scroll = ScrollController();
  // double _savedOffset = 0; // reserved for persistence
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{
    'header': GlobalKey(),
    'principles': GlobalKey(),
    'note': GlobalKey(),
  };

  @override
  void dispose() {
  // _savedOffset = _scroll.offset; // potential persistence spot
    _scroll.dispose();
    super.dispose();
  }

  void _jumpTo(String key) {
    final BuildContext? ctx = _sectionKeys[key]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final S tr = S.of(context);
    final TextTheme txt = Theme.of(context).textTheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final AsyncValue<String?> md = ref.watch(privacyMarkdownProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr.privacy_title)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Section index chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: <Widget>[
                  _IndexChip(label: tr.privacy_prelim_header, onTap: () => _jumpTo('header')),
                  const SizedBox(width: 8),
                  _IndexChip(label: tr.privacy_principles_title, onTap: () => _jumpTo('principles')),
                  const SizedBox(width: 8),
                  _IndexChip(label: tr.privacy_note_title, onTap: () => _jumpTo('note')),
                ],
              ),
            ),
            Expanded(
              child: md.when(
                data: (final String? remote) {
                  // If remote markdown were available we would render it; currently fallback.
                  if (remote != null) {
                    return Markdown(
                      controller: _scroll,
                      data: remote,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: txt.bodyMedium,
                      ),
                    );
                  }
                  return ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: <Widget>[
                      Container(
                        key: _sectionKeys['header'],
                        child: Text(tr.privacy_prelim_header, style: txt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 12),
                      Text(tr.privacy_prelim_body, style: txt.bodyMedium),
                      const SizedBox(height: 28),
                      Container(
                        key: _sectionKeys['principles'],
                        child: Text(tr.privacy_principles_title, style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 12),
                      _Bullet(tr.privacy_principle_minimum),
                      _Bullet(tr.privacy_principle_opt_in),
                      _Bullet(tr.privacy_principle_erasure),
                      _Bullet(tr.privacy_principle_security),
                      const SizedBox(height: 28),
                      Container(
                        key: _sectionKeys['note'],
                        child: Text(tr.privacy_note_title, style: txt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      Text(tr.privacy_note_body, style: txt.bodySmall),
                      const SizedBox(height: 40),
                      if (dark)
                        Center(
                          child: Icon(Icons.shield_moon, size: 72, color: Theme.of(context).colorScheme.primary),
                        )
                      else
                        Center(
                          child: Icon(Icons.shield_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
                        ),
                      const SizedBox(height: 28),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              tr.privacy_version_label('0.1', DateFormat('yyyy-MM-dd').format(DateTime.now())),
                              style: txt.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.check),
                            label: Text(tr.privacy_acknowledge),
                          ),
                        ],
                      )
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    Text(tr.privacy_prelim_header, style: txt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(tr.privacy_prelim_body, style: txt.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8),
          ),
            const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _IndexChip extends StatelessWidget {
  const _IndexChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: .4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
