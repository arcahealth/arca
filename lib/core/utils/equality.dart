import 'package:collection/collection.dart';

/// Centralized collection equality singletons reused across Arca.
///
/// Prevents redundant allocations and provides standard O(N) element comparison
/// singletons for models, state objects, and database DTOs.
abstract final class ArcaEquality {
  /// Constant equality comparator for [List] containing [String] elements.
  static const stringList = ListEquality<String>();

  /// Constant equality comparator for generic [List] collections using element equality.
  static const list = ListEquality<dynamic>();

  /// Constant equality comparator for generic [Set] collections using element equality.
  static const set = SetEquality<dynamic>();

  /// Constant equality comparator for generic [Map] collections using key/value equality.
  static const map = MapEquality<dynamic, dynamic>();
}
