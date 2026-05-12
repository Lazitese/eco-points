import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class MealCameraScreen extends StatefulWidget {
  const MealCameraScreen({super.key});

  @override
  State<MealCameraScreen> createState() => _MealCameraScreenState();
}

class _MealCameraScreenState extends State<MealCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _uploading = false;
  File? _capturedFile;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (mounted) setState(() { _initializing = true; _error = null; });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() {
          _error = 'No cameras found on this device.';
          _initializing = false;
        });
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await ctrl.initialize();
      await ctrl.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (mounted) {
        _controller = ctrl;
        setState(() => _initializing = false);
      } else {
        ctrl.dispose();
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Camera error: ${e.toString()}';
        _initializing = false;
      });
    }
  }

  Future<void> _takePicture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (ctrl.value.isTakingPicture) return;

    try {
      final xFile = await ctrl.takePicture();
      if (mounted) setState(() => _capturedFile = File(xFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to capture: $e'),
              backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _uploadAndSave() async {
    if (_capturedFile == null) return;
    setState(() => _uploading = true);

    try {
      final photoUrl =
          await SupabaseService.uploadVerificationPhoto(_capturedFile!);
      await SupabaseService.insertMealActivity(photoUrl: photoUrl, points: 10);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Photo submitted for verification!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: AppTheme.errorRed),
        );
        setState(() => _uploading = false);
      }
    }
  }

  void _retake() => setState(() => _capturedFile = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Extend body behind the AppBar so camera fills the screen
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verify Meal',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: _capturedFile != null
          ? _PreviewView(
              file: _capturedFile!,
              uploading: _uploading,
              onRetake: _retake,
              onConfirm: _uploadAndSave,
            )
          : _CameraView(
              controller: _controller,
              initializing: _initializing,
              error: _error,
              onCapture: _takePicture,
            ),
    );
  }
}

// ── Camera viewfinder ──────────────────────────────────────────────────────────

class _CameraView extends StatelessWidget {
  const _CameraView({
    required this.controller,
    required this.initializing,
    required this.error,
    required this.onCapture,
  });

  final CameraController? controller;
  final bool initializing;
  final String? error;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    if (initializing) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(error!,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen camera preview
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.previewSize!.height,
              height: controller!.value.previewSize!.width,
              child: CameraPreview(controller!),
            ),
          ),
        ),

        // Darkened corners (vignette)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),

        // Meal framing guide
        Center(
          child: Container(
            width: size.width * 0.72,
            height: size.width * 0.72,
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppTheme.accentGreen.withValues(alpha: 0.8),
                  width: 2.5),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),

        // Instruction pill
        Positioned(
          top: MediaQuery.of(context).padding.top + 72,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Frame your meal in the box',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),

        // Shutter button + label
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onCapture,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Camera only — gallery disabled',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Preview after capture ──────────────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.file,
    required this.uploading,
    required this.onRetake,
    required this.onConfirm,
  });

  final File file;
  final bool uploading;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-screen photo
        Image.file(file, fit: BoxFit.cover),

        // Bottom gradient so buttons are always readable
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 220 + bottomPad,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // Upload overlay
        if (uploading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Uploading…',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          // Buttons — padded above home indicator
          Positioned(
            bottom: bottomPad + 32,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'Submit for Verification',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: 0.2),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onRetake,
                  child: const Text(
                    'Retake Photo',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
