import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CCCDPhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  static const String _photoFolder = 'photos';

  /// Pick image from camera or gallery
  Future<File?> pickImage({required bool fromCamera}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Upload CCCD photo to Firebase Storage
  Future<String?> uploadCCCDPhoto(File imageFile) async {
    try {
      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference ref = _storage.ref().child('$_photoFolder/$fileName');

      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading CCCD photo: $e');
      return null;
    }
  }

  /// Delete photo from Firebase Storage
  Future<bool> deletePhoto(String photoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }
}
