/// Units a shopkeeper can sell an item in. Kept short and shop-friendly
/// rather than exhaustive.
const List<String> kItemUnits = ['piece', 'kg', 'gram', 'litre', 'ml', 'dozen', 'packet', 'box', 'meter'];

class Item {
  final String id;
  final String name;

  /// Price for one [unit] of this item, e.g. Rs 500 per kg.
  final double price;
  final String unit;

  const Item({required this.id, required this.name, required this.price, required this.unit});
}

/// Trims a quantity like 5.000 down to "5" and 2.500 down to "2.5".
String formatQuantity(double q) {
  var s = q.toStringAsFixed(3);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}
