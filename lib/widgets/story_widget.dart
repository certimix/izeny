import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/models/status.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/posts/story/status_view.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/widgets/indicators.dart';

class StoryWidget extends StatelessWidget {
  const StoryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = firebaseAuth.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: userChatsStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        List chatList = snapshot.data!.docs;
        if (chatList.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 90.0,
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: chatList.length,
            itemBuilder: (BuildContext context, int index) {
              DocumentSnapshot statusListSnapshot = chatList[index];
              return StreamBuilder<QuerySnapshot>(
                stream: messageListStream(statusListSnapshot.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List statuses = snapshot.data!.docs;
                    if (statuses.isEmpty) return const SizedBox.shrink();
                    StatusModel status = StatusModel.fromJson(
                      statuses.first.data(),
                    );
                    List users = List.from(statusListSnapshot.get('whoCanSee') ?? []);
                    users.remove(uid);
                    return _buildStatusAvatar(
                        statusListSnapshot.get('userId') ?? '',
                        statusListSnapshot.id,
                        status.statusId ?? '',
                        index);
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  _buildStatusAvatar(
    String userId,
    String chatId,
    String messageId,
    int index,
  ) {
    return StreamBuilder(
      stream: usersRef.doc('$userId').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot documentSnapshot =
              snapshot.data as DocumentSnapshot<Object?>;
          UserModel user = UserModel.fromJson(
            documentSnapshot.data() as Map<String, dynamic>,
          );
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StatusScreen(
                          statusId: chatId,
                          storyId: messageId,
                          initPage: index,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          offset: new Offset(0.0, 0.0),
                          blurRadius: 2.0,
                          spreadRadius: 0.0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: CircleAvatar(
                        radius: 35.0,
                        backgroundColor: Colors.grey,
                        backgroundImage: CachedNetworkImageProvider(
                          user.photoUrl!,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  user.username!,
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Stream<QuerySnapshot> userChatsStream(String uid) {
    return statusRef.where('whoCanSee', arrayContains: '$uid').snapshots();
  }

  Stream<QuerySnapshot> messageListStream(String documentId) {
    return statusRef.doc(documentId).collection('statuses').snapshots();
  }
}
