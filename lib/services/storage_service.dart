import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadNewsImage(File file) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'news_images/$timestamp.jpg';
      
      final ref = _storage.ref().child(path);
      final snapshot = await ref.putFile(file);
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw 'Firebase Storage Error [${e.code}]: ${e.message}';
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }
}
