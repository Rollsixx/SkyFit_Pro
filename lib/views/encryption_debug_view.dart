import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';

/// Debug screen that shows every todo's raw AES-256-GCM encrypted payload
/// side-by-side with the decrypted plaintext.
///
/// Access it via the 🔍 icon in the TodoListView AppBar.
class EncryptionDebugView extends StatefulWidget {
  const EncryptionDebugView({super.key});

  @override
  State<EncryptionDebugView> createState() => _EncryptionDebugViewState();
}

class _EncryptionDebugViewState extends State<EncryptionDebugView> {
  // Tracks which cards have their encrypted payload expanded
  final Set<String> _expandedEncrypted = {};

  // Tracks which cards are showing decrypted text
  final Set<String> _revealedDecrypted = {};

  @override
  void initState() {
    super.initState();
    // Ensure todos are loaded when this view opens, regardless of
    // whether TodoListView already called loadTodos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<TodoViewModel>().loadTodos(user.email);
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Splits the v1:<iv_b64>:<cipher_b64> format into labelled parts.
  List<_PayloadPart> _parsePayload(String raw) {
    final parts = raw.split(':');
    if (parts.length != 3) {
      return [_PayloadPart('raw', raw)];
    }
    return [
      _PayloadPart('version', parts[0]),
      _PayloadPart('IV (base64)', parts[1]),
      _PayloadPart('ciphertext + tag (base64)', parts[2]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final todoVM = context.watch<TodoViewModel>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in', style: TextStyle(color: Colors.white))),
      );
    }

    final todos = todoVM.todos;

    return Scaffold(
      backgroundColor: Constants.dsBlack,
      appBar: AppBar(
        backgroundColor: Constants.dsBlack,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 20),
            const SizedBox(width: 8),
            const Text('Encryption Inspector'),
          ],
        ),
      ),
      body: SafeArea(
        child: todos.isEmpty
            ? const Center(
                child: Text(
                  'No todos to inspect.\nAdd one from the main screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header banner ──────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          Constants.dsTeal.withOpacity(0.25),
                          Constants.dsCrimson.withOpacity(0.18),
                        ],
                      ),
                      border: Border.all(
                        color: Constants.dsTeal.withOpacity(0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${todos.length} task${todos.length == 1 ? '' : 's'} • AES-256-GCM encrypted notes',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Format:  v1 : <IV base64> : <ciphertext+tag base64>',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Todo cards ─────────────────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                      itemCount: todos.length,
                      itemBuilder: (_, i) {
                        final todo = todos[i];
                        final decrypted = todoVM.decryptNoteForUi(todo);
                        return _InspectorCard(
                          todo: todo,
                          decryptedNote: decrypted,
                          isEncryptedExpanded:
                              _expandedEncrypted.contains(todo.id),
                          isDecryptedRevealed:
                              _revealedDecrypted.contains(todo.id),
                          payloadParts: _parsePayload(todo.encryptedNote),
                          onToggleEncrypted: () => setState(() {
                            _expandedEncrypted.contains(todo.id)
                                ? _expandedEncrypted.remove(todo.id)
                                : _expandedEncrypted.add(todo.id);
                          }),
                          onToggleDecrypted: () => setState(() {
                            _revealedDecrypted.contains(todo.id)
                                ? _revealedDecrypted.remove(todo.id)
                                : _revealedDecrypted.add(todo.id);
                          }),
                          onCopyEncrypted: () => _copyToClipboard(
                              todo.encryptedNote, 'Encrypted payload'),
                          onCopyDecrypted: () =>
                              _copyToClipboard(decrypted, 'Decrypted note'),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _PayloadPart {
  final String label;
  final String value;
  const _PayloadPart(this.label, this.value);
}

// ── Inspector Card ────────────────────────────────────────────────────────────

class _InspectorCard extends StatelessWidget {
  final TodoModel todo;
  final String decryptedNote;
  final bool isEncryptedExpanded;
  final bool isDecryptedRevealed;
  final List<_PayloadPart> payloadParts;
  final VoidCallback onToggleEncrypted;
  final VoidCallback onToggleDecrypted;
  final VoidCallback onCopyEncrypted;
  final VoidCallback onCopyDecrypted;

  const _InspectorCard({
    required this.todo,
    required this.decryptedNote,
    required this.isEncryptedExpanded,
    required this.isDecryptedRevealed,
    required this.payloadParts,
    required this.onToggleEncrypted,
    required this.onToggleDecrypted,
    required this.onCopyEncrypted,
    required this.onCopyDecrypted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Task title + meta ─────────────────────────────────────────
          Row(
            children: [
              Icon(
                todo.completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color:
                    todo.completed ? Colors.lightGreenAccent : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    decoration: todo.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              _PriorityBadge(priority: todo.priority),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${todo.id}',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(height: 14),
          const _SectionDivider(label: '🔒 ENCRYPTED PAYLOAD'),
          const SizedBox(height: 8),

          // ── Encrypted section ─────────────────────────────────────────
          if (!isEncryptedExpanded) ...[
            // Collapsed: single truncated line
            _MonoBox(
              text: _truncate(todo.encryptedNote, 60),
              color: Constants.dsCrimson.withOpacity(0.12),
              borderColor: Constants.dsCrimson.withOpacity(0.35),
            ),
          ] else ...[
            // Expanded: one sub-box per payload segment
            ...payloadParts.map(
              (part) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.label.toUpperCase(),
                      style: TextStyle(
                        color: Constants.dsCrimson.withOpacity(0.80),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _MonoBox(
                      text: part.value,
                      color: Constants.dsCrimson.withOpacity(0.08),
                      borderColor: Constants.dsCrimson.withOpacity(0.28),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 6),
          Row(
            children: [
              _ActionChip(
                icon: isEncryptedExpanded
                    ? Icons.unfold_less
                    : Icons.unfold_more,
                label: isEncryptedExpanded ? 'Collapse' : 'Expand',
                color: Constants.dsCrimson,
                onTap: onToggleEncrypted,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.copy,
                label: 'Copy',
                color: Constants.dsCrimson,
                onTap: onCopyEncrypted,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const _SectionDivider(label: '🔓 DECRYPTED PLAINTEXT'),
          const SizedBox(height: 8),

          // ── Decrypted section ─────────────────────────────────────────
          isDecryptedRevealed
              ? _MonoBox(
                  text: decryptedNote.isEmpty ? '(empty)' : decryptedNote,
                  color: Constants.dsTeal.withOpacity(0.10),
                  borderColor: Constants.dsTeal.withOpacity(0.40),
                  textColor: Colors.white.withOpacity(0.85),
                  softWrap: true,
                )
              : GestureDetector(
                  onTap: onToggleDecrypted,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Constants.dsTeal.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.visibility_off,
                            color: Constants.dsTeal.withOpacity(0.70),
                            size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to reveal decrypted note',
                          style: TextStyle(
                            color: Constants.dsTeal.withOpacity(0.70),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

          if (isDecryptedRevealed) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                _ActionChip(
                  icon: Icons.visibility_off,
                  label: 'Hide',
                  color: Constants.dsTeal,
                  onTap: onToggleDecrypted,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.copy,
                  label: 'Copy',
                  color: Constants.dsTeal,
                  onTap: onCopyDecrypted,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _truncate(String s, int maxLen) =>
      s.length <= maxLen ? s : '${s.substring(0, maxLen)}…';
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.10))),
      ],
    );
  }
}

class _MonoBox extends StatelessWidget {
  final String text;
  final Color color;
  final Color borderColor;
  final Color textColor;
  final bool softWrap;

  const _MonoBox({
    required this.text,
    required this.color,
    required this.borderColor,
    this.textColor = const Color(0xFFFF8A80),
    this.softWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      text,
      softWrap: softWrap,
      style: TextStyle(
        color: textColor,
        fontSize: 11,
        fontFamily: 'monospace',
        height: 1.5,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: softWrap
          ? textWidget
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: textWidget,
            ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  Color get _color {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.orangeAccent;
      default:
        return Colors.lightGreenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withOpacity(0.45)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}