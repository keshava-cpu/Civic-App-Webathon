import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:civic_contribution/application/providers/report_flow_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _initialized = false;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No camera available');
        return;
      }
      await _setupController(_cameras.first);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (mounted) setState(() => _initialized = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _setupController(controller.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_initialized || _capturing) return;

    setState(() => _capturing = true);

    try {
      final xFile = await _controller!.takePicture();
      final file = File(xFile.path);
      if (!mounted) return;

      await context.read<ReportFlowProvider>().onPhotoCaptured(file);
      if (mounted) context.push('/report/form');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    await context.read<ReportFlowProvider>().onPhotoCaptured(file);
    if (mounted) context.push('/report/form');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Report Issue'),
      ),
      body: _error != null
          ? _buildError()
          : !_initialized
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _buildCamera(),
    );
  }

  Widget _buildCamera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        // Grid overlay
        Positioned.fill(
          child: CustomPaint(painter: _GridPainter()),
        ),
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined,
                      color: Colors.white, size: 32),
                ),
                GestureDetector(
                  onTap: _capturing ? null : _capture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _capturing ? Colors.grey : Colors.white,
                    ),
                    child: _capturing
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                ),
                if (_cameras.length > 1)
                  IconButton(
                    onPressed: () async {
                      final current = _controller!.description;
                      final next = _cameras.firstWhere(
                        (c) => c != current,
                        orElse: () => _cameras.first,
                      );
                      await _controller?.dispose();
                      await _setupController(next);
                    },
                    icon: const Icon(Icons.flip_camera_ios_outlined,
                        color: Colors.white, size: 32),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white60, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Camera unavailable',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: const TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pick from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 0.5;

    canvas.drawLine(
        Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

