class Business {
  final String name;
  final String ownerName;
  final String phone;
  final String? address;
  final String? logoUrl;
  final String? contactNumber;

  const Business({
    required this.name,
    required this.ownerName,
    required this.phone,
    this.address,
    this.logoUrl,
    this.contactNumber,
  });
}
