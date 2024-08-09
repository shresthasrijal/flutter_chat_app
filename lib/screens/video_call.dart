import 'package:flutter/material.dart';
import 'package:agora_uikit/agora_uikit.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen(this.documentId, this.isGroup, {super.key});
  final String documentId;
  final bool isGroup;
  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late AgoraClient _client;

  @override
  void initState() {
    super.initState();
    _client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: '', //add ur own
        channelName: '', // add ur own
        // widget.documentId,
        tempToken: '', // add ur own
      ),
    );
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      await _client.initialize();
      print('Agora client initialized successfully.');
    } catch (e) {
      print('Error initializing Agora client: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Video Call'),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              AgoraVideoViewer(
                client: _client,
                showNumberOfUsers: true,
                disabledVideoWidget: Container(
                  color: Colors.black,
                  child: const Icon(Icons.videocam_off_outlined),
                ),
                layoutType: !widget.isGroup ? Layout.oneToOne : Layout.floating,
              ),
              AgoraVideoButtons(client: _client),
            ],
          ),
        ),
      ),
    );
  }
}
