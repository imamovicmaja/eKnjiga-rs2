class OrderReport {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int paidOrders;
  final int purchaseOrders;
  final int reservationOrders;
  final int pdfPurchases;
  final int hardcopyPurchases;
  final double totalRevenue;

  OrderReport({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.paidOrders,
    required this.purchaseOrders,
    required this.reservationOrders,
    required this.pdfPurchases,
    required this.hardcopyPurchases,
    required this.totalRevenue,
  });

  factory OrderReport.fromJson(Map<String, dynamic> json) {
    return OrderReport(
      totalOrders: json['totalOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      paidOrders: json['paidOrders'] ?? 0,
      purchaseOrders: json['purchaseOrders'] ?? 0,
      reservationOrders: json['reservationOrders'] ?? 0,
      pdfPurchases: json['pdfPurchases'] ?? 0,
      hardcopyPurchases: json['hardcopyPurchases'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
    );
  }
}
