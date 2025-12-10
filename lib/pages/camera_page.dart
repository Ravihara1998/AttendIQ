import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../style/employee_style.dart';
import '../service/cloudinary_service.dart';
import '../service/checkin_service.dart';
import '../pages/employee_model.dart';
import '../pages/checkin_model.dart';

class CameraPage extends StatefulWidget {
  final Employee employee;

  const CameraPage({super.key, required this.employee});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  final _checkInService = CheckInService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      CameraDescription selectedCamera;
      try {
        selectedCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        selectedCamera = _cameras!.first;
        debugPrint('Front camera not found, using: ${selectedCamera.name}');
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        EmployeeStyle.showSnackBar(context, 'Camera error: $e', isError: true);
        Navigator.of(context).pop();
      }
    }
  }

  Future<File> _compressImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      // Reduced size and quality for faster upload
      final resized = img.copyResize(image, width: 400);
      final compressed = img.encodeJpg(resized, quality: 50);
      final compressedFile = File(imageFile.path)..writeAsBytesSync(compressed);

      debugPrint(
        'Image compressed: ${bytes.length} -> ${compressed.length} bytes',
      );
      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }

  Future<void> _captureAndSave() async {
    if (_isProcessing || _cameraController == null) return;

    setState(() => _isProcessing = true);

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();

      // Show processing dialog after capture
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildProcessingDialog('Thank You...'),
        );
      }

      // Compress and upload in parallel for web, sequential for mobile
      String capturedImageUrl;

      if (kIsWeb) {
        // Web: upload directly
        capturedImageUrl = await CloudinaryService.uploadImage(imageFile);
      } else {
        // Mobile: compress then upload
        final processedImage = await _compressImage(File(imageFile.path));
        capturedImageUrl = await CloudinaryService.uploadImage(processedImage);
      }

      // Create and save check-in record
      final checkIn = CheckIn(
        empId: widget.employee.empId,
        name: widget.employee.name,
        nickName: widget.employee.name,
        department: widget.employee.department,
        capturedImageUrl: capturedImageUrl,
        originalImageUrl: widget.employee.userImageUrl,
      );

      await _checkInService.addCheckIn(checkIn);

      if (mounted) {
        Navigator.of(context).pop(); // Close processing dialog
        // Directly return to employee page with success
        Navigator.of(
          context,
        ).pop({'success': true, 'employeeName': widget.employee.name});
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close processing dialog
        _showErrorDialog('Error', 'Failed to save check-in: $e');
      }
      setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(EmployeeStyle.spacingL),
          decoration: EmployeeStyle.getCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: EmployeeStyle.errorColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: EmployeeStyle.errorColor,
                ),
              ),
              const SizedBox(height: EmployeeStyle.spacingM),
              Text(
                title,
                style: EmployeeStyle.headingMedium.copyWith(
                  color: EmployeeStyle.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EmployeeStyle.spacingS),
              Text(
                message,
                style: EmployeeStyle.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: EmployeeStyle.spacingM),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EmployeeStyle.errorColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text('Try Again', style: EmployeeStyle.buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingDialog(String message) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(EmployeeStyle.spacingL),
        decoration: EmployeeStyle.getCardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: EmployeeStyle.primaryColor),
            const SizedBox(height: EmployeeStyle.spacingM),
            Text(
              message,
              style: EmployeeStyle.headingSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmployeeStyle.backgroundColor,
      body: _isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(child: CameraPreview(_cameraController!)),
                Positioned.fill(
                  child: CustomPaint(painter: FaceGuidePainter()),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: _isProcessing
                              ? null
                              : () => Navigator.pop(context),
                        ),
                        Text(
                          'Take Photo',
                          style: EmployeeStyle.headingSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(EmployeeStyle.spacingL),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: EmployeeStyle.primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Position yourself and tap to capture',
                                  style: EmployeeStyle.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: EmployeeStyle.spacingL),
                        GestureDetector(
                          onTap: _isProcessing ? null : _captureAndSave,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: _isProcessing
                                  ? Colors.grey
                                  : EmployeeStyle.primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: EmployeeStyle.primaryColor.withOpacity(
                                    0.5,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: _isProcessing
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        const SizedBox(height: EmployeeStyle.spacingL),
                        Text(
                          widget.employee.name,
                          style: EmployeeStyle.headingSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.employee.empId,
                          style: EmployeeStyle.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: EmployeeStyle.primaryColor,
                  ),
                  const SizedBox(height: EmployeeStyle.spacingM),
                  Text(
                    'Initializing Camera...',
                    style: EmployeeStyle.bodyLarge,
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}

class FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EmployeeStyle.primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2.5),
      width: size.width * 0.6,
      height: size.height * 0.4,
    );

    canvas.drawOval(ovalRect, paint);

    final cornerPaint = Paint()
      ..color = EmployeeStyle.primaryColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;
    final corners = [
      [
        Offset(ovalRect.left, ovalRect.top),
        Offset(ovalRect.left + cornerLength, ovalRect.top),
      ],
      [
        Offset(ovalRect.left, ovalRect.top),
        Offset(ovalRect.left, ovalRect.top + cornerLength),
      ],
      [
        Offset(ovalRect.right, ovalRect.top),
        Offset(ovalRect.right - cornerLength, ovalRect.top),
      ],
      [
        Offset(ovalRect.right, ovalRect.top),
        Offset(ovalRect.right, ovalRect.top + cornerLength),
      ],
      [
        Offset(ovalRect.left, ovalRect.bottom),
        Offset(ovalRect.left + cornerLength, ovalRect.bottom),
      ],
      [
        Offset(ovalRect.left, ovalRect.bottom),
        Offset(ovalRect.left, ovalRect.bottom - cornerLength),
      ],
      [
        Offset(ovalRect.right, ovalRect.bottom),
        Offset(ovalRect.right - cornerLength, ovalRect.bottom),
      ],
      [
        Offset(ovalRect.right, ovalRect.bottom),
        Offset(ovalRect.right, ovalRect.bottom - cornerLength),
      ],
    ];

    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
