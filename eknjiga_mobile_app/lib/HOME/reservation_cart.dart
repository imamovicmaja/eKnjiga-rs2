import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class ReservationCart {
  ReservationCart._();
  static final ReservationCart I = ReservationCart._();

  final ValueNotifier<int> count = ValueNotifier<int>(0);
  final ValueNotifier<List<CartItem>> notifier =
      ValueNotifier<List<CartItem>>([]);

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  void _refresh() {
    notifier.value = List<CartItem>.from(_items);
    count.value = _items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  void add(CartItem item) {
    if (item.isPdfPurchase) return;

    final existingIndex = _items.indexWhere((e) => e.bookId == item.bookId);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(
        CartItem(
          bookId: item.bookId,
          name: item.name,
          authors: item.authors,
          coverImage: item.coverImage,
          price: item.price,
          isPdfPurchase: false,
          quantity: item.quantity,
          createdAt: item.createdAt,
          pickupAddress: item.pickupAddress,
        ),
      );
    }

    _refresh();
  }

  void remove(CartItem item) {
    _items.removeWhere((e) => e.bookId == item.bookId);
    _refresh();
  }

  void increase(CartItem item) {
    final index = _items.indexWhere((e) => e.bookId == item.bookId);
    if (index == -1) return;

    _items[index].quantity++;
    _refresh();
  }

  void decrease(CartItem item) {
    final index = _items.indexWhere((e) => e.bookId == item.bookId);
    if (index == -1) return;

    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }

    _refresh();
  }

  double get totalPrice {
    return _items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  void clear() {
    _items.clear();
    _refresh();
  }
}