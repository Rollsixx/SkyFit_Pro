import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';

/// Bottom sheet for both creating and editing a todo.
///
/// Pass [existing] to pre-populate fields for edit mode.
class TodoFormSheet extends StatefulWidget {
  final TodoModel? existing; // null = add mode

  const TodoFormSheet({super.key, this.existing});

  @override
  State<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends State<TodoFormSheet> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl  = TextEditingController();

  String    _priority = 'Medium';
  DateTime? _dueDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final todo   = widget.existing!;
      final todoVm = context.read<TodoViewModel>();

      _titleCtrl.text = todo.title;
      _noteCtrl.text  = todoVm.decryptNoteForUi(todo);
      _priority       = todo.priority;
      _dueDate        = todo.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final todoVm  = context.read<TodoViewModel>();
    final authVm  = context.read<AuthViewModel>();
    final email   = authVm.currentUser?.email ?? '';
    todoVm.clearError();

    bool ok;
    if (_isEdit) {
      ok = await todoVm.updateTodo(
        ownerEmail:       email,
        existing:         widget.existing!,
        newTitle:         _titleCtrl.text,
        newNotePlaintext: _noteCtrl.text,
        dueDate:          _dueDate,
        priority:         _priority,
      );
    } else {
      ok = await todoVm.addTodo(
        ownerEmail:    email,
        title:         _titleCtrl.text,
        notePlaintext: _noteCtrl.text,
        dueDate:       _dueDate,
        priority:      _priority,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(todoVm.error ?? 'Save failed')),
      );
    }
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate:    DateTime.now(),
      lastDate:     DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<TodoViewModel>();
    final cs     = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand:         false,
        initialChildSize: 0.65,
        minChildSize:     0.4,
        maxChildSize:     0.92,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color:        Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ───────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width:  40,
                height: 4,
                decoration: BoxDecoration(
                  color:        isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),

              // ── Header ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _isEdit ? Icons.edit_note_rounded : Icons.add_task_rounded,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEdit ? 'Edit Todo' : 'New Todo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon:     const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Scrollable form ───────────────────────────────────
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Title
                    TextField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText:  'Title *',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Note
                    TextField(
                      controller: _noteCtrl,
                      maxLines:   4,
                      decoration: const InputDecoration(
                        labelText:     'Note (encrypted)',
                        alignLabelWithHint: true,
                        prefixIcon:    Padding(
                          padding: EdgeInsets.only(bottom: 64),
                          child:   Icon(Icons.notes_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Priority selector
                    Text(
                      'Priority',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: TodoViewModel.priorities.map((p) {
                        final selected = _priority == p;
                        final color = p == 'High'
                            ? Colors.red
                            : p == 'Medium'
                                ? Colors.orange
                                : Colors.green;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: ChoiceChip(
                              label:    Text(p),
                              selected: selected,
                              selectedColor:     color.withOpacity(0.20),
                              checkmarkColor:    color,
                              side:              BorderSide(
                                color: selected ? color : Colors.transparent,
                              ),
                              labelStyle: TextStyle(
                                color:      selected ? color : null,
                                fontWeight: selected ? FontWeight.w700 : null,
                              ),
                              onSelected: (_) => setState(() => _priority = p),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Due date
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_rounded, color: cs.secondary),
                      title: Text(
                        _dueDate != null
                            ? 'Due: ${DateFormat('EEEE, MMM d y').format(_dueDate!)}'
                            : 'Set due date (optional)',
                      ),
                      trailing: _dueDate != null
                          ? IconButton(
                              icon:     const Icon(Icons.clear_rounded),
                              onPressed: () => setState(() => _dueDate = null),
                            )
                          : const Icon(Icons.chevron_right_rounded),
                      onTap: _pickDue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: vm.isBusy ? null : _save,
                        icon:      Icon(_isEdit ? Icons.save_outlined : Icons.add_rounded),
                        label:     vm.isBusy
                            ? const SizedBox(
                                height: 18, width: 18,
                                child:  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isEdit ? 'Save Changes' : 'Add Todo'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
