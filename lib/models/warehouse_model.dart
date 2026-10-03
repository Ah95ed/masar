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

/// نموذج صنف/مادة في المخزن مطابق لـ warehouse_items.php
class WarehouseItemModel {
  final int id;
  final String name;
  final String? code;
  final int? categoryId;
  final String? categoryName;
  final String unit; // كيس، طن، متر، برميل، قطعة...
  final double currentStock;
  final double minStock;
  final double unitPrice;
  final String status; // active, inactive
  final String? location;
  final String? notes;

  WarehouseItemModel({
    required this.id,
    required this.name,
    this.code,
    this.categoryId,
    this.categoryName,
    this.unit = 'قطعة',
    this.currentStock = 0.0,
    this.minStock = 0.0,
    this.unitPrice = 0.0,
    this.status = 'active',
    this.location,
    this.notes,
  });

  bool get isActive => status.toLowerCase() == 'active' || status == '1';
  bool get isLowStock => currentStock <= minStock;
  double get totalValue => currentStock * unitPrice;

  factory WarehouseItemModel.fromJson(Map<String, dynamic> json) {
    return WarehouseItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      categoryId: int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString() ?? json['category']?.toString(),
      unit: json['unit']?.toString() ?? 'قطعة',
      currentStock: double.tryParse(json['current_stock']?.toString() ?? json['quantity']?.toString() ?? json['stock']?.toString() ?? '0') ?? 0.0,
      minStock: double.tryParse(json['min_stock']?.toString() ?? json['min_quantity']?.toString() ?? '0') ?? 0.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString().toLowerCase() ?? ((json['is_active'] == 0 || json['is_active'] == false) ? 'inactive' : 'active'),
      location: json['location']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      if (code != null) 'code': code,
      if (categoryId != null) 'category_id': categoryId,
      'unit': unit,
      'quantity': currentStock,
      'current_stock': currentStock,
      'min_quantity': minStock,
      'min_stock': minStock,
      'unit_price': unitPrice,
      'status': status,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
    };
  }
}

/// نموذج حركة مخزنية مطابق لـ warehouse_moves.php و warehouse_transactions
class WarehouseMoveModel {
  final int id;
  final int itemId;
  final String? itemName;
  final String moveType; // in (وارد), out (صادر), adjust (تعديل رصيد)
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final int? siteId;
  final String? siteName;
  final String? supplier;
  final String? invoiceNumber;
  final String? notes;
  final String? createdAt;
  final String? createdBy;

  WarehouseMoveModel({
    required this.id,
    required this.itemId,
    this.itemName,
    required this.moveType,
    required this.quantity,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
    this.siteId,
    this.siteName,
    this.supplier,
    this.invoiceNumber,
    this.notes,
    this.createdAt,
    this.createdBy,
  });

  String get moveTypeLabel {
    switch (moveType.toLowerCase()) {
      case 'in':
        return 'وارد مخزني';
      case 'out':
        return 'صادر لموقع';
      case 'adjust':
        return 'تعديل رصيد';
      default:
        return moveType;
    }
  }

  factory WarehouseMoveModel.fromJson(Map<String, dynamic> json) {
    return WarehouseMoveModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      itemId: int.tryParse(json['item_id']?.toString() ?? '0') ?? 0,
      itemName: json['item_name']?.toString() ?? json['item']?.toString(),
      moveType: json['type']?.toString().toLowerCase() ?? json['move_type']?.toString().toLowerCase() ?? 'out',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? json['total']?.toString() ?? '0') ?? 0.0,
      siteId: int.tryParse(json['site_id']?.toString() ?? ''),
      siteName: json['site_name']?.toString() ?? json['site']?.toString(),
      supplier: json['supplier']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      notes: json['reason']?.toString() ?? json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      createdBy: json['full_name']?.toString() ?? json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'type': moveType,
      'move_type': moveType,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      if (siteId != null) 'site_id': siteId,
      if (supplier != null) 'supplier': supplier,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (notes != null && notes!.isNotEmpty) 'reason': notes,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
