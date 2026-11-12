import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:social_media_app/models/enum/message_type.dart';

class Message {
  String? content;
  String? senderUid;
  String? messageId;
  MessageType? type;
  Timestamp? time;
  String? mediaUrl;
  int? duration;

  Message({
    this.content,
    this.senderUid,
    this.messageId,
    this.type,
    this.time,
    this.mediaUrl,
    this.duration,
  });

  Message.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    senderUid = json['senderUid'] ?? json['sender'];
    messageId = json['messageId'] ?? json['id'];
    mediaUrl = json['mediaUrl'] ?? json['media'];
    duration = json['duration'] is int ? json['duration'] : null;

    final typeStr = (json['type'] ?? 'text').toString().toLowerCase();
    if (typeStr == 'image' || typeStr == 'photo') {
      type = MessageType.IMAGE;
    } else if (typeStr == 'audio' || typeStr == 'voice') {
      type = MessageType.AUDIO;
    } else if (typeStr == 'video') {
      type = MessageType.VIDEO;
    } else {
      type = MessageType.TEXT;
    }
    time = json['time'] ?? (json['created'] != null ? Timestamp.fromDate(DateTime.parse(json['created'])) : Timestamp.now());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['content'] = content;
    data['senderUid'] = senderUid;
    data['sender'] = senderUid;
    data['messageId'] = messageId;
    data['mediaUrl'] = mediaUrl;
    data['media'] = mediaUrl;
    data['duration'] = duration;

    switch (type) {
      case MessageType.IMAGE:
        data['type'] = 'image';
        break;
      case MessageType.AUDIO:
        data['type'] = 'audio';
        break;
      case MessageType.VIDEO:
        data['type'] = 'video';
        break;
      case MessageType.TEXT:
      default:
        data['type'] = 'text';
        break;
    }
    data['time'] = time;
    return data;
  }
}
