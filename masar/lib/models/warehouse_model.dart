/// نموذج فئة/تصنيف المواد المخزنية
class WarehouseCategoryModel {
  final int id;
  final String name;
  final String? description;

  WarehouseCategoryModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory WarehouseCategoryModel.fromJson(Map<String, dynamic> json) {
    return WarehouseCategoryModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      if (description != null) 'description': description,
    };
  }
}

/// نموذج صنف/مادة في المخزن
class WarehouseItemModel {
  final int id;
  final String name;
  final String? code;
  final int? categoryId;
  final String? categoryName;
  final String unit; // كيس، طن، متر، برميل...
  final double currentStock;
  final double minStock;
  final double unitPrice;
  final String status; // active, inactive
  final String? location;

  WarehouseItemModel({
    required this.id,
    required this.name,
    this.code,
    this.categoryId,
    this.categoryName,
    this.unit = 'وحدة',
    this.currentStock = 0.0,
    this.minStock = 0.0,
    this.unitPrice = 0.0,
    this.status = 'active',
    this.location,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isLowStock => currentStock <= minStock;
  double get totalValue => currentStock * unitPrice;

  factory WarehouseItemModel.fromJson(Map<String, dynamic> json) {
    return WarehouseItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString() ?? json['category']?.toString(),
      unit: json['unit']?.toString() ?? 'وحدة',
      currentStock: double.tryParse(json['current_stock']?.toString() ?? json['stock']?.toString() ?? '0') ?? 0.0,
      minStock: double.tryParse(json['min_stock']?.toString() ?? '0') ?? 0.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString().toLowerCase() ?? 'active',
      location: json['location']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      if (code != null) 'code': code,
      if (categoryId != null) 'category_id': categoryId,
      'unit': unit,
      'current_stock': currentStock,
      'min_stock': minStock,
      'unit_price': unitPrice,
      'status': status,
      if (location != null) 'location': location,
    };
  }
}

/// نموذج حركة مخزنية (صرف لموقع، توريد، إرجاع)
class WarehouseMoveModel {
  final int id;
  final int itemId;
  final String? itemName;
  final String moveType; // in (توريد), out (صرف), return (إرجاع)
  final double quantity;
  final int? siteId;
  final String? siteName;
  final String? notes;
  final String? createdAt;
  final String? createdBy;

  WarehouseMoveModel({
    required this.id,
    required this.itemId,
    this.itemName,
    required this.moveType,
    required this.quantity,
    this.siteId,
    this.siteName,
    this.notes,
    this.createdAt,
    this.createdBy,
  });

  String get moveTypeLabel {
    switch (moveType.toLowerCase()) {
      case 'in':
        return 'توريد إلى المخزن';
      case 'out':
        return 'صرف لمشروع';
      case 'return':
        return 'إرجاع للمخزن';
      default:
        return moveType;
    }
  }

  factory WarehouseMoveModel.fromJson(Map<String, dynamic> json) {
    return WarehouseMoveModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      itemId: int.tryParse(json['item_id']?.toString() ?? '0') ?? 0,
      itemName: json['item_name']?.toString() ?? json['item']?.toString(),
      moveType: json['move_type']?.toString().toLowerCase() ?? 'out',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      siteId: int.tryParse(json['site_id']?.toString() ?? ''),
      siteName: json['site_name']?.toString() ?? json['site']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'move_type': moveType,
      'quantity': quantity,
      if (siteId != null) 'site_id': siteId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
