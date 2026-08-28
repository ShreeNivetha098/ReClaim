import 'lost_item_model.dart';
import 'found_item_model.dart';

class MatchResultModel {
  final LostItemModel lostItem;
  final FoundItemModel foundItem;
  final double matchPercentage; // 0 to 100
  final Map<String, double> attributeScores; // Breakdown per attribute

  MatchResultModel({
    required this.lostItem,
    required this.foundItem,
    required this.matchPercentage,
    required this.attributeScores,
  });
}
