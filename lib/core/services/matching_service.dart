import '../../shared/models/lost_item_model.dart';
import '../../shared/models/found_item_model.dart';
import '../../shared/models/match_result_model.dart';

class MatchingService {
  // Configurable weights (must sum to 100)
  static const double categoryWeight = 25.0;
  static const double nameWeight = 25.0;
  static const double brandWeight = 15.0;
  static const double colourWeight = 10.0;
  static const double locationWeight = 15.0;
  static const double dateWeight = 10.0;

  /// Calculate match percentage between a lost item and a found item
  static MatchResultModel calculateMatch({
    required LostItemModel lostItem,
    required FoundItemModel foundItem,
  }) {
    // 1. Category Score (25%)
    final categoryScore = _calculateCategoryScore(lostItem.category, foundItem.category);

    // 2. Name & Description Keyword Score (25%)
    final nameScore = _calculateNameKeywordScore(
      lostName: lostItem.itemName,
      lostDesc: lostItem.description,
      foundName: foundItem.itemName,
      foundDesc: foundItem.description,
    );

    // 3. Brand Score (15%)
    final brandScore = _calculateBrandScore(lostItem.brand, foundItem.brand);

    // 4. Colour Score (10%)
    final colourScore = _calculateColourScore(lostItem.colour, foundItem.colour);

    // 5. Location Score (15%)
    final locationScore = _calculateLocationScore(lostItem.locationLost, foundItem.locationFound);

    // 6. Date Proximity Score (10%)
    final dateScore = _calculateDateProximityScore(lostItem.dateLost, foundItem.dateFound);

    final totalScore = categoryScore + nameScore + brandScore + colourScore + locationScore + dateScore;

    return MatchResultModel(
      lostItem: lostItem,
      foundItem: foundItem,
      matchPercentage: double.parse(totalScore.toStringAsFixed(1)),
      attributeScores: {
        'Category': categoryScore,
        'Item Name / Keywords': nameScore,
        'Brand': brandScore,
        'Colour': colourScore,
        'Location': locationScore,
        'Date': dateScore,
      },
    );
  }

  /// Finds potential matches for a lost item from a list of found items,
  /// sorted descending by match percentage.
  static List<MatchResultModel> findMatchesForLostItem({
    required LostItemModel lostItem,
    required List<FoundItemModel> foundItems,
    double minThreshold = 40.0,
  }) {
    final results = <MatchResultModel>[];

    for (final foundItem in foundItems) {
      if (foundItem.status.toUpperCase() != 'ACTIVE' && foundItem.status.toUpperCase() != 'MATCHED') {
        continue;
      }
      final match = calculateMatch(lostItem: lostItem, foundItem: foundItem);
      if (match.matchPercentage >= minThreshold) {
        results.add(match);
      }
    }

    results.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return results;
  }

  // Helper score functions

  static double _calculateCategoryScore(String cat1, String cat2) {
    if (cat1.trim().isEmpty || cat2.trim().isEmpty) return 0.0;
    if (cat1.trim().toLowerCase() == cat2.trim().toLowerCase()) {
      return categoryWeight;
    }
    return 0.0;
  }

  static double _calculateNameKeywordScore({
    required String lostName,
    required String lostDesc,
    required String foundName,
    required String foundDesc,
  }) {
    final lostText = '$lostName $lostDesc'.toLowerCase();
    final foundText = '$foundName $foundDesc'.toLowerCase();

    final lostTokens = _extractTokens(lostText);
    final foundTokens = _extractTokens(foundText);

    if (lostTokens.isEmpty || foundTokens.isEmpty) return 0.0;

    final commonTokens = lostTokens.intersection(foundTokens);

    // Jaccard similarity index
    final unionCount = lostTokens.union(foundTokens).length;
    if (unionCount == 0) return 0.0;

    final similarityRatio = commonTokens.length / unionCount;

    // Bonus for direct substring match of main title
    double titleBonus = 0.0;
    if (foundName.toLowerCase().contains(lostName.toLowerCase()) ||
        lostName.toLowerCase().contains(foundName.toLowerCase())) {
      titleBonus = 0.3;
    }

    final finalRatio = (similarityRatio + titleBonus).clamp(0.0, 1.0);
    return double.parse((finalRatio * nameWeight).toStringAsFixed(1));
  }

  static double _calculateBrandScore(String brand1, String brand2) {
    final b1 = brand1.trim().toLowerCase();
    final b2 = brand2.trim().toLowerCase();

    if (b1.isEmpty || b2.isEmpty || b1 == 'n/a' || b2 == 'n/a' || b1 == 'unknown' || b2 == 'unknown') {
      return brandWeight * 0.5; // Partial neutral credit if unknown
    }

    if (b1 == b2) return brandWeight;

    if (b1.contains(b2) || b2.contains(b1)) {
      return brandWeight * 0.8;
    }

    return 0.0;
  }

  static double _calculateColourScore(String col1, String col2) {
    final c1Tokens = _extractTokens(col1.toLowerCase());
    final c2Tokens = _extractTokens(col2.toLowerCase());

    if (c1Tokens.isEmpty || c2Tokens.isEmpty) return colourWeight * 0.5;

    final common = c1Tokens.intersection(c2Tokens);
    if (common.isNotEmpty) {
      return colourWeight;
    }
    return 0.0;
  }

  static double _calculateLocationScore(String loc1, String loc2) {
    final l1 = loc1.trim().toLowerCase();
    final l2 = loc2.trim().toLowerCase();

    if (l1.isEmpty || l2.isEmpty) return 0.0;

    if (l1 == l2) return locationWeight;

    final l1Tokens = _extractTokens(l1);
    final l2Tokens = _extractTokens(l2);

    final common = l1Tokens.intersection(l2Tokens);
    if (common.isNotEmpty) {
      final ratio = common.length / (l1Tokens.length > l2Tokens.length ? l1Tokens.length : l2Tokens.length);
      return double.parse((ratio * locationWeight).toStringAsFixed(1));
    }

    return 0.0;
  }

  static double _calculateDateProximityScore(DateTime d1, DateTime d2) {
    final diffDays = d1.difference(d2).inDays.abs();

    if (diffDays <= 1) {
      return dateWeight; // 100% of date weight
    } else if (diffDays <= 3) {
      return dateWeight * 0.8;
    } else if (diffDays <= 7) {
      return dateWeight * 0.5;
    } else if (diffDays <= 14) {
      return dateWeight * 0.3;
    } else {
      return dateWeight * 0.1;
    }
  }

  static Set<String> _extractTokens(String text) {
    final stopWords = {
      'a', 'an', 'the', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'is', 'was', 'my', 'i', 'it'
    };
    final cleaned = text.replaceAll(RegExp(r'[^\w\s]'), ' ');
    final words = cleaned.split(RegExp(r'\s+'));
    return words.where((w) => w.length > 1 && !stopWords.contains(w)).toSet();
  }
}
