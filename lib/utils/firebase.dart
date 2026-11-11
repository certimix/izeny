import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:uuid/uuid.dart';

export 'package:social_media_app/pocketbase/pb_compat.dart';

FirebaseAuth firebaseAuth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseStorage storage = FirebaseStorage.instance;
final Uuid uuid = Uuid();

// Collection refs
CollectionReference usersRef = firestore.collection('users');
CollectionReference chatRef = firestore.collection("chats");
CollectionReference postRef = firestore.collection('posts');
CollectionReference storyRef = firestore.collection('posts');
CollectionReference commentRef = firestore.collection('comments');
CollectionReference notificationRef = firestore.collection('notifications');
CollectionReference followersRef = firestore.collection('follows');
CollectionReference followingRef = firestore.collection('follows');
CollectionReference likesRef = firestore.collection('likes');
CollectionReference favUsersRef = firestore.collection('favoriteUsers');
CollectionReference chatIdRef = firestore.collection('chatIds');
CollectionReference statusRef = firestore.collection('statuses');

// Storage refs
Reference profilePic = storage.ref('profilePic');
Reference posts = storage.ref('posts');
Reference statuses = storage.ref('statuses');
