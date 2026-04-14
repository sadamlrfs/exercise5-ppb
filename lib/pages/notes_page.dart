import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_local_database_app/services/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final titleTextController = TextEditingController();
  final contentTextController = TextEditingController();
  final tglTextController = TextEditingController();
  final labelTextController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  void logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  void openNoteBox(
      {String? docId,
      String? existingTitle,
      String? existingContent,
      String? existingTgl,
      String? existingLabel}) {
    if (docId != null) {
      titleTextController.text = existingTitle ?? '';
      contentTextController.text = existingContent ?? '';
      tglTextController.text = existingTgl ?? '';
      labelTextController.text = existingLabel ?? '';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? "Create new Note" : "Edit Note"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Title"),
                  controller: titleTextController,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: "Content"),
                  controller: contentTextController,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Tanggal",
                    hintText: "e.g. 2026-04-14",
                  ),
                  controller: tglTextController,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Label",
                    hintText: "e.g. Work, Personal",
                  ),
                  controller: labelTextController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                titleTextController.clear();
                contentTextController.clear();
                tglTextController.clear();
                labelTextController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            MaterialButton(
              onPressed: () {
                if (docId == null) {
                  firestoreService.addNote(
                    titleTextController.text,
                    contentTextController.text,
                    tglTextController.text,
                    labelTextController.text,
                  );
                } else {
                  firestoreService.updateNote(
                    docId,
                    titleTextController.text,
                    contentTextController.text,
                    tglTextController.text,
                    labelTextController.text,
                  );
                }
                titleTextController.clear();
                contentTextController.clear();
                tglTextController.clear();
                labelTextController.clear();
                Navigator.pop(context);
              },
              child: Text(docId == null ? "Create" : "Update"),
            ),
          ],
        );
      },
    ).then((_) {
      titleTextController.clear();
      contentTextController.clear();
      tglTextController.clear();
      labelTextController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openNoteBox,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.hasData) {
            List notesList = snapshot.data!.docs;

            // sort client-side by createdAt descending
            notesList.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

            if (notesList.isEmpty) {
              return const Center(child: Text("No notes yet"));
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: notesList.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = notesList[index];
                  String docId = document.id;

                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  String noteTitle = data['title'] ?? '';
                  String noteContent = data['content'] ?? '';
                  String noteTgl = data['tgl'] ?? '';
                  String noteLabel = data['label'] ?? '';

                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  noteTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                iconSize: 20,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    openNoteBox(
                                      docId: docId,
                                      existingTitle: noteTitle,
                                      existingContent: noteContent,
                                      existingTgl: noteTgl,
                                      existingLabel: noteLabel,
                                    );
                                  } else if (value == 'delete') {
                                    firestoreService.deleteNote(docId);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              noteContent,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Divider(),
                          if (noteTgl.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    noteTgl,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (noteLabel.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.label, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    noteLabel,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
