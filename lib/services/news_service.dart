import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'news';

  Stream<List<NewsModel>> getNewsStream({
    String? category,
    String? locationScope,
    String? state,
    String? district,
  }) {
    Query query = _firestore.collection(_collectionPath);
    
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    if (locationScope != null) {
      query = query.where('locationScope', isEqualTo: locationScope);
    }

    if (state != null && state != 'All') {
      query = query.where('state', isEqualTo: state);
    }

    if (district != null && district != 'All') {
      query = query.where('district', isEqualTo: district);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NewsModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> addNews(NewsModel news) async {
    await _firestore.collection(_collectionPath).add(news.toMap());
  }

  Future<void> updateNews(NewsModel news) async {
    await _firestore.collection(_collectionPath).doc(news.id).update(news.toMap());
  }

  Future<void> deleteNews(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }

  Future<void> toggleLike(String newsId, String userId, bool isCurrentlyLiked) async {
    final docRef = _firestore.collection(_collectionPath).doc(newsId);
    if (isCurrentlyLiked) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([userId])
      });
    }
  }

  Stream<List<NewsModel>> getNewsByCreator(String creatorUid) {
    return _firestore
        .collection(_collectionPath)
        .where('createdBy', isEqualTo: creatorUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NewsModel.fromMap(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }
}
