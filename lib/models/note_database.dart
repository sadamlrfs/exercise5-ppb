import 'package:crud_local_database_app/models/note.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class NoteDatabase extends ChangeNotifier {
  static late Isar isar;
  static bool _useMemoryStore = false;
  static int _nextWebId = 1;
  static final List<Note> _webNotes = [];

  // INIT
  static Future<void> initialize() async {
    if (kIsWeb) {
      _useMemoryStore = true;
      await _loadFromPrefs();
      return;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open([NoteSchema], directory: dir.path);
    }
  }

  // Web persistence helper - load
  static Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString('web_notes');
    if (notesJson != null) {
      final List<dynamic> decoded = jsonDecode(notesJson);
      _webNotes.clear();
      for (var item in decoded) {
        final note = Note()
          ..id = item['id']
          ..text = item['text'];
        _webNotes.add(note);
        if (note.id >= _nextWebId) _nextWebId = note.id + 1;
      }
    }
  }

  // Web persistence helper - save
  static Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> toSave = _webNotes
        .map((note) => {'id': note.id, 'text': note.text})
        .toList();
    await prefs.setString('web_notes', jsonEncode(toSave));
  }

  // list
  final List<Note> currentNotes = [];

  // create
  Future<void> addNote(String textFromUser) async {
    if (_useMemoryStore) {
      final newNote = Note()
        ..id = _nextWebId++
        ..text = textFromUser;
      _webNotes.add(newNote);
      await _saveToPrefs();
      await fetchNotes();
      return;
    }

    // create a new object
    final newNote = Note()..text = textFromUser;

    // save to db
    await isar.writeTxn(() => isar.notes.put(newNote));

    // re-read from db
    fetchNotes();
  }

  // read
  Future<void> fetchNotes() async {
    List<Note> fetchedNotes;

    if (_useMemoryStore) {
      fetchedNotes = List<Note>.from(_webNotes);
    } else {
      fetchedNotes = await isar.notes.where().findAll();
    }

    currentNotes.clear();
    currentNotes.addAll(fetchedNotes);
    notifyListeners();
  }

  // update
  Future<void> updateNote(int id, String newText) async {
    if (_useMemoryStore) {
      final index = _webNotes.indexWhere((note) => note.id == id);
      if (index != -1) {
        _webNotes[index].text = newText;
        await _saveToPrefs();
      }
      await fetchNotes();
      return;
    }

    final existingNote = await isar.notes.get(id);
    if (existingNote != null) {
      existingNote.text = newText;
      await isar.writeTxn(() => isar.notes.put(existingNote));
      await fetchNotes();
    }
  }

  // delete
  Future<void> deleteNote(int id) async {
    if (_useMemoryStore) {
      _webNotes.removeWhere((note) => note.id == id);
      await _saveToPrefs();
      await fetchNotes();
      return;
    }

    await isar.writeTxn(() => isar.notes.delete(id));
    await fetchNotes();
  }
}
