import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/components/chat_item.dart';
import 'package:social_media_app/models/enum/message_type.dart';
import 'package:social_media_app/models/message.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/view_models/user/user_view_model.dart';
import 'package:social_media_app/widgets/indicators.dart';

class Chats extends StatelessWidget {
  const Chats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUid = firebaseAuth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(Icons.keyboard_backspace),
              )
            : null,
        title: const Text(
          "Mensagens",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20.0,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: currentUid.isEmpty
          ? const Center(child: Text("Faça login para ver suas conversas."))
          : StreamBuilder<QuerySnapshot>(
              stream: userChatsStream(currentUid),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List chatList = snapshot.data!.docs;
                  if (chatList.isNotEmpty) {
                    return ListView.separated(
                      itemCount: chatList.length,
                      separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        DocumentSnapshot chatListSnapshot = chatList[index];
                        return StreamBuilder<QuerySnapshot>(
                          stream: messageListStream(chatListSnapshot.id),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              List messages = snapshot.data!.docs;
                              if (messages.isEmpty) return const SizedBox();
                              Message message = Message.fromJson(
                                messages.first.data() as Map<String, dynamic>,
                              );
                              List users = List.from(chatListSnapshot.get('users') ?? []);
                              users.remove(currentUid);
                              if (users.isEmpty) return const SizedBox();
                              String recipient = users[0];
                              return ChatItem(
                                userId: recipient,
                                messageCount: messages.length,
                                msg: message.content ?? '',
                                time: message.time ?? Timestamp.now(),
                                chatId: chatListSnapshot.id,
                                type: message.type ?? MessageType.TEXT,
                                currentUserId: currentUid,
                              );
                            } else {
                              return const SizedBox();
                            }
                          },
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              'Nenhuma conversa ainda',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Conecte-se com técnicos e parceiros na barra lateral ou buscando usuários!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                } else {
                  return Center(child: circularProgress(context));
                }
              },
            ),
    );
  }

  Stream<QuerySnapshot> userChatsStream(String uid) {
    return chatRef
        .where('users', arrayContains: '$uid')
        .orderBy('lastTextTime', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> messageListStream(String documentId) {
    return chatRef
        .doc(documentId)
        .collection('messages')
        .orderBy('time', descending: true)
        .snapshots();
  }
}
