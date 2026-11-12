import 'dart:io';

import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:social_media_app/models/message.dart';
import 'package:social_media_app/utils/firebase.dart';

class ChatService {
  FirebaseStorage storage = FirebaseStorage.instance;

  Future<void> sendMessage(Message message, String chatId) async {
    await chatRef.doc("$chatId").collection("messages").add(message.toJson());
    await chatRef.doc("$chatId").update({
      "lastMessageTime": Timestamp.now(),
      "lastMessage": message.content ?? '',
    });
  }

  Future<String> sendFirstMessage(Message message, String recipient) async {
    User user = firebaseAuth.currentUser!;
    DocumentReference ref = await chatRef.add({
      'users': [recipient, user.uid],
      'lastMessage': message.content ?? '',
      'lastMessageTime': Timestamp.now(),
    });
    await sendMessage(message, ref.id);
    return ref.id;
  }

  Future<String> uploadImage(File image, String chatId) async {
    Reference storageReference =
        storage.ref().child("chats").child(chatId).child(uuid.v4());
    UploadTask uploadTask = storageReference.putFile(image);
    await uploadTask.whenComplete(() => null);
    String imageUrl = await storageReference.getDownloadURL();
    return imageUrl;
  }

  setUserRead(String chatId, User user, int count) async {
    DocumentSnapshot snap = await chatRef.doc(chatId).get();
    Map reads = snap.get('reads') ?? {};
    reads[user.uid] = count;
    await chatRef.doc(chatId).update({'reads': reads});
  }

  setUserTyping(String chatId, User user, bool userTyping) async {
    DocumentSnapshot snap = await chatRef.doc(chatId).get();
    Map typing = snap.get('typing') ?? {};
    typing[user.uid] = userTyping;
    await chatRef.doc(chatId).update({
      'typing': typing,
    });
  }
}
