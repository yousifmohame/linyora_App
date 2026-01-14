class ShippingCompany {
  final int id;
  final String name;
  final double shippingCost;

  ShippingCompany({
    required this.id,
    required this.name,
    required this.shippingCost,
  });

  factory ShippingCompany.fromJson(Map<String, dynamic> json) {
    return ShippingCompany(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      shippingCost: double.tryParse(json['shipping_cost']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'shipping_cost': shippingCost,
  };
}