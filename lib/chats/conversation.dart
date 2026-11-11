import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:social_media_app/components/chat_bubble.dart';
import 'package:social_media_app/models/enum/message_type.dart';
import 'package:social_media_app/models/message.dart';
import 'package:social_media_app/models/user.dart';
import 'package:social_media_app/pages/profile.dart';
import 'package:social_media_app/utils/audio_helper.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/view_models/conversation/conversation_view_model.dart';
import 'package:social_media_app/view_models/user/user_view_model.dart';
import 'package:social_media_app/widgets/indicators.dart';
import 'package:timeago/timeago.dart' as timeago;

class Conversation extends StatefulWidget {
  final String userId;
  final String chatId;

  const Conversation({required this.userId, required this.chatId});

  @override
  _ConversationState createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  FocusNode focusNode = FocusNode();
  ScrollController scrollController = ScrollController();
  TextEditingController messageController = TextEditingController();
  bool isFirst = false;
  String? chatId;

  final AppAudioRecorder _recorder = AppAudioRecorder();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  bool _isUploadingMedia = false;

  @override
  void dispose() {
    _recordTimer?.cancel();
    messageController.dispose();
    super.dispose();
  }

  void _startVoiceRecord() async {
    final ok = await _recorder.start();
    if (ok) {
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
    }
  }

  void _cancelVoiceRecord() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  void _sendVoiceRecord(ConversationViewModel viewModel, var user) async {
    _recordTimer?.cancel();
    final duration = _recordSeconds;
    setState(() {
      _isRecording = false;
      _isUploadingMedia = true;
    });
    final result = await _recorder.stop();
    if (result != null && result.bytes.isNotEmpty) {
      final audioUrl = await PBClient.uploadBytes(
        result.bytes,
        result.fileName,
        collection: 'messages',
        field: 'media',
      );
      if (audioUrl.isNotEmpty) {
        final msg = Message(
          content: audioUrl,
          mediaUrl: audioUrl,
          senderUid: user?.uid,
          type: MessageType.AUDIO,
          duration: duration > 0 ? duration : 1,
          time: Timestamp.now(),
        );
        _deliverMessage(viewModel, user, msg);
      }
    }
    if (mounted) {
      setState(() {
        _isUploadingMedia = false;
        _recordSeconds = 0;
      });
    }
  }

  void _pickAndSendVideo(ConversationViewModel viewModel, var user) async {
    final picker = ImagePicker();
    final picked = await picker.getVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _isUploadingMedia = true;
      });
      final bytes = await picked.readAsBytes();
      final videoUrl = await PBClient.uploadBytes(
        bytes,
        'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        collection: 'messages',
        field: 'media',
      );
      if (videoUrl.isNotEmpty) {
        final msg = Message(
          content: videoUrl,
          mediaUrl: videoUrl,
          senderUid: user?.uid,
          type: MessageType.VIDEO,
          time: Timestamp.now(),
        );
        _deliverMessage(viewModel, user, msg);
      }
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  void _deliverMessage(ConversationViewModel viewModel, var user, Message message) async {
    if (isFirst) {
      String id = await viewModel.sendFirstMessage(widget.userId, message);
      setState(() {
        isFirst = false;
        chatId = id;
        chatIdRef.add({
          "users": getUser(firebaseAuth.currentUser!.uid, widget.userId),
          "chatId": id
        });
        viewModel.sendMessage(widget.chatId, message);
      });
      chatRef.doc(chatId).update({'reads': {}});
      chatRef.doc(chatId).update({'typing': {}});
    } else {
      viewModel.sendMessage(widget.chatId, message);
    }
  }

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      focusNode.unfocus();
    });
    if (widget.chatId == 'newChat') {
      isFirst = true;
    }
    chatId = widget.chatId;

    messageController.addListener(() {
      if (focusNode.hasFocus && messageController.text.isNotEmpty) {
        setTyping(true);
      } else if (!focusNode.hasFocus ||
          (focusNode.hasFocus && messageController.text.isEmpty)) {
        setTyping(false);
      }
    });
  }

  setTyping(typing) {
    UserViewModel viewModel = Provider.of<UserViewModel>(context);
    viewModel.setUser();
    var user = Provider.of<UserViewModel>(context, listen: true).user;
    Provider.of<ConversationViewModel>(context, listen: false)
        .setUserTyping(widget.chatId, user, typing);
  }

  @override
  Widget build(BuildContext context) {
    UserViewModel viewModel = Provider.of<UserViewModel>(context);
    viewModel.setUser();
    var user = Provider.of<UserViewModel>(context, listen: true).user;
    return Consumer<ConversationViewModel>(
        builder: (BuildContext context, viewModel, Widget? child) {
      return Scaffold(
        key: viewModel.scaffoldKey,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.keyboard_backspace,
            ),
          ),
          elevation: 0.0,
          titleSpacing: 0,
          title: buildUserName(),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: messageListStream(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List messages = snapshot.data!.docs;
                      viewModel.setReadCount(
                          widget.chatId, user, messages.length);
                      return ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        itemCount: messages.length,
                        reverse: true,
                        itemBuilder: (BuildContext context, int index) {
                          Message message = Message.fromJson(
                            messages.reversed.toList()[index].data(),
                          );
                          return ChatBubbleWidget(
                            message: '${message.content}',
                            time: message.time!,
                            isMe: message.senderUid == user!.uid,
                            type: message.type!,
                          );
                        },
                      );
                    } else {
                      return Center(child: circularProgress(context));
                    }
                  },
                ),
              ),
              if (_isUploadingMedia)
                Container(
                  color: Colors.blue.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Enviando mídia...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: BottomAppBar(
                  elevation: 10.0,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100.0),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: _isRecording
                        ? Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Cancelar Gravação',
                                onPressed: _cancelVoiceRecord,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Gravando áudio de voz... ${_recordSeconds}s',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                                tooltip: 'Enviar Mensagem de Voz',
                                onPressed: () => _sendVoiceRecord(viewModel, user),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Photo Picker
                              IconButton(
                                icon: Icon(
                                  CupertinoIcons.photo_on_rectangle,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                tooltip: 'Enviar Foto',
                                onPressed: () => showPhotoOptions(viewModel, user),
                              ),
                              // Video Picker
                              IconButton(
                                icon: Icon(
                                  CupertinoIcons.videocam_fill,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                tooltip: 'Enviar Vídeo',
                                onPressed: () => _pickAndSendVideo(viewModel, user),
                              ),
                              // Audio Record Button
                              IconButton(
                                icon: const Icon(
                                  Icons.mic_none_rounded,
                                  color: Color(0xFF2563EB),
                                ),
                                tooltip: 'Gravar Mensagem de Voz',
                                onPressed: _startVoiceRecord,
                              ),
                              // Text Field
                              Flexible(
                                child: TextField(
                                  controller: messageController,
                                  focusNode: focusNode,
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                    hintText: "Digite sua mensagem...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                  maxLines: null,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Send Button
                              IconButton(
                                icon: Icon(
                                  Ionicons.send,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                tooltip: 'Enviar',
                                onPressed: () {
                                  if (messageController.text.isNotEmpty) {
                                    sendMessage(viewModel, user);
                                  }
                                },
                              ),
                            ],
                          ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    });
  }

  _buildOnlineText(
    var user,
    bool typing,
  ) {
    if (user.isOnline) {
      if (typing) {
        return "typing...";
      } else {
        return "online";
      }
    } else {
      return 'last seen ${timeago.format(user.lastSeen.toDate())}';
    }
  }

  buildUserName() {
    return StreamBuilder(
      stream: usersRef.doc('${widget.userId}').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot documentSnapshot =
              snapshot.data as DocumentSnapshot<Object?>;
          UserModel user = UserModel.fromJson(
            documentSnapshot.data() as Map<String, dynamic>,
          );
          return InkWell(
            child: Row(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 10.0, right: 10.0),
                  child: Hero(
                    tag: user.email!,
                    child: user.photoUrl!.isEmpty
                        ? CircleAvatar(
                            radius: 25.0,
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            child: Center(
                              child: Text(
                                '${user.username![0].toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 25.0,
                            backgroundImage: CachedNetworkImageProvider(
                              '${user.photoUrl}',
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${user.username}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                      SizedBox(height: 5.0),
                      StreamBuilder(
                        stream: chatRef.doc('${widget.chatId}').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            DocumentSnapshot? snap =
                                snapshot.data as DocumentSnapshot<Object?>;
                            Map? data = snap.data() as Map<dynamic, dynamic>?;
                            Map? usersTyping = data?['typing'] ?? {};
                            return Text(
                              _buildOnlineText(
                                user,
                                usersTyping![widget.userId] ?? false,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            );
                          } else {
                            return SizedBox();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => Profile(profileId: user.id),
                ),
              );
            },
          );
        } else {
          return Center(child: circularProgress(context));
        }
      },
    );
  }

  showPhotoOptions(ConversationViewModel viewModel, var user) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10.0),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text("Camera"),
              onTap: () {
                sendMessage(viewModel, user, imageType: 0, isImage: true);
              },
            ),
            ListTile(
              title: Text("Gallery"),
              onTap: () {
                sendMessage(viewModel, user, imageType: 1, isImage: true);
              },
            ),
          ],
        );
      },
    );
  }

  sendMessage(ConversationViewModel viewModel, var user,
      {bool isImage = false, int? imageType}) async {
    String msg;
    if (isImage) {
      msg = await viewModel.pickImage(
        source: imageType!,
        context: context,
        chatId: widget.chatId,
      );
    } else {
      msg = messageController.text.trim();
      messageController.clear();
    }

    Message message = Message(
      content: '$msg',
      senderUid: user?.uid,
      type: isImage ? MessageType.IMAGE : MessageType.TEXT,
      time: Timestamp.now(),
    );

    if (msg.isNotEmpty) {
      if (isFirst) {
        print("FIRST");
        String id = await viewModel.sendFirstMessage(widget.userId, message);
        setState(() {
          isFirst = false;
          chatId = id;
          //Add the IDs of the two users to the chatID reference
          //the users map will be concatenation of the two users
          //involved in the chat
          chatIdRef.add({
            "users": getUser(firebaseAuth.currentUser!.uid, widget.userId),
            "chatId": id
          });
          viewModel.sendMessage(widget.chatId, message);
        });
        //update the reads to an empty map in other to avoid null value bug
        chatRef.doc(chatId).update({'reads': {}});
        //update the typing to an empty map in other to avoid null value bug
        chatRef.doc(chatId).update({'typing': {}});
      } else {
        viewModel.sendMessage(
          widget.chatId,
          message,
        );
      }
    }
  }

  //this will concatenate the two users involved in the chat
  //and  return a unique id, because firebase doesn't perform
  //some complex queries
  String getUser(String user1, String user2) {
    user1 = user1.substring(0, 5);
    user2 = user2.substring(0, 5);
    List<String> list = [user1, user2];
    list.sort();
    var chatId = "${list[0]}-${list[1]}";
    return chatId;
  }

  Stream<QuerySnapshot> messageListStream(String documentId) {
    return chatRef
        .doc(documentId)
        .collection('messages')
        .orderBy('time')
        .snapshots();
  }
}
