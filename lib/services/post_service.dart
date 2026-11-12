import 'dart:io';

import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/screens/view_image.dart';
import 'package:social_media_app/services/services.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:uuid/uuid.dart';

class PostService extends Service {
  String postId = Uuid().v4();

  // Uploads profile picture to the users collection
  uploadProfilePicture(File image, User user) async {
    String link = await uploadImage(profilePic, image);
    var ref = usersRef.doc(user.uid);
    ref.update({
      "photoUrl": link,
    });
  }

  // Universal post creator supporting web, mobile, text-only, and media
  Future<bool> createPostRaw({
    required String description,
    String? location,
    String? mediaUrl,
  }) async {
    try {
      final uid = firebaseAuth.currentUser?.uid ?? '';
      if (uid.isEmpty) return false;

      DocumentSnapshot doc = await usersRef.doc(uid).get();
      String username = 'Usuário';
      if (doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        username = data['name'] ?? data['username'] ?? 'Usuário';
      }

      await postRef.add({
        "username": username,
        "ownerId": uid,
        "owner": uid,
        "mediaUrl": mediaUrl ?? "",
        "description": description.trim(),
        "location": (location != null && location.trim().isNotEmpty) ? location.trim() : "IZeny",
        "timestamp": Timestamp.now(),
        "likes": [],
      });
      return true;
    } catch (e) {
      print('createPostRaw error: $e');
      return false;
    }
  }

  // Uploads post to the post collection
  uploadPost(File? image, String? location, String? description) async {
    String link = "";
    if (image != null) {
      link = await uploadImage(posts, image);
    }
    DocumentSnapshot doc =
        await usersRef.doc(firebaseAuth.currentUser!.uid).get();
    user = UserModel.fromJson(
      doc.data() as Map<String, dynamic>,
    );

    await postRef.add({
      "username": user?.username ?? "Usuário",
      "ownerId": firebaseAuth.currentUser!.uid,
      "owner": firebaseAuth.currentUser!.uid,
      "mediaUrl": link,
      "description": description ?? "",
      "location": location ?? "IZeny",
      "timestamp": Timestamp.now(),
      "likes": [],
    });
  }

  // Upload a comment
  uploadComment(String currentUserId, String comment, String postId,
      String ownerId, String mediaUrl) async {
    DocumentSnapshot doc = await usersRef.doc(currentUserId).get();
    user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
    await commentRef.doc(postId).collection("comments").add({
      "username": user!.username,
      "comment": comment,
      "timestamp": Timestamp.now(),
      "userDp": user!.photoUrl,
      "userId": user!.id,
    });
    bool isNotMe = ownerId != currentUserId;
    if (isNotMe) {
      addCommentToNotification("comment", comment, user!.username!, user!.id!,
          postId, mediaUrl, ownerId, user!.photoUrl!);
    }
  }

  // Add the comment to notification collection
  addCommentToNotification(
      String type,
      String commentData,
      String username,
      String userId,
      String postId,
      String mediaUrl,
      String ownerId,
      String userDp) async {
    await notificationRef.doc(ownerId).collection('notifications').add({
      "type": type,
      "commentData": commentData,
      "username": username,
      "userId": userId,
      "userDp": userDp,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": Timestamp.now(),
    });
  }

  // Add the likes to the notification collection
  addLikesToNotification(String type, String username, String userId,
      String postId, String mediaUrl, String ownerId, String userDp) async {
    await notificationRef
        .doc(ownerId)
        .collection('notifications')
        .doc(postId)
        .set({
      "type": type,
      "username": username,
      "userId": firebaseAuth.currentUser!.uid,
      "userDp": userDp,
      "postId": postId,
      "mediaUrl": mediaUrl,
      "timestamp": Timestamp.now(),
    });
  }

  // Remove likes from notification
  removeLikeFromNotification(
      String ownerId, String postId, String currentUser) async {
    bool isNotMe = currentUser != ownerId;

    if (isNotMe) {
      DocumentSnapshot doc = await usersRef.doc(currentUser).get();
      user = UserModel.fromJson(doc.data() as Map<String, dynamic>);
      notificationRef
          .doc(ownerId)
          .collection('notifications')
          .doc(postId)
          .get()
          .then((doc) => {
                if (doc.exists) {doc.reference.delete()}
              });
    }
  }
}
