import 'package:cloud_firestore/cloud_firestore.dart';

/// User data model representing a user in the application
class User {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  /// Creates a new User instance
  User({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a User instance from a Firestore DocumentSnapshot
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Creates a User instance from a Firestore Map data
  factory User.fromMap(Map<String, dynamic> data, String documentId) {
    return User(
      uid: documentId,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// Converts the User instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Creates a copy of the User with updated fields
  User copyWith({
    String? uid,
    String? email,
    String? username,
    String? displayName,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the User instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Creates a User instance from a Map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      createdAt: json['createdAt'] is Timestamp 
          ? json['createdAt'] 
          : Timestamp.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: json['updatedAt'] is Timestamp 
          ? json['updatedAt'] 
          : Timestamp.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
    );
  }

  /// Converts the User instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Returns a string representation of the User
  @override
  String toString() {
    return 'User(uid: $uid, email: $email, username: $username, displayName: $displayName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Equality operator for comparing User instances
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.uid == uid &&
        other.email == email &&
        other.username == username &&
        other.displayName == displayName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  /// Hash code implementation
  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        username.hashCode ^
        displayName.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  /// Helper method to get formatted creation date
  String get formattedCreatedAt {
    final date = createdAt.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Helper method to get formatted update date
  String get formattedUpdatedAt {
    final date = updatedAt.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Helper method to check if user was created recently (within last 7 days)
  bool get isNewUser {
    final now = DateTime.now();
    final created = createdAt.toDate();
    return now.difference(created).inDays <= 7;
  }

  /// Helper method to get user initials for avatar
  String get initials {
    if (displayName.isNotEmpty) {
      final names = displayName.split(' ');
      if (names.length > 1) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return displayName.substring(0, 1).toUpperCase();
    }
    return username.substring(0, 1).toUpperCase();
  }
}

/// Firestore Service for User operations
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of all users from Firestore
  Stream<List<User>> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('username') // Order by username alphabetically
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromFirestore(doc))
            .toList());
  }

  /// Get all users once (non-stream)
  Future<List<User>> getUsers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('username')
          .get();
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  /// Search users by username
  Stream<List<User>> searchUsers(String query) {
    if (query.isEmpty) {
      return getUsersStream();
    }
    
    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .orderBy('username')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromFirestore(doc))
            .toList());
  }

  /// Get a specific user by UID
  Future<User?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      throw Exception('Failed to load user: $e');
    }
  }

  /// Get a specific user by username
  Future<User?> getUserByUsername(String username) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return User.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by username: $e');
      throw Exception('Failed to load user: $e');
    }
  }

  /// Get a specific user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return User.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      throw Exception('Failed to load user: $e');
    }
  }

  /// Create a new user
  Future<void> createUser(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore());
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  /// Update an existing user
  Future<void> updateUser(User user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: Timestamp.now());
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(updatedUser.toFirestore());
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete a user and all their subcollections
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user's inventory subcollection
      await _deleteSubcollection('users/$userId/inventory');
      
      // Delete user's saved_recipes subcollection
      await _deleteSubcollection('users/$userId/saved_recipes');
      
      // Finally delete the user document
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Helper method to delete all documents in a subcollection
  Future<void> _deleteSubcollection(String collectionPath) async {
    try {
      final snapshot = await _firestore.collection(collectionPath).get();
      
      // Delete all documents in the subcollection
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error deleting subcollection $collectionPath: $e');
      // Don't throw here, continue with user deletion
    }
  }

  /// Check if username already exists
  Future<bool> usernameExists(String username) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      throw Exception('Failed to check username: $e');
    }
  }

  /// Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      throw Exception('Failed to check email: $e');
    }
  }
}

/// Extension methods for List<User>
extension UserListExtensions on List<User> {
  /// Sort users by username alphabetically
  List<User> sortByUsername({bool ascending = true}) {
    sort((a, b) => ascending
        ? a.username.compareTo(b.username)
        : b.username.compareTo(a.username));
    return this;
  }

  /// Sort users by creation date
  List<User> sortByCreationDate({bool ascending = true}) {
    sort((a, b) => ascending
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    return this;
  }

  /// Filter users by search query
  List<User> search(String query) {
    if (query.isEmpty) return this;
    final lowerQuery = query.toLowerCase();
    return where((user) =>
        user.username.toLowerCase().contains(lowerQuery) ||
        user.displayName.toLowerCase().contains(lowerQuery) ||
        user.email.toLowerCase().contains(lowerQuery)).toList();
  }

  /// Get user by UID
  User? getByUid(String uid) {
    try {
      return firstWhere((user) => user.uid == uid);
    } catch (e) {
      return null;
    }
  }

  /// Get user by username
  User? getByUsername(String username) {
    try {
      return firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }

  /// Get user by email
  User? getByEmail(String email) {
    try {
      return firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }
}