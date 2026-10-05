import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img; // image 패키지 사용

class ImageUtil {
  /// 이미지를 리사이징하고 JPEG로 압축하여 저장합니다.
  static Future<void> compressAndSave(
      File sourceFile, String targetPath) async {
    // 1. 파일 읽기
    Uint8List bytes = await sourceFile.readAsBytes();

    // 2. 이미지 디코딩
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return;

    // 3. 리사이징 (가로 800px 기준, 비율 유지)
    img.Image resized = img.copyResize(image, width: 800);

    // 4. JPEG 압축 (퀄리티 80% 정도면 충분합니다)
    Uint8List compressedBytes =
        Uint8List.fromList(img.encodeJpg(resized, quality: 80));

    // 5. 파일 저장
    await File(targetPath).writeAsBytes(compressedBytes);
    print("이미지 압축 완료: ${sourceFile.lengthSync()} -> ${compressedBytes.length}");
  }
}
