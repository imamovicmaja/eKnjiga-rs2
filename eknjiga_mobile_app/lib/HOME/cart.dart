import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class Cart {
  Cart._();
  static final Cart I = Cart._();

  final ValueNotifier<int> count = ValueNotifier<int>(0);
  final ValueNotifier<List<CartItem>> notifier = ValueNotifier<List<CartItem>>([]);

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  void _refresh() {
    notifier.value = List<CartItem>.from(_items);
    count.value = _items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  void add(CartItem item) {
    final existingIndex = _items.indexWhere(
      (e) => e.bookId == item.bookId && e.isPdfPurchase == item.isPdfPurchase,
    );

    if (existingIndex >= 0) {
      if (_items[existingIndex].isPdfPurchase) {
        _items[existingIndex].quantity = 1;
      } else {
        _items[existingIndex].quantity += item.quantity;
      }
    } else {
      _items.add(item);
    }

    _refresh();
  }

  void remove(CartItem item) {
    _items.removeWhere(
      (e) => e.bookId == item.bookId && e.isPdfPurchase == item.isPdfPurchase,
    );
    _refresh();
  }

  void increase(CartItem item) {
    final index = _items.indexWhere(
      (e) => e.bookId == item.bookId && e.isPdfPurchase == item.isPdfPurchase,
    );

    if (index == -1) return;
    if (_items[index].isPdfPurchase) return;

    _items[index].quantity++;
    _refresh();
  }

  void decrease(CartItem item) {
    final index = _items.indexWhere(
      (e) => e.bookId == item.bookId && e.isPdfPurchase == item.isPdfPurchase,
    );

    if (index == -1) return;
    if (_items[index].isPdfPurchase) return;

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

  bool get hasPdf => _items.any((e) => e.isPdfPurchase);

  void clear() {
    _items.clear();
    _refresh();
  }
}