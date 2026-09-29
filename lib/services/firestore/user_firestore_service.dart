import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_constants.dart';
import '../../models/user_model.dart';
import 'firestore_service.dart';

/// Firestore operations for the [users] collection.
class UserFirestoreService {
  UserFirestoreService(this._fs);
  final FirestoreService _fs;

  static const String _col = FirestoreConstants.usersCollection;

  Future<void> saveUser(UserModel user) =>
      _fs.setDoc(_col, user.uid, user.toFirestore());

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _fs.getDoc(_col, uid);
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      _fs.updateDoc(_col, uid, {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<bool> hasAnyUsers() async {
    try {
      final snap = await _fs.queryCollection(_col, limit: 1);
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Stream<List<UserModel>> streamPendingUsers() {
    return _fs.streamCollection(_col, whereEqual: {'active': false}).map(
      (snap) => snap.docs.map(UserModel.fromFirestore).toList(),
    );
  }

  Future<void> activateUser(String uid) =>
      _fs.updateDoc(_col, uid, {'active': true});

  Future<void> deactivateUser(String uid) =>
      _fs.updateDoc(_col, uid, {'active': false});

  Future<void> deleteUser(String uid) => _fs.deleteDoc(_col, uid);

  Stream<List<UserModel>> streamAllStaff() {
    return _fs.db.collection(_col).snapshots().map((snap) => snap.docs
        .map(UserModel.fromFirestore)
        .where((u) => u.role != 'patient')
        .toList());
  }

  Stream<UserModel?> streamUser(String uid) =>
      _fs.streamDoc(_col, uid).map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });
}
