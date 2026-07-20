import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class CloudinaryService {
  final String cloudName = 'delnnzcph';
  final String uploadPreset = 'flutter_upload';

  /// Upload image and return BOTH secure_url and public_id
  Future<Map<String, dynamic>?> uploadImage() async {
    final picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return uploadBytes(bytes, filename: image.name);
  }

  /// Capture from camera and upload to Cloudinary.
  Future<Map<String, dynamic>?> captureAndUpload() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return uploadBytes(bytes, filename: image.name);
  }

  Future<Map<String, dynamic>?> uploadBytes(
    List<int> bytes, {
    required String filename,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    );

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      var jsonResp = json.decode(respStr);

      return {
        "secure_url": jsonResp['secure_url'],
        "public_id": jsonResp['public_id'],
      };
    } else {
      print('Upload failed: ${response.statusCode}');
      return null;
    }
  }

  /// Delete image from Cloudinary using public_id
  Future<void> deleteImage(String publicId) async {
    var url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
    );

    await http.post(
      url,
      body: {
        "public_id": publicId,
        "upload_preset": uploadPreset,
      },
    );
  }
}
