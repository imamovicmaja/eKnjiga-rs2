class CartItem {
  final int bookId;
  final String name;
  final List<String> authors;
  final String? coverImage;
  final double price;
  final bool isPdfPurchase;
  int quantity;
  final DateTime createdAt;
  final String pickupAddress;

  CartItem({
    required this.bookId,
    required this.name,
    required this.authors,
    required this.coverImage,
    required this.price,
    required this.isPdfPurchase,
    this.quantity = 1,
    DateTime? createdAt,
    this.pickupAddress = 'Poslovnica eKnjiga, Zmaja od Bosne 12, Sarajevo',
  })  : createdAt = createdAt ?? DateTime.now();
}