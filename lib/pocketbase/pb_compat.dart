import 'dart:async';
import 'dart:convert';
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

  static Future<String> uploadBytes(
    List<int> bytes,
    String fileName, {
    String collection = 'messages',
    String field = 'media',
    Map<String, String>? extraFields,
  }) async {
    try {
      final uri = Uri.parse('${instance.baseUrl}/api/collections/$collection/records');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(instance.headers);
      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }
      request.files.add(http.MultipartFile.fromBytes(field, bytes, filename: fileName));

      final res = await request.send();
      final respStr = await res.stream.bytesToString();
      if (res.statusCode == 200 || res.statusCode == 201) {
        final d = jsonDecode(respStr) as Map<String, dynamic>;
        final id = d['id'];
        final fn = (d[field] is List && (d[field] as List).isNotEmpty)
            ? (d[field] as List).first
            : (d[field] ?? '');
        return '${instance.baseUrl}/api/files/$collection/$id/$fn';
      } else {
        debugPrint('Upload failed with status ${res.statusCode}: $respStr');
      }
    } catch (e) {
      debugPrint('PB uploadBytes error: $e');
    }
    return '';
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
// Firestore Replacement Classes (Generic Compatible)
// ----------------------------------------------------
class DocumentSnapshot<T extends Object?> {
  final String id;
  final String collectionName;
  final Map<String, dynamic> _data;
  final bool exists;

  DocumentSnapshot(this.id, this._data, {this.exists = true, this.collectionName = 'posts'});

  Map<String, dynamic> data() => Map<String, dynamic>.from(_data);

  DocumentReference<T> get reference => DocumentReference<T>(collectionName, id);

  dynamic get(String field) => _data[field];

  dynamic operator [](String field) => _data[field];
}

class QueryDocumentSnapshot<T extends Object?> extends DocumentSnapshot<T> {
  QueryDocumentSnapshot(String id, Map<String, dynamic> data, {String collectionName = 'posts'})
      : super(id, data, exists: true, collectionName: collectionName);
}

class QuerySnapshot<T extends Object?> {
  final List<QueryDocumentSnapshot<T>> docs;
  QuerySnapshot(this.docs);
}

class DocumentReference<T extends Object?> {
  final String id;
  final String collectionName;
  DocumentReference(this.collectionName, this.id);

  Future<DocumentSnapshot<T>> get() async {
    try {
      final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records/$id');
      final resp = await http.get(url, headers: PBClient.instance.headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return DocumentSnapshot<T>(id, _normalizeData(data), exists: true, collectionName: collectionName);
      }
    } catch (e) {
      debugPrint('Doc get error: $e');
    }
    return DocumentSnapshot<T>(id, {}, exists: false, collectionName: collectionName);
  }

  Future<void> set(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records/$id');
      final resp = await http.patch(
        url,
        headers: {...PBClient.instance.headers, 'Content-Type': 'application/json'},
        body: jsonEncode(_cleanData(data)),
      );
      if (resp.statusCode == 404) {
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

  CollectionReference<T> collection(String subCol) {
    return CollectionReference<T>(subCol);
  }

  Stream<DocumentSnapshot<T>> snapshots() {
    late StreamController<DocumentSnapshot<T>> controller;
    Timer? timer;
    controller = StreamController<DocumentSnapshot<T>>(
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

class Query<T extends Object?> {
  final String collectionName;
  String? sortField;
  bool isDescending = false;
  int limitCount = 30;
  final List<String> filters = [];

  Query(this.collectionName);

  Query<T> orderBy(String field, {bool descending = false}) {
    sortField = field;
    isDescending = descending;
    return this;
  }

  Query<T> limit(int n) {
    limitCount = n;
    return this;
  }

  Query<T> where(String field, {dynamic isEqualTo, dynamic arrayContains}) {
    if (isEqualTo != null) {
      filters.add('$field = "$isEqualTo"');
    }
    return this;
  }

  Future<QuerySnapshot<T>> get() async {
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
        List<QueryDocumentSnapshot<T>> docs = items.map((it) {
          final m = it as Map<String, dynamic>;
          return QueryDocumentSnapshot<T>(m['id'], _normalizeData(m), collectionName: collectionName);
        }).toList();
        return QuerySnapshot<T>(docs);
      }
    } catch (e) {
      debugPrint('Query get error: $e');
    }
    return QuerySnapshot<T>([]);
  }

  Stream<QuerySnapshot<T>> snapshots() {
    late StreamController<QuerySnapshot<T>> controller;
    Timer? timer;
    controller = StreamController<QuerySnapshot<T>>(
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

class CollectionReference<T extends Object?> extends Query<T> {
  CollectionReference(String name) : super(name);

  DocumentReference<T> doc([String? docId]) {
    String id = docId ?? const Uuid().v4().replaceAll('-', '').substring(0, 15);
    return DocumentReference<T>(collectionName, id);
  }

  Future<DocumentReference<T>> add(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${PBClient.instance.baseUrl}/api/collections/$collectionName/records');
      final resp = await http.post(
        url,
        headers: {...PBClient.instance.headers, 'Content-Type': 'application/json'},
        body: jsonEncode(_cleanData(data)),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final rec = jsonDecode(resp.body) as Map<String, dynamic>;
        return DocumentReference<T>(collectionName, rec['id']);
      }
    } catch (e) {
      debugPrint('Collection add error: $e');
    }
    return DocumentReference<T>(collectionName, const Uuid().v4().substring(0, 15));
  }
}

class FirebaseFirestore {
  static final FirebaseFirestore instance = FirebaseFirestore._();
  FirebaseFirestore._();

  CollectionReference<Map<String, dynamic>> collection(String name) =>
      CollectionReference<Map<String, dynamic>>(name);
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
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${PBClient.instance.baseUrl}/api/collections/posts/records'),
      );
      request.headers.addAll(PBClient.instance.headers);
      request.fields['description'] = 'Upload';
      request.fields['owner'] = PBClient.instance.currentRecord?['id'] ?? '';

      if (file != null) {
        try {
          final p = (file as dynamic).path;
          if (p != null) {
            request.files.add(await http.MultipartFile.fromPath('media', p.toString()));
          }
        } catch (_) {}
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
