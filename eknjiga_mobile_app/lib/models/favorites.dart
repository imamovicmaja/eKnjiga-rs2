import '../models/book.dart';
class Favorites {
  Favorites._();
  static final Favorites I = Favorites._();

  final List<Book> _items = [];

  List<Book> get items => _items;

  void add(Book b) {
    if (!_items.any((e) => e.id == b.id)) {
      _items.add(b);
    }
  }

  void remove(Book b) {
    _items.removeWhere((e) => e.id == b.id);
  }

  void clear() {
  _items.clear();
}
}