import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:custom_image_crop/custom_image_crop.dart';
import '../utils/constants.dart';

class ImageCropScreen extends StatefulWidget {
  final Uint8List image;

  const ImageCropScreen({super.key, required this.image});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  late CustomImageCropController _controller;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = CustomImageCropController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onCrop() async {
    final cropped = await _controller.onCropImage();
    if (cropped != null && mounted) {
      Navigator.pop(context, cropped.bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cắt ảnh (Tỉ lệ 4:3)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary, size: 30),
            onPressed: _onCrop,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomImageCrop(
              cropController: _controller,
              image: MemoryImage(widget.image),
              shape: CustomCropShape.Ratio,
              ratio: Ratio(width: 4, height: 3),
              borderRadius: 8,
              canRotate: false,
              backgroundColor: Colors.black,
              overlayColor: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mức độ phóng lớn',
                        style: TextStyle(color: Colors.white, fontSize: 13)),
                    Text('${_zoomLevel.toStringAsFixed(1)}x',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _zoomLevel,
                  min: 1.0,
                  max: 4.0,
                  divisions: 30,
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.white24,
                  onChanged: (val) {
                    // Tính toán tỉ lệ thay đổi (relative scale)
                    final double scaleFactor = val / _zoomLevel;
                    
                    setState(() {
                      _zoomLevel = val;
                    });
                    
                    // Áp dụng tỉ lệ thay đổi thay vì giá trị tuyệt đối
                    _controller.addTransition(CropImageData(scale: scaleFactor));
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Di chuyển ảnh bằng tay và dùng thanh trượt để phóng to',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
