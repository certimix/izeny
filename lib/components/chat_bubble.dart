import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_3.dart';
import 'package:social_media_app/components/text_time.dart';
import 'package:social_media_app/components/voice_bubble.dart';
import 'package:social_media_app/components/video_bubble.dart';
import 'package:social_media_app/models/enum/message_type.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatBubbleWidget extends StatefulWidget {
  final String? message;
  final MessageType? type;
  final Timestamp? time;
  final bool? isMe;

  ChatBubbleWidget({
    @required this.message,
    @required this.time,
    @required this.isMe,
    @required this.type,
  });

  @override
  _ChatBubbleWidgetState createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget> {
  Color? chatBubbleColor() {
    if (widget.isMe!) {
      return Theme.of(context).colorScheme.secondary;
    } else {
      if (Theme.of(context).brightness == Brightness.dark) {
        return Colors.grey[800];
      } else {
        return Colors.grey[200];
      }
    }
  }

  Widget _buildBubbleContent() {
    switch (widget.type) {
      case MessageType.AUDIO:
        return VoiceMessageBubble(
          audioUrl: widget.message ?? '',
          isMe: widget.isMe ?? false,
        );
      case MessageType.VIDEO:
        return VideoMessageBubble(
          videoUrl: widget.message ?? '',
          isMe: widget.isMe ?? false,
        );
      case MessageType.IMAGE:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: "${widget.message}",
            height: 200,
            width: MediaQuery.of(context).size.width > 600
                ? 300
                : MediaQuery.of(context).size.width / 1.4,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 180,
              color: Colors.grey.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => Container(
              height: 120,
              color: Colors.grey.withOpacity(0.2),
              child: const Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey)),
            ),
          ),
        );
      case MessageType.TEXT:
      default:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            widget.message ?? '',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: widget.isMe!
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final align =
        widget.isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: <Widget>[
        ChatBubble(
          elevation: 0.0,
          margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4.0),
          padding: EdgeInsets.zero,
          alignment:
              widget.isMe! ? Alignment.centerRight : Alignment.centerLeft,
          clipper: ChatBubbleClipper3(
            nipSize: 0,
            type: widget.isMe!
                ? BubbleType.sendBubble
                : BubbleType.receiverBubble,
          ),
          backGroundColor: chatBubbleColor(),
          child: _buildBubbleContent(),
        ),
        Padding(
          padding: widget.isMe!
              ? const EdgeInsets.only(right: 10.0, bottom: 8.0)
              : const EdgeInsets.only(left: 10.0, bottom: 8.0),
          child: Text(
            widget.time != null ? timeago.format(widget.time!.toDate()) : '',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10.0,
            ),
          ),
        ),
      ],
    );
  }
}
