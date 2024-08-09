import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projj12_chatapp/screens/chat.dart';

class UserTile extends StatefulWidget {
  const UserTile({super.key});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  List<Map<String, dynamic>> documents = [];
  late User user;

  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    List<Map<String, dynamic>> usersList = await getAllUserDocuments('users');
    List<Map<String, dynamic>> groupsList = await getAllGroupDocuments('groups');
    return [...usersList, ...groupsList];
  }

  Future<List<Map<String, dynamic>>> getAllUserDocuments(
      String collectionName) async {
    CollectionReference collection =
        FirebaseFirestore.instance.collection(collectionName);
    QuerySnapshot querySnapshot = await collection.get();
    List<Map<String, dynamic>> documents = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
    return documents
        .where((doc) => doc['uid'] != user.uid)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAllGroupDocuments(
      String collectionName) async {
    CollectionReference collection =
        FirebaseFirestore.instance.collection(collectionName);
    QuerySnapshot querySnapshot = await collection.get();
    List<Map<String, dynamic>> allGroups = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
    // Filter groups where current user UID is in the userList
    List<Map<String, dynamic>> filteredGroups = [];
    for (var group in allGroups) {
      List<dynamic> userList = group['users'] ?? [];
      if (userList.contains(user.uid)) {
        filteredGroups.add(group);
      }
    }
    return filteredGroups;
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getAllDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No users available to message.'));
        } else {
          List<Map<String, dynamic>> documents = snapshot.data!;
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              bool isGroup = documents[index].containsKey('users');
              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Material(
                  elevation: 4.0,
                  surfaceTintColor: const Color.fromARGB(97, 3, 168, 244),
                  child: ListTile(
                    leading: CircleAvatar(
                      foregroundImage: isGroup
                          ? null
                          : NetworkImage(documents[index]['image_url']),
                      child: isGroup ? const Icon(Icons.group) : null,
                    ),
                    title: Text(isGroup
                        ? documents[index]['groupname']
                        : documents[index]['username']),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) {
                            return isGroup
                                ? ChatScreen.group(documents[index],
                                    documents[index]['documentId'])
                                : ChatScreen(
                                    documents[index],
                                    getDocumentId(
                                      user.uid,
                                      documents[index]['uid'],
                                    ),
                                  );
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}

String getDocumentId(String uid1, String uid2) {
  List<String> uids = [uid1, uid2];
  uids.sort();
  return '${uids[0]}_${uids[1]}';
}
