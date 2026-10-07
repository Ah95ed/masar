class WarehouseCategory {
  final int id;
  final String name;
  final String? description;

  WarehouseCategory({
    required this.id,
    required this.name,
    this.description,
  });

  factory WarehouseCategory.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return WarehouseCategory(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
  };
}

class WarehouseItem {
  final int id;
  final String code;
  final String name;
  final int? categoryId;
  final String? categoryName;
  final String unit;
  final double quantity;
  final double minQuantity;
  final double unitPrice;
  final String? location;
  final int isActive;
  final String? notes;

  WarehouseItem({
    required this.id,
    required this.code,
    required this.name,
    this.categoryId,
    this.categoryName,
    required this.unit,
    required this.quantity,
    this.minQuantity = 0.0,
    this.unitPrice = 0.0,
    this.location,
    required this.isActive,
    this.notes,
  });

  bool get isLowStock => quantity <= minQuantity;
  bool get active => isActive == 1;

  factory WarehouseItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, [int fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    double parseDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return WarehouseItem(
      id: parseInt(json['id']),
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryId: json['category_id'] != null ? parseInt(json['category_id']) : null,
      categoryName: json['category_name']?.toString(),
      unit: json['unit']?.toString() ?? 'قطعة',
      quantity: parseDouble(json['quantity']),
      minQuantity: parseDouble(json['min_quantity']),
      unitPrice: parseDouble(json['unit_price']),
      location: json['location']?.toString(),
      isActive: parseInt(json['is_active'], 1),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    if (categoryId != null) 'category_id': categoryId,
    'unit': unit,
    'quantity': quantity,
    'min_quantity': minQuantity,
    'unit_price': unitPrice,
    if (location != null) 'location': location,
    'is_active': isActive,
    if (notes != null) 'notes': notes,
  };
}
