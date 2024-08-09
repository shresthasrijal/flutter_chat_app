import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:projj12_chatapp/utility/camera_screen.dart';
import 'package:video_player/video_player.dart';

class NewMessage extends StatefulWidget {
  const NewMessage(this.seconduserdetails, {super.key})
      : memberdetails = const {},
        isGroup = false;

  const NewMessage.group(this.memberdetails, {super.key})
      : seconduserdetails = const {},
        isGroup = true;

  final Map<String, dynamic> memberdetails;
  final Map<String, dynamic> seconduserdetails;
  final bool isGroup;
  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();
  VideoPlayerController? _videoPlayerController;

  File? _image;
  File? _video;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  String getDocumentId(String uid1, String uid2) {
    List<String> uids = [uid1, uid2];
    uids.sort();
    return '${uids[0]}_${uids[1]}';
  }

  Future<String> getAccessToken() async {
    final serviceAccountJson = {}; //add ur own
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];
    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );
    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);
    // Close the HTTP client
    client.close();
    // Return the access token
    return credentials.accessToken.data;
  }

  void _submitMessage() async {
    if (_isSubmitting) return; // Prevent multiple submissions
    setState(() {
      _isSubmitting = true;
    });

    final enteredMessage = _messageController.text;

    // add validation
    if (enteredMessage.trim().isEmpty && _image == null && _video == null) {
      return;
    }

    final uploadImage = _image;
    final uploadVideo = _video;

    _removeAttachment();
    //clear textbox
    _messageController.clear();
    // close keyboard
    FocusScope.of(context).unfocus(); //closes keyboard
    //get current user id
    final user = FirebaseAuth.instance.currentUser!;
    //get user data from firestore
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    String chatId = widget.isGroup
        ? widget.memberdetails['documentId']
        : getDocumentId(user.uid, widget.seconduserdetails['uid']);
    // send to Firebase
    if (uploadImage == null && uploadVideo == null) {
      await FirebaseFirestore.instance
          .collection('chat')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': enteredMessage,
        'createdAt': Timestamp.now(),
        'userID': user.uid,
        'username': userData.data()!['username'],
        'userImage': userData.data()!['image_url'],
        'imageUrl': '',
        'videoUrl': '',
      });
    } else if (uploadVideo == null && uploadImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${user.uid}_${Timestamp.now().millisecondsSinceEpoch}.jpg');

      // store image into firebase storage and et url
      await storageRef.putFile(uploadImage);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('chat')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': '',
        'createdAt': Timestamp.now(),
        'userID': user.uid,
        'username': userData.data()!['username'],
        'userImage': userData.data()!['image_url'],
        'imageUrl': imageUrl,
        'videoUrl': '',
      });
    } else {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_videos')
          .child('${user.uid}_${Timestamp.now().millisecondsSinceEpoch}.mp4');
      await storageRef.putFile(uploadVideo!);
      final videoUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance
          .collection('chat')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': '',
        'createdAt': Timestamp.now(),
        'userID': user.uid,
        'username': userData.data()!['username'],
        'userImage': userData.data()!['image_url'],
        'imageUrl': '',
        'videoUrl': videoUrl,
      });
    }

    String toSend = '';

    if (uploadImage != null) {
      toSend = 'Sent an Image attachment.';
    } else if (uploadVideo != null) {
      toSend = 'Sent an Video attachment.';
    } else {
      toSend = enteredMessage;
    }

    if (!widget.isGroup) {
      await sendPushNotification(
        userData.data()!['username'],
        toSend,
        widget.seconduserdetails["fcmtoken"],
        userData.data()!['fcmtoken'],
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> sendPushNotification(String username, String text,
      String fcmtoken, String currentFCMToken) async {
    final String serverKey = await getAccessToken();
    const String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/flutter-chat-app-52f3e/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'token': fcmtoken,
        'notification': {
          'body': text,
          'title': username,
        },
        'data': {
          'CurrentUserFcmToken': currentFCMToken,
        },
      }
    };

    final http.Response response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('FCM message sent successfully');
    } else {
      print(response);
      print(response.body);
      print('Failed to send FCM message: ${response.statusCode}');
    }
  }

  void _removeAttachment() {
    setState(() {
      _image = null;
      _video = null;
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.media);

    if (result == null) {
      return;
    } else {
      PlatformFile file = result.files.first;
      String? extension = file.extension?.toLowerCase();

      if (extension == 'jpg' ||
          extension == 'jpeg' ||
          extension == 'png' ||
          extension == 'gif') {
        setState(() {
          _image = File(file.path!);
        });
      } else if (extension == 'mp4' ||
          extension == 'mov' ||
          extension == 'avi' ||
          extension == 'mkv') {
        setState(() {
          _video = File(file.path!);
          _videoPlayerController = VideoPlayerController.file(_video!)
            ..initialize().then((_) {
              setState(() {});
            });
        });
      } else {
        return;
      }
    }
  }

  Future<void> _takeMedia() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    if (result != null) {
      final path = result['path'];
      final isImage = result['isImage'];
      setState(() {
        if (isImage) {
          _image = File(path);
        } else {
          _video = File(path);
          _videoPlayerController = VideoPlayerController.file(_video!)
            ..initialize().then((_) {
              setState(() {});
            });
        }
      });
    } else {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
        right: 1,
        bottom: 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_image != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Positioned(
                      top: -10,
                      left: -10,
                      child: InkWell(
                        onTap: _removeAttachment,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.red,
                          ),
                          height: 20,
                          width: 20,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_video != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _videoPlayerController != null &&
                              _videoPlayerController!.value.isInitialized
                          ? AspectRatio(
                              aspectRatio:
                                  _videoPlayerController!.value.aspectRatio,
                              child: VideoPlayer(_videoPlayerController!),
                            )
                          : const Center(
                              child: Icon(
                                Icons.video_library,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                    ),
                    Positioned(
                      top: -10,
                      left: -10,
                      child: InkWell(
                        onTap: _removeAttachment,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.red,
                          ),
                          height: 20,
                          width: 20,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  autocorrect: true,
                  enableSuggestions: true,
                  decoration: const InputDecoration(
                    labelText: 'Send a message...',
                  ),
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.add_a_photo_outlined),
                color: Theme.of(context).colorScheme.primary,
                onSelected: (value) {
                  if (value == 1) {
                    _takeMedia();
                  } else if (value == 2) {
                    _pickFile();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Camera')
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        Icon(Icons.photo, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Gallery')
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                color: Theme.of(context).colorScheme.primary,
                onPressed: _isSubmitting ? () {} : _submitMessage,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
