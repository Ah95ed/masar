class WarehouseMove {
  final int id;
  final int itemId;
  final String? itemCode;
  final String? itemName;
  final String type; // in, out, adjust
  final double quantity;
  final String? unit;
  final double unitPrice;
  final double totalPrice;
  final int? siteId;
  final String? siteName;
  final String? supplier;
  final String? invoiceNumber;
  final String? reason;
  final String? createdBy;
  final String? createdAt;
  final int? signatureId;
  final String? signedBy;
  final String? signedAt;
  final String? signatureHash;

  WarehouseMove({
    required this.id,
    required this.itemId,
    this.itemCode,
    this.itemName,
    required this.type,
    required this.quantity,
    this.unit,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
    this.siteId,
    this.siteName,
    this.supplier,
    this.invoiceNumber,
    this.reason,
    this.createdBy,
    this.createdAt,
    this.signatureId,
    this.signedBy,
    this.signedAt,
    this.signatureHash,
  });

  bool get isSigned =>
      (signedBy != null && signedBy!.trim().isNotEmpty) ||
      signatureId != null ||
      (signatureHash != null && signatureHash!.trim().isNotEmpty);

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'in':
        return 'وارد مخزني';
      case 'out':
        return 'صادر لموقع';
      case 'adjust':
        return 'تسوية جردية';
      default:
        return type;
    }
  }

  factory WarehouseMove.fromJson(Map<String, dynamic> json) {
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

    return WarehouseMove(
      id: parseInt(json['id']),
      itemId: parseInt(json['item_id']),
      itemCode: json['item_code']?.toString(),
      itemName: json['item_name']?.toString() ?? json['item']?.toString(),
      type: json['type']?.toString().toLowerCase() ?? 'out',
      quantity: parseDouble(json['quantity']),
      unit: json['unit']?.toString(),
      unitPrice: parseDouble(json['unit_price']),
      totalPrice: parseDouble(json['total_price']),
      siteId: json['site_id'] != null ? parseInt(json['site_id']) : null,
      siteName: json['site_name']?.toString(),
      supplier: json['supplier']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      reason: json['reason']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      signatureId: json['signature_id'] != null ? parseInt(json['signature_id']) : null,
      signedBy: json['signed_by']?.toString(),
      signedAt: json['signed_at']?.toString(),
      signatureHash: json['signature_hash']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'item_id': itemId,
    'type': type,
    'quantity': quantity,
    'unit_price': unitPrice,
    if (siteId != null) 'site_id': siteId,
    if (supplier != null) 'supplier': supplier,
    if (invoiceNumber != null) 'invoice_number': invoiceNumber,
    if (reason != null) 'reason': reason,
  };
}
