import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:simplytranslate_mobile/data.dart';

List<CameraDescription> cameras = [];

List<FlashMode> modes = [
  FlashMode.off,
  FlashMode.torch,
];
var currentMode = modes[0];

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() {
    return _CameraScreenState();
  }
}

void logError(String code, String? message) {
  if (message != null)
    print('Error: $code\nError Message: $message');
  else
    print('Error: $code');
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  XFile? imageFile;
  late AnimationController _flashModeControlRowAnimationController;

  @override
  void initState() {
    super.initState();
    onNewCameraSelected();
    _ambiguate(WidgetsBinding.instance)?.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _ambiguate(WidgetsBinding.instance)?.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized)
      return;

    if (state == AppLifecycleState.inactive)
      cameraController.dispose();
    else if (state == AppLifecycleState.resumed) onNewCameraSelected();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    late IconData flashIcon;
    switch (currentMode) {
      case FlashMode.off:
        flashIcon = Icons.flash_off;
        break;
      case FlashMode.torch:
        flashIcon = Icons.flash_on;
        break;
      default:
        flashIcon = Icons.flash_off;
    }
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(flashIcon),
            onPressed: controller != null ? onSetFlashModeButtonPressed : null,
          ),
        ],
      ),
      key: _scaffoldKey,
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Center(child: _cameraPreviewWidget()),
              decoration: BoxDecoration(color: Colors.black),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _captureControlRowWidget(),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    return CameraPreview(
      controller!,
      child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => onViewFinderTap(details, constraints),
        );
      }),
    );
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    final CameraController? cameraController = controller;

    return FloatingActionButton(
      child: Icon(
        Icons.camera_alt,
        color: theme == Brightness.dark ? Colors.white : Colors.black,
      ),
      onPressed: cameraController != null &&
              cameraController.value.isInitialized &&
              !cameraController.value.isRecordingVideo
          ? () async {
              final CameraController? cameraController = controller;
              if (cameraController == null ||
                  !cameraController.value.isInitialized) {
                showInSnackBar('Error: select a camera first.');
                return;
              }

              if (cameraController.value.isTakingPicture) return;

              try {
                XFile file = await cameraController.takePicture();
                Navigator.pop(context, file);
              } on CameraException catch (e) {
                _showCameraException(e);
                return;
              }
            }
          : null,
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).

  void showInSnackBar(String message) {
    // ignore: deprecated_member_use
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) return;

    final CameraController cameraController = controller!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  void onNewCameraSelected() async {
    final CameraController cameraController = CameraController(
      cameras[0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError)
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
    });

    try {
      if (!cameraController.value.isInitialized)
        await cameraController.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    if (mounted) setState(() {});
  }

  void onSetFlashModeButtonPressed() {
    int i = modes.indexOf(currentMode);
    currentMode = modes[(i + 1) % (modes.length)];
    setFlashMode().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> setFlashMode() async {
    if (controller == null) return;

    try {
      await controller!.setFlashMode(currentMode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

// TODO(ianh): Remove this once we roll stable in late 2021.
T? _ambiguate<T>(T? value) => value;
