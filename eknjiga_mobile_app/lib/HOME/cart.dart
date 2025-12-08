import 'package:flutter/foundation.dart';
import 'package:eknjiga/models/book.dart';

class Cart {
  Cart._();
  static final Cart I = Cart._();

  final ValueNotifier<int> count = ValueNotifier<int>(0);
  final List<Book> _items = [];
  List<Book> get items => List.unmodifiable(_items);

  void add(Book b) {
    _items.add(b);
    count.value = _items.length;
  }

  void remove(Book b) {
    _items.remove(b);
    count.value = _items.length;
  }

  void clear() {
    _items.clear();
    count.value = 0;
  }
}
