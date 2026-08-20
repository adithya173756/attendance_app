import '../models/note.dart';

class NoteService {
  static final List<Note> notes = [];

  static void add(Note note) {
    notes.add(note);
  }

  static void delete(Note note) {
    notes.remove(note);
  }

  static List<Note> subjectNotes(String subject) {
    return notes.where((e) => e.subject == subject).toList();
  }
}
