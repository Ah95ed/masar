/// نموذج بند المصروف المرفق بالتقرير اليومي
class ExpenseModel {
  final String itemName;
  final String category; // materials, labor, fuel, equipment, transport, other
  final double quantity;
  final double unitPrice;
  final String? notes;

  ExpenseModel({
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unitPrice,
    this.notes,
  });

  double get total => quantity * unitPrice;

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      itemName: json['item_name']?.toString() ?? '',
      category: json['category']?.toString().toLowerCase() ?? 'other',
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_name': itemName,
      'category': category,
      'quantity': quantity,
      'unit_price': unitPrice,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }
}
