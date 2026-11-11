import 'dart:async';
import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String kPocketBaseBaseUrl = 'https://izeny.zenydesk.com';

class PBClient {
  static final PBClient instance = PBClient._internal();
  PBClient._internal();

  String baseUrl = kPocketBaseBaseUrl;
  String? token;
  Map<String, dynamic>? currentRecord;

  final StreamController<User?> _authController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authController.stream;

  Future<void> init() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      token = prefs.getString('pb_token');
      String? rec = prefs.getString('pb_record');
      if (rec != null && rec.isNotEmpty) {
        currentRecord = jsonDecode(rec) as Map<String, dynamic>;
        _authController.add(User._fromRecord(currentRecord!));
      } else {
        _authController.add(null);
      }
    } catch (e) {
      debugPrint('PB init error: $e');
    }
  }

  Future<void> saveAuth(String tok, Map<String, dynamic> rec) async {
    token = tok;
    currentRecord = rec;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('pb_token', tok);
    await prefs.setString('pb_record', jsonEncode(rec));
    _authController.add(User._fromRecord(rec));
  }

  Future<void> clearAuth() async {
    token = null;
    currentRecord = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('pb_token');
    await prefs.remove('pb_record');
    _authController.add(null);
  }

  Map<String, String> get headers {
    Map<String, String> h = {
      'Accept': 'application/json',
    };
    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = token!;
    }
    return h;
  }
}

// ----------------------------------------------------
// Firebase Core replacement
// ----------------------------------------------------
class Firebase {
  static Future<void> initializeApp() async {
    await PBClient.instance.init();
  }
}

// ----------------------------------------------------
// Timestamp replacement
// ----------------------------------------------------
class Timestamp implements Comparable<Timestamp> {
  final DateTime _date;
  Timestamp(this._date);

  factory Timestamp.now() => Timestamp(DateTime.now());
  factory Timestamp.fromDate(DateTime d) => Timestamp(d);

  DateTime toDate() => _date;
  int get millisecondsSinceEpoch => _date.millisecondsSinceEpoch;

  @override
  int compareTo(Timestamp other) => _date.compareTo(other._date);

  @override
  String toString() => _date.toIso8601String();

  dynamic toJson() => _date.toIso8601String();
}

// ----------------------------------------------------
// User & Auth
// ----------------------------------------------------
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  User({required this.uid, this.email, this.displayName, this.photoURL});

  factory User._fromRecord(Map<String, dynamic> r) {
    String id = r['id'] ?? '';
    String? av = r['avatar'];
    String? pUrl;
    if (av != null && av.isNotEmpty) {
      pUrl = '${PBClient.instance.baseUrl}/api/files/users/$id/$av';
    }
    return User(
      uid: id,
      email: r['email'],
      displayName: r['name'] ?? r['username'],
      photoURL: pUrl,
    );
  }
}

class UserCredential {
  final User? user;
  UserCredential({this.user});
}

class FirebaseAuth {
  static final FirebaseAuth instance = FirebaseAuth._();
  FirebaseAuth._();

  User? get currentUser {
    if (PBClient.instance.currentRecord != null) {
      return User._fromRecord(PBClient.instance.currentRecord!);
    }
    return null;
  }

  Stream<User?> authStateChanges() => PBClient.instance.authStateChanges;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/users/auth-with-password');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identity': email.trim(), 'password': password}),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final tok = data['token'] as String;
      final rec = data['record'] as Map<String, dynamic>;
      await PBClient.instance.saveAuth(tok, rec);
      return UserCredential(user: User._fromRecord(rec));
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['message'] ?? 'Credenciais inválidas');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/users/records');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'passwordConfirm': password,
        'name': email.split('@').first,
        'username': email.split('@').first.replaceAll('.', '_'),
        'verified': true,
      }),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      // Auto login after registration
      return await signInWithEmailAndPassword(email: email, password: password);
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['message'] ?? 'Falha ao registrar usuário');
    }
  }

  Future<void> signOut() async {
    await PBClient.instance.clearAuth();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/users/request-password-reset');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
  }
}

// ----------------------------------------------------
// Firestore Replacement Classes
// ----------------------------------------------------
class DocumentSnapshot {
  final String id;
  final Map<String, dynamic> _data;
  final bool exists;

  DocumentSnapshot(this.id, this._data, {this.exists = true});

  Map<String, dynamic> data() => Map<String, dynamic>.from(_data);

  dynamic get(String field) => _data[field];

  dynamic operator [](String field) => _data[field];
}

class QueryDocumentSnapshot extends DocumentSnapshot {
  QueryDocumentSnapshot(String id, Map<String, dynamic> data) : super(id, data, exists: true);
}

class QuerySnapshot {
  final List<DocumentSnapshot> docs;
  QuerySnapshot(this.docs);
}

class DocumentReference {
  final String id;
  final String collectionName;
  DocumentReference(this.collectionName, this.id);

  Future<DocumentSnapshot> get() async {
    try {
      final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records/$id');
      final resp = await http.get(url, headers: PBClient.instance.headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return DocumentSnapshot(id, _normalizeData(data), exists: true);
      }
    } catch (e) {
      debugPrint('Doc get error: $e');
    }
    return DocumentSnapshot(id, {}, exists: false);
  }

  Future<void> set(Map<String, dynamic> data) async {
    // If it exists, update; if not, create
    try {
      final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records/$id');
      final resp = await http.patch(
        url,
        headers: {...PBClient.instance.headers, 'Content-Type': 'application/json'},
        body: jsonEncode(_cleanData(data)),
      );
      if (resp.statusCode == 404) {
        // create with this ID
        final createUrl = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records');
        final cData = _cleanData(data);
        cData['id'] = id;
        await http.post(
          createUrl,
          headers: {...PBClient.instance.headers, 'Content-Type': 'application/json'},
          body: jsonEncode(cData),
        );
      }
    } catch (e) {
      debugPrint('Doc set error: $e');
    }
  }

  Future<void> update(Map<String, dynamic> data) async {
    final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records/$id');
    await http.patch(
      url,
      headers: {...PBClient.instance.headers, 'Content-Type': 'application/json'},
      body: jsonEncode(_cleanData(data)),
    );
  }

  Future<void> delete() async {
    final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records/$id');
    await http.delete(url, headers: PBClient.instance.headers);
  }

  CollectionReference collection(String subCol) {
    return CollectionReference(subCol);
  }

  Stream<DocumentSnapshot> snapshots() {
    late StreamController<DocumentSnapshot> controller;
    Timer? timer;
    controller = StreamController<DocumentSnapshot>(
      onListen: () {
        get().then((snap) {
          if (!controller.isClosed) controller.add(snap);
        });
        timer = Timer.periodic(const Duration(seconds: 4), (_) async {
          if (!controller.isClosed) {
            final snap = await get();
            controller.add(snap);
          }
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );
    return controller.stream;
  }
}

class Query {
  final String collectionName;
  String? sortField;
  bool isDescending = false;
  int limitCount = 30;
  final List<String> filters = [];

  Query(this.collectionName);

  Query orderBy(String field, {bool descending = false}) {
    sortField = field;
    isDescending = descending;
    return this;
  }

  Query limit(int n) {
    limitCount = n;
    return this;
  }

  Query where(String field, {dynamic isEqualTo, dynamic arrayContains}) {
    if (isEqualTo != null) {
      filters.add('$field = "$isEqualTo"');
    }
    return this;
  }

  Future<QuerySnapshot> get() async {
    try {
      final qParams = <String, String>{
        'page': '1',
        'perPage': limitCount.toString(),
      };
      if (sortField != null) {
        String s = sortField == 'timestamp' ? 'created' : sortField!;
        qParams['sort'] = isDescending ? '-$s' : s;
      }
      if (filters.isNotEmpty) {
        qParams['filter'] = filters.join(' && ');
      }

      final uri = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records')
          .replace(queryParameters: qParams);

      final resp = await http.get(uri, headers: PBClient.instance.headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>?) ?? [];
        List<DocumentSnapshot> docs = items.map((it) {
          final m = it as Map<String, dynamic>;
          return DocumentSnapshot(m['id'], _normalizeData(m), exists: true);
        }).toList();
        return QuerySnapshot(docs);
      }
    } catch (e) {
      debugPrint('Query get error: $e');
    }
    return QuerySnapshot([]);
  }

  Stream<QuerySnapshot> snapshots() {
    late StreamController<QuerySnapshot> controller;
    Timer? timer;
    controller = StreamController<QuerySnapshot>(
      onListen: () {
        get().then((snap) {
          if (!controller.isClosed) controller.add(snap);
        });
        timer = Timer.periodic(const Duration(seconds: 4), (_) async {
          if (!controller.isClosed) {
            final snap = await get();
            controller.add(snap);
          }
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );
    return controller.stream;
  }
}

class CollectionReference extends Query {
  CollectionReference(String name) : super(name);

  DocumentReference doc([String? docId]) {
    String id = docId ?? const Uuid().v4().replaceAll('-', '').substring(0, 15);
    return DocumentReference(collectionName, id);
  }

  Future<DocumentReference> add(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records');
      final resp = await http.post(
        url,
        headers: {...PBClient.instance.headers, 'Content-Type': 'application/json'},
        body: jsonEncode(_cleanData(data)),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final rec = jsonDecode(resp.body) as Map<String, dynamic>;
        return DocumentReference(collectionName, rec['id']);
      }
    } catch (e) {
      debugPrint('Collection add error: $e');
    }
    return DocumentReference(collectionName, const Uuid().v4().substring(0, 15));
  }
}

class FirebaseFirestore {
  static final FirebaseFirestore instance = FirebaseFirestore._();
  FirebaseFirestore._();

  CollectionReference collection(String name) => CollectionReference(name);
}

// ----------------------------------------------------
// Storage Replacement Classes
// ----------------------------------------------------
class FirebaseStorage {
  static final FirebaseStorage instance = FirebaseStorage._();
  FirebaseStorage._();

  Reference ref([String? path]) => Reference(path ?? '');
}

class Reference {
  final String path;
  Reference(this.path);

  Reference child(String childPath) {
    return Reference(path.isEmpty ? childPath : '$path/$childPath');
  }

  UploadTask putFile(dynamic file) {
    return UploadTask(_upload(file));
  }

  Future<String> _upload(dynamic file) async {
    // Post to storage collection or posts collection
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${PBClient.instance.baseUrl}/api/collections/posts/records'),
      );
      request.headers.addAll(PBClient.instance.headers);
      request.fields['description'] = 'Upload';
      request.fields['owner'] = PBClient.instance.currentRecord?['id'] ?? '';

      if (file is File) {
        request.files.add(await http.MultipartFile.fromPath('media', file.path));
      }

      var res = await request.send();
      var respStr = await res.stream.bytesToString();
      if (res.statusCode == 200 || res.statusCode == 201) {
        var d = jsonDecode(respStr);
        String id = d['id'];
        String fn = (d['media'] is List && (d['media'] as List).isNotEmpty)
            ? (d['media'] as List).first
            : d['media'] ?? '';
        return '${PBClient.instance.baseUrl}/api/files/posts/$id/$fn';
      }
    } catch (e) {
      debugPrint('File upload error: $e');
    }
    return '';
  }

  Future<String> getDownloadURL() async {
    return '${PBClient.instance.baseUrl}/api/files/posts/$path';
  }
}

class UploadTask {
  final Future<String> _future;
  UploadTask(this._future);

  Future<void> whenComplete(Function() action) async {
    await _future;
    action();
  }
}

// ----------------------------------------------------
// Helpers
// ----------------------------------------------------
Map<String, dynamic> _cleanData(Map<String, dynamic> input) {
  final out = <String, dynamic>{};
  input.forEach((key, val) {
    if (val is Timestamp) {
      out[key] = val.toDate().toIso8601String();
    } else {
      out[key] = val;
    }
  });
  return out;
}

Map<String, dynamic> _normalizeData(Map<String, dynamic> input) {
  final out = Map<String, dynamic>.from(input);
  if (out['created'] != null) {
    try {
      out['timestamp'] = Timestamp(DateTime.parse(out['created']));
      out['time'] = out['timestamp'];
    } catch (_) {}
  }
  if (out['media'] != null && out['media'] is List && (out['media'] as List).isNotEmpty) {
    String fn = (out['media'] as List).first;
    out['mediaUrl'] = '${PBClient.instance.baseUrl}/api/files/${input['collectionName'] ?? 'posts'}/${input['id']}/$fn';
  }
  if (out['avatar'] != null && (out['avatar'] as String).isNotEmpty) {
    out['photoUrl'] = '${PBClient.instance.baseUrl}/api/files/users/${input['id']}/${out['avatar']}';
  }
  return out;
}
