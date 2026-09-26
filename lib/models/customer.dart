String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
  return parts.map((w) => w[0]).join().toUpperCase();
}

class Customer {
  final String id;
  final String name;
  final String phone;

  const Customer({required this.id, required this.name, required this.phone});

  String get initials => initialsOf(name);
}
