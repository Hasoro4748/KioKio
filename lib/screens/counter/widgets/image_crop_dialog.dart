import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class ImageCropDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropDialog({super.key, required this.imageBytes});

  static Future<File?> cropFile(BuildContext context, File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      if (!context.mounted) return null;

      final Uint8List? croppedBytes = await showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ImageCropDialog(imageBytes: bytes),
      );

      if (croppedBytes != null) {
        final String tempPath =
            '${file.parent.path}/crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File croppedFile = File(tempPath);
        await croppedFile.writeAsBytes(croppedBytes);
        return croppedFile;
      }
    } catch (e) {
      print("이미지 크롭 에러: $e");
    }
    return file; // 취소 시 원본 유지
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 550,
        height: 600,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              '썸네일 영역 잘라내기 (1:1 비율)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isCropping
                    ? null
                    : () {
                        setState(() => _isCropping = true);
                        _cropController.crop();
                      },
                icon: _isCropping
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('잘라내기 적용'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: Crop(
                    image: widget.imageBytes,
                    controller: _cropController,
                    onCropped: (result) {
                      if (result is CropSuccess) {
                        Navigator.pop(context, result.croppedImage);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이미지 자르기에 실패했습니다.')),
                          );
                          setState(() => _isCropping = false);
                        }
                      }
                    },
                    aspectRatio: 1.0, // 1:1 비율 고정
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: Colors.grey[900],
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_outlined,
                        color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '상자를 드래그하여 썸네일에 들어갈 핵심 영역을 맞추세요.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
