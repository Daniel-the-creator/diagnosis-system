import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/firebase_error_handler.dart';

/// Base Firestore service providing generic CRUD helpers.
/// All collection-specific services extend or compose this.
class FirestoreService {
  FirestoreService(this._db);
  final FirebaseFirestore _db;

  FirebaseFirestore get db => _db;

  // ── Document helpers ───────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _db.collection(path);

  DocumentReference<Map<String, dynamic>> doc(String path) => _db.doc(path);

  /// Sets (creates or overwrites) a document.
  Future<void> setDoc(
    String collectionPath,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _db
          .collection(collectionPath)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handleFirestoreError(e);
    }
  }

  /// Updates specific fields of an existing document.
  Future<void> updateDoc(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _db.collection(collectionPath).doc(docId).update(data);
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handleFirestoreError(e);
    }
  }

  /// Deletes a document.
  Future<void> deleteDoc(String collectionPath, String docId) async {
    try {
      await _db.collection(collectionPath).doc(docId).delete();
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handleFirestoreError(e);
    }
  }

  /// Fetches a single document snapshot.
  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
    String collectionPath,
    String docId,
  ) async {
    try {
      return await _db.collection(collectionPath).doc(docId).get();
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handleFirestoreError(e);
    }
  }

  /// Queries a collection with optional filters, ordering, and limit.
  Future<QuerySnapshot<Map<String, dynamic>>> queryCollection(
    String collectionPath, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db.collection(collectionPath);
      if (filters != null) {
        for (final f in filters) {
          query = query.where(f.field, isEqualTo: f.isEqualTo,
              isGreaterThanOrEqualTo: f.isGreaterThanOrEqualTo,
              whereIn: f.whereIn);
        }
      }
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      return await query.get();
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handleFirestoreError(e);
    }
  }

  /// Returns a real-time stream of a collection query.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collectionPath, {
    Map<String, dynamic>? whereEqual,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (whereEqual != null) {
      whereEqual.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots();
  }

  /// Returns a real-time stream for a single document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamDoc(
    String collectionPath,
    String docId,
  ) =>
      _db.collection(collectionPath).doc(docId).snapshots();

  /// Generates a new document ID.
  String generateId(String collectionPath) =>
      _db.collection(collectionPath).doc().id;

  /// Runs a Firestore transaction.
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction txn) handler,
  ) async {
    try {
      return await _db.runTransaction(handler);
    } on FirebaseException catch (e) {
      throw FirebaseErrorHandler.handleFirestoreError(e);
    }
  }
}

/// Simple filter descriptor for query building.
class QueryFilter {
  final String field;
  final dynamic isEqualTo;
  final dynamic isGreaterThanOrEqualTo;
  final List<dynamic>? whereIn;

  const QueryFilter({
    required this.field,
    this.isEqualTo,
    this.isGreaterThanOrEqualTo,
    this.whereIn,
  });
}
