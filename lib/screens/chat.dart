import 'package:flutter/material.dart';
import 'package:projj12_chatapp/screens/video_call.dart';
import 'package:projj12_chatapp/widgets/chat/chat_messages.dart';
import 'package:projj12_chatapp/widgets/chat/new_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen(this.seconduserdetails, this.documentId, {super.key})
      : memberdetails = const {},
        isGroup = false;

  const ChatScreen.group(this.memberdetails, this.documentId, {super.key})
      : seconduserdetails = const {},
        isGroup = true;

  final Map<String, dynamic> seconduserdetails;
  final Map<String, dynamic> memberdetails;
  final bool isGroup;
  final String documentId;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String appBarTitle;

  @override
  void initState() {
    super.initState();
    if (widget.isGroup) {
      appBarTitle = widget.memberdetails['groupname'] ?? 'Group Chat';
    } else {
      appBarTitle = widget.seconduserdetails['username'] ?? 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: widget.isGroup
            ? Text(appBarTitle)
            : Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        NetworkImage(widget.seconduserdetails['image_url']),
                  ),
                  const SizedBox(width: 12),
                  Text(appBarTitle),
                ],
              ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => VideoCallScreen(widget.documentId, widget.isGroup)),
            ),
            icon: const Icon(Icons.video_camera_front),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: Colors.orange,
            height: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.isGroup
                ? ChatMessages.group(widget.memberdetails)
                : ChatMessages(widget.seconduserdetails),
          ),
          widget.isGroup
              ? NewMessage.group(widget.memberdetails)
              : NewMessage(widget.seconduserdetails),
        ],
      ),
    );
  }
}
