// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project.dart';
import '../models/client.dart';
import '../services/local_db.dart';



final projectsProvider = FutureProvider<List<Project>>((ref) async {
  return LocalDb.instance.getAllProjects();
});

final clientsDropdownProvider = FutureProvider<List<Client>>((ref) async {
  return LocalDb.instance.getAllClients();
});

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: projectsAsync.when(
        data: (projects) => ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return FutureBuilder<Client>(
              future: LocalDb.instance.getAllClients().then(
                (list) => list.firstWhere((c) => c.id == project.clientId),
              ),
              builder: (context, snapshot) {
                final clientName = snapshot.data?.name ?? '';
                return ListTile(
                  title: Text(project.title),
                  subtitle: Text(
                    'Client: $clientName\n'
                    'Due: ${project.dueDate.toLocal().toIso8601String().split('T').first}',
                  ),
                  isThreeLine: true,
                  onTap: () => _showEditDialog(context, ref, project),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await LocalDb.instance.deleteProject(project.id!);
                      ref.refresh(projectsProvider);
                    },
                  ),
                );
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    ref.refresh(clientsDropdownProvider);
    final titleController = TextEditingController();
    int? selectedClientId;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final clientsAsync = ref.watch(clientsDropdownProvider);
            return AlertDialog(
              title: const Text('Add Project'),
              content: clientsAsync.when(
                data: (clients) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Client'),
                      hint: const Text('Select client'),
                      value: selectedClientId,
                      items: clients
                          .map((c) => DropdownMenuItem<int>(
                                value: c.id!,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (id) => setState(() => selectedClientId = id),
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Due: ${selectedDate.toLocal().toIso8601String().split('T').first}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => selectedDate = d);
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedClientId != null && titleController.text.trim().isNotEmpty) {
                      await LocalDb.instance.addProject(
                        Project(
                          clientId: selectedClientId!,
                          title: titleController.text.trim(),
                          dueDate: selectedDate,
                        ),
                      );
                      ref.refresh(projectsProvider);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    ref.refresh(clientsDropdownProvider);
    final titleController = TextEditingController(text: project.title);
    int selectedClientId = project.clientId;
    DateTime selectedDate = project.dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final clientsAsync = ref.watch(clientsDropdownProvider);
            return AlertDialog(
              title: const Text('Edit Project'),
              content: clientsAsync.when(
                data: (clients) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Client'),
                      value: selectedClientId,
                      items: clients
                          .map((c) => DropdownMenuItem<int>(
                                value: c.id!,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (id) => setState(() => selectedClientId = id!),
                    ),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Due: ${selectedDate.toLocal().toIso8601String().split('T').first}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setState(() => selectedDate = d);
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 50,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isNotEmpty) {
                      await LocalDb.instance.updateProject(
                        Project(
                          id: project.id,
                          clientId: selectedClientId,
                          title: titleController.text.trim(),
                          dueDate: selectedDate,
                        ),
                      );
                      ref.refresh(projectsProvider);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}