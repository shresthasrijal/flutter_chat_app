import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewGroup extends StatefulWidget {
  const NewGroup({super.key});

  @override
  State<NewGroup> createState() => _NewGroupState();
}

class _NewGroupState extends State<NewGroup> {
  final _nameController = TextEditingController();
  late List<Map<String, dynamic>> userDocuments;
  final List<Map<String, dynamic>> _selectedItems = [];

  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    final user = FirebaseAuth.instance.currentUser!;

    CollectionReference collection =
        FirebaseFirestore.instance.collection('users');
    QuerySnapshot querySnapshot = await collection.get();
    List<Map<String, dynamic>> documents = querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
    return documents.where((doc) => doc['uid'] != user.uid).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() async {
    final value = await getAllDocuments();
    setState(() {
      userDocuments = value;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // void _itemChange(Map<String, dynamic> itemValue, bool isSelected) {
  //   setState(() {
  //     if (isSelected) {
  //       _selectedItems.add(itemValue);
  //     } else {
  //       _selectedItems.remove(itemValue);
  //     }
  //   });
  // }

  void _showMultiSelect(BuildContext context) async {
    final List<Map<String, dynamic>> tempSelectedItems =
        List.from(_selectedItems);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Users'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: userDocuments.map((user) {
                    return CheckboxListTile(
                      value: tempSelectedItems.contains(user),
                      title: Row(
                        children: [
                          CircleAvatar(
                            foregroundImage: NetworkImage(user['image_url']),
                          ),
                          const SizedBox(width: 8),
                          Text(user['username']),
                        ],
                      ),
                      onChanged: (isChecked) {
                        setState(() {
                          if (isChecked!) {
                            tempSelectedItems.add(user);
                          } else {
                            tempSelectedItems.remove(user);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    setState(() {
                      _selectedItems.clear();
                      _selectedItems.addAll(tempSelectedItems);
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitData() async {
    final enteredName = _nameController.text.trim();

    if (enteredName.isEmpty ||
        enteredName.length < 3 ||
        _selectedItems.isEmpty ||
        _selectedItems.length < 2) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid Input'),
          content: const Text(
              'Please make sure you enter a valid group name or selected atleast two users.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Okay'),
            ),
          ],
        ),
      );
      return;
    } else {
      final user = FirebaseAuth.instance.currentUser!;
      List<String> uidList = [
        user.uid,
        ..._selectedItems.map((value) => value['uid'])
      ]..sort();
      String documentId = uidList.join('_');
      Map<String, dynamic> data = {
        'groupname': enteredName,
        'users': uidList,
        'documentId': documentId,
      };
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(documentId)
          .set(data)
          .then((_) {
        print('Group created successfuly!');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            maxLength: 25,
            decoration: const InputDecoration(label: Text('Group name')),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              _showMultiSelect(context);
            },
            child: const Text('Select Users'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _submitData();
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Discard'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
