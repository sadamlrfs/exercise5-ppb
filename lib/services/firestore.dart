import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final CollectionReference notes =
      FirebaseFirestore.instance.collection('notes');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // create new note
  Future<void> addNote(String title, String content, String tgl, String label) {
    return notes.add({
      'uid': _uid,
      'title': title,
      'content': content,
      'tgl': tgl,
      'label': label,
      'createdAt': Timestamp.now(),
    });
  }

  // fetch all notes for current user
  Stream<QuerySnapshot> getNotes() {
    return notes
        .where('uid', isEqualTo: _uid)
        .snapshots();
  }

  // update note
  Future<void> updateNote(
      String id, String title, String content, String tgl, String label) {
    return notes.doc(id).update({
      'title': title,
      'content': content,
      'tgl': tgl,
      'label': label,
      'createdAt': Timestamp.now(),
    });
  }

  // delete note
  Future<void> deleteNote(String id) {
    return notes.doc(id).delete();
  }
}
