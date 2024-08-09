import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projj12_chatapp/screens/chat.dart';
import 'package:projj12_chatapp/widgets/ui/new_group.dart';
import 'package:projj12_chatapp/widgets/users/user_tile.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  Map<String, dynamic>? userData;
  String username = 'Hello,';
  late String userUid;

  void getUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    userUid = user.uid;

    setState(() {
      userData = userDoc.data();
      if (userData != null) {
        username = 'Hello ${userData!['username']},';
      }
    });
  }

  Future<void> _initializeNotification() async {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');

      // Navigate to ChatScreen based on notification data
      if (message.data['CurrentUserFcmToken'] != null) {
        String? token = message.data['CurrentUserFcmToken'];
        if (token != null) {
          navigateToChatScreen(token, userUid);
        }
      }
    });
  }

  Future<void> navigateToChatScreen(String token, String userUid) async {
    // Fetch the user data
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('fcmtoken', isEqualTo: token)
        .get();

    final userDoc = querySnapshot.docs.firstWhere(
      (doc) => doc.data()['fcmtoken'] == token,
    );

    userData = userDoc.data();
    if (!mounted) {
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              ChatScreen(userData!, getDocumentId(userUid, userData!['uid']))),
    );
  }

  @override
  void initState() {
    getUserData();
    super.initState();
    _initializeNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        actions: [
          IconButton(
            onPressed: () {
              _openAddGroupOverlay(context);
              setState(() {});
            },
            icon: const Icon(Icons.groups),
          ),
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.exit_to_app_rounded),
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
      drawer: Drawer(
        backgroundColor: Colors.blueGrey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Update token'),
              onTap: () async {
                var newToken = await FirebaseMessaging.instance.getToken();
                var currentUser = FirebaseAuth.instance.currentUser;
                DocumentReference documentref = FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid);
                await documentref.update({
                  'fcmtoken': newToken,
                });
              },
            )
          ],
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.only(
          top: 5,
        ),
        child: UserTile(),
      ),
    );
  }
}

String getDocumentId(String uid1, String uid2) {
  List<String> uids = [uid1, uid2];
  uids.sort();
  return '${uids[0]}_${uids[1]}';
}

void _openAddGroupOverlay(BuildContext context) {
  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (ctx) => const NewGroup(),
  );
}
