import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NotePage extends StatefulWidget {
  const NotePage({Key? key}) : super(key: key);

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final _noteController = TextEditingController();
  final DatabaseReference _dbref = FirebaseDatabase.instance.ref("notes");

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isNotEmpty) {
      final note = {
        'content': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _dbref.push().set(note).then((_) {
        print("Note added to Firebase!");
      }).catchError((error) {
        print("Error adding note: $error");
      });

      _noteController.clear();
    } else {
      print("Note is empty, not adding.");
    }
  }

  void _deleteNote(String key) {
    _dbref.child(key).remove().then((_) {
      print("Note deleted: $key");
    }).catchError((e) {
      print("Delete error: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Enter note',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addNote,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _dbref.orderByChild("timestamp").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final notesMap = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map);

                  final notesList = notesMap.entries.toList()
                    ..sort((a, b) =>
                        b.value['timestamp'].compareTo(a.value['timestamp']));

                  return ListView.builder(
                    itemCount: notesList.length,
                    itemBuilder: (context, index) {
                      final entry = notesList[index];
                      return ListTile(
                        title: Text(entry.value['content']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNote(entry.key),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text("No notes yet."));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
