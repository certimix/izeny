import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/components/notification_stream_wrapper.dart';
import 'package:social_media_app/models/notification.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/widgets/notification_items.dart';

class Activities extends StatefulWidget {
  @override
  _ActivitiesState createState() => _ActivitiesState();
}

class _ActivitiesState extends State<Activities> {
  String currentUserId() {
    return firebaseAuth.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Notificações',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20.0,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: () => deleteAllItems(),
              child: Text(
                'LIMPAR',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: currentUserId().isEmpty
          ? const Center(child: Text("Faça login para ver suas notificações."))
          : ListView(
              children: [
                getActivities(),
              ],
            ),
    );
  }

  getActivities() {
    final uid = currentUserId();
    if (uid.isEmpty) return const SizedBox.shrink();

    return ActivityStreamWrapper(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      stream: notificationRef
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, DocumentSnapshot snapshot) {
        ActivityModel activities =
            ActivityModel.fromJson(snapshot.data() as Map<String, dynamic>);
        return ActivityItems(
          activity: activities,
        );
      },
    );
  }

  deleteAllItems() async {
    final uid = currentUserId();
    if (uid.isEmpty) return;
    QuerySnapshot notificationsSnap = await notificationRef
        .doc(uid)
        .collection('notifications')
        .get();
    for (var doc in notificationsSnap.docs) {
      if (doc.exists) {
        doc.reference.delete();
      }
    }
    setState(() {});
  }
}
