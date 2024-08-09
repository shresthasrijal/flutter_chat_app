import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projj12_chatapp/widgets/chat/message_bubble.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages(this.seconduserdetails, {super.key}): memberdetails = const {}, isGroup = false;

  const ChatMessages.group(this.memberdetails, {super.key}): seconduserdetails = const {}, isGroup = true;

  final Map<String, dynamic> seconduserdetails;
  final Map<String, dynamic> memberdetails;
  final bool isGroup;

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  String chatId = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser!;
    chatId = widget.memberdetails['documentId'] ?? getDocumentId(user.uid, widget.seconduserdetails['uid']);
  }

  String getDocumentId(String uid1, String uid2) {
    List<String> uids = [uid1, uid2];
    uids.sort();
    return '${uids[0]}_${uids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .doc(chatId)
          .collection('messages')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found.'),
          );
        }

        if (chatSnapshots.hasError) {
          return const Center(
            child: Text('Something went wrong ...'),
          );
        }
        final loadedMessages = chatSnapshots.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 13,
            right: 13,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final chatMessage = loadedMessages[index].data();
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;
            final currentMessageUserID = chatMessage['userID'];
            final nextMessageUserID =
                nextChatMessage != null ? nextChatMessage['userID'] : null;
            final nextUserIsSame = nextMessageUserID == currentMessageUserID;

            if (nextUserIsSame) {
              return MessageBubble.next(
                message: chatMessage['text'],
                isMe: authenticatedUser.uid == currentMessageUserID,
                imageUrl: chatMessage['imageUrl'],
                videoUrl: chatMessage['videoUrl'],
              );
            } else {
              return MessageBubble.first(
                userImage: chatMessage['userImage'],
                username: chatMessage['username'],
                message: chatMessage['text'],
                isMe: authenticatedUser.uid == currentMessageUserID,
                imageUrl: chatMessage['imageUrl'],
                videoUrl: chatMessage['videoUrl'],
              );
            }
          },
        );
      },
    );
  }
}
