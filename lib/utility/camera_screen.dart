import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> _cameras;
  CameraController? _controller;
  VideoPlayerController? _videoPlayerController;
  bool _isRecording = false;
  XFile? _imageFile;
  XFile? _videoFile;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _controller = CameraController(_cameras[0], ResolutionPreset.max);

      await _controller?.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final image = await _controller!.takePicture();
      setState(() {
        _imageFile = image;
      });
      _returnResult(_imageFile!.path, true);
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      final video = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _videoFile = video;
      });
      _initializeVideoPlayer(_videoFile!.path);
      _returnResult(_videoFile!.path, false);
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  void _initializeVideoPlayer(String videoPath) {
    _videoPlayerController = VideoPlayerController.file(File(videoPath))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController?.play();
      });
  }

  void _returnResult(String path, bool isImage) {
    Navigator.pop(context, {'path': path, 'isImage': isImage});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_controller!),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.camera_alt,
                              size: 40, color: Colors.white),
                          onPressed: () async {
                            await _takePhoto();
                          },
                        ),
                        const SizedBox(width: 30),
                        IconButton(
                          icon: Icon(
                            _isRecording ? Icons.stop : Icons.videocam,
                            size: 40,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            if (_isRecording) {
                              await _stopVideoRecording();
                            } else {
                              await _startVideoRecording();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (_videoFile != null && _videoPlayerController != null)
                  Positioned.fill(
                    child: _videoPlayerController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio:
                                _videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController!),
                          )
                        : Container(),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
