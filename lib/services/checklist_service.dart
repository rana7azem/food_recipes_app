import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_recipes_app/models/checklist.dart';

class ChecklistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reference to user's checklists collection
  CollectionReference _getUserChecklistsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('checklists');
  }

  // Create a new checklist
  Future<void> createChecklist(String userId, Checklist checklist) async {
    try {
      await _getUserChecklistsCollection(userId)
          .doc(checklist.id)
          .set(checklist.toMap());
    } catch (e) {
      throw Exception('Failed to create checklist: $e');
    }
  }

  // Get all checklists for a user
  Future<List<Checklist>> getChecklists(String userId) async {
    try {
      final snapshot = await _getUserChecklistsCollection(userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Checklist.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch checklists: $e');
    }
  }

  // Update an existing checklist
  Future<void> updateChecklist(String userId, Checklist checklist) async {
    try {
      await _getUserChecklistsCollection(userId)
          .doc(checklist.id)
          .update(checklist.toMap());
    } catch (e) {
      throw Exception('Failed to update checklist: $e');
    }
  }

  // Delete a checklist
  Future<void> deleteChecklist(String userId, String checklistId) async {
    try {
      await _getUserChecklistsCollection(userId).doc(checklistId).delete();
    } catch (e) {
      throw Exception('Failed to delete checklist: $e');
    }
  }

  // Toggle a checklist item's checked state
  Future<void> toggleChecklistItem(
    String userId,
    String checklistId,
    String itemId,
    bool isChecked,
  ) async {
    try {
      // Get the current checklist
      final doc =
          await _getUserChecklistsCollection(userId).doc(checklistId).get();

      if (!doc.exists) {
        throw Exception('Checklist not found');
      }

      final checklist =
          Checklist.fromMap(doc.data() as Map<String, dynamic>);

      // Find and update the item
      final updatedItems = checklist.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(isChecked: isChecked);
        }
        return item;
      }).toList();

      // Update the checklist with new items
      final updatedChecklist = Checklist(
        id: checklist.id,
        title: checklist.title,
        recipeId: checklist.recipeId,
        items: updatedItems,
        createdAt: checklist.createdAt,
        completedAt: checklist.completedAt,
      );

      await updateChecklist(userId, updatedChecklist);
    } catch (e) {
      throw Exception('Failed to toggle checklist item: $e');
    }
  }

  // Stream checklists for real-time updates (optional)
  Stream<List<Checklist>> streamChecklists(String userId) {
    return _getUserChecklistsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Checklist.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
