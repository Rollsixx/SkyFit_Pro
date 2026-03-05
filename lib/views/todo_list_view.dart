import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo_model.dart';
import '../utils/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/todo_viewmodel.dart';
import 'login_view.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthViewModel>();
    final todoVM = context.read<TodoViewModel>();
    final user = auth.currentUser;
    if (user != null) {
      todoVM.loadTodos(user.email);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showAddDialog() async {
    final title = TextEditingController();
    final note = TextEditingController();
    final todoVM = context.read<TodoViewModel>();
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;

    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New To-Do'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Sensitive Note (Encrypted)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final success = await todoVM.addTodo(
      ownerEmail: user.email,
      title: title.text,
      notePlaintext: note.text,
    );

    if (!mounted) return;
    if (!success) {
      _snack(todoVM.error ?? 'Failed to add todo');
    }
  }

  Future<void> _showEditDialog(TodoModel todo) async {
    final todoVM = context.read<TodoViewModel>();
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;
    if (user == null) return;

    final title = TextEditingController(text: todo.title);
    final note = TextEditingController(text: todoVM.decryptNoteForUi(todo));

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit To-Do'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Sensitive Note (Encrypted)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Update')),
        ],
      ),
    );

    if (ok != true) return;

    final success = await todoVM.updateTodo(
      ownerEmail: user.email,
      existing: todo,
      newTitle: title.text,
      newNotePlaintext: note.text,
    );

    if (!mounted) return;
    if (!success) {
      _snack(todoVM.error ?? 'Failed to update todo');
    }
  }

  Future<void> _confirmDelete(TodoModel todo) async {
    final todoVM = context.read<TodoViewModel>();
    final auth = context.read<AuthViewModel>();
    final user = auth.currentUser;
    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete To-Do?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await todoVM.deleteTodo(ownerEmail: user.email, todoId: todo.id);
  }

  Future<void> _logout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('Are you sure you want to log out of CipherTask?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  await context.read<AuthViewModel>().logout();
  if (!mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginView()),
    (_) => false,
  );
}

  Widget _todoTile(TodoModel todo, String note) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Constants.dsTeal.withOpacity(0.25)),
      ),
      child: ListTile(
        onTap: () => _showEditDialog(todo),
        leading: Checkbox(
          value: todo.completed,
          onChanged: (_) {
            final auth = context.read<AuthViewModel>();
            final user = auth.currentUser;
            if (user == null) return;
            context.read<TodoViewModel>().toggleCompleted(ownerEmail: user.email, todo: todo);
          },
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            decoration: todo.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            note.isEmpty ? '(No note)' : note,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white70),
          onPressed: () => _confirmDelete(todo),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final todoVM = context.watch<TodoViewModel>();
    final user = auth.currentUser;

    if (user == null) {
      // Safety fallback
      return const LoginView();
    }

    final todos = todoVM.todos;

    return Scaffold(
      backgroundColor: Constants.dsBlack,
      appBar: AppBar(
        backgroundColor: Constants.dsBlack,
        foregroundColor: Colors.white,
        title: const Text('CipherTask • To-Dos'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: todoVM.isBusy ? null : _showAddDialog,
        backgroundColor: Constants.dsCrimson,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Constants.dsCrimson.withOpacity(0.30),
                      Constants.dsTeal.withOpacity(0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Signed in as: ${user.email}\nNotes are AES-256-GCM encrypted • DB is encrypted • Auto-lock: ${Constants.inactivityTimeoutSeconds}s',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: user.biometricsEnabled,
                      onChanged: (v) async {
                        await auth.setBiometricsEnabled(v);
                        if (auth.error != null) _snack(auth.error!);
                      },
                      activeColor: Constants.dsTeal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: todos.isEmpty
                    ? Center(
                        child: Text(
                          'No to-dos yet.\nTap + to add one.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: todos.length,
                        itemBuilder: (_, i) {
                          final t = todos[i];
                          final note = todoVM.decryptNoteForUi(t);
                          return _todoTile(t, note);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}