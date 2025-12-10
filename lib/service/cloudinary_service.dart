import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'davhxsess'; // Your cloud name
  static const String uploadPreset = 'empimages'; // Your upload preset

  /// Sanitizes filename/public_id to remove invalid characters
  static String _sanitizePublicId(String input) {
    return input
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(' ', '_')
        .trim();
  }

  /// Generates a unique public_id using timestamp
  static String _generatePublicId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'checkin_$timestamp';
  }

  static Future<String> uploadImage(dynamic imageFile) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['public_id'] = _generatePublicId();
      request.fields['folder'] = 'employee_checkins';

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        request.fields['file'] = 'data:image/jpeg;base64,$base64Image';
      } else {
        final file = imageFile as File;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'] as String;
      } else {
        final errorData = json.decode(responseString);
        throw Exception(
          'Upload failed (${response.statusCode}): ${errorData['error']?['message'] ?? responseString}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  static Future<String> uploadImageWithName(
    dynamic imageFile,
    String name,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;

      final sanitizedName = _sanitizePublicId(name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      request.fields['public_id'] = '${sanitizedName}_$timestamp';
      request.fields['folder'] = 'employee_checkins';

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        request.fields['file'] = 'data:image/jpeg;base64,$base64Image';
      } else {
        final file = imageFile as File;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'] as String;
      } else {
        final errorData = json.decode(responseString);
        throw Exception(
          'Upload failed (${response.statusCode}): ${errorData['error']?['message'] ?? responseString}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload document (PDF, DOC, DOCX, Images) to Cloudinary
  /// Supports both File (mobile) and Uint8List (web)
  static Future<String> uploadDocument({
    File? file,
    Uint8List? bytes,
    required String fileName,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
      );

      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;

      // Generate unique public_id for document
      final sanitizedName = _sanitizePublicId(
        fileName.split('.').first,
      ); // Remove extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      request.fields['public_id'] = '${sanitizedName}_$timestamp';
      request.fields['folder'] = 'employee_documents';
      request.fields['resource_type'] = 'raw';

      if (kIsWeb && bytes != null) {
        // Web: Upload using bytes
        final base64Doc = base64Encode(bytes);
        final extension = fileName.split('.').last.toLowerCase();
        String mimeType;

        switch (extension) {
          case 'pdf':
            mimeType = 'application/pdf';
            break;
          case 'doc':
            mimeType = 'application/msword';
            break;
          case 'docx':
            mimeType =
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            break;
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          default:
            mimeType = 'application/octet-stream';
        }

        request.fields['file'] = 'data:$mimeType;base64,$base64Doc';
      } else if (file != null) {
        // Mobile: Upload using file path
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      } else {
        throw Exception('No file or bytes provided for upload');
      }

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'] as String;
      } else {
        final errorData = json.decode(responseString);
        throw Exception(
          'Upload failed (${response.statusCode}): ${errorData['error']?['message'] ?? responseString}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }
}
