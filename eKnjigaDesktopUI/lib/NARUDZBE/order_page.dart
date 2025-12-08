import 'dart:async';

import 'package:flutter/material.dart';

import '../FORUM/forum_page.dart';
import '../KNJIGE/books_page.dart';
import '../KORISNICI/user_page.dart';
import '../LOGIN/login_page.dart';

import '../models/order.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  String selectedSidebar = "NARUDZBE";
  List<OrderResponse> orders = [];

  final TextEditingController _totalPriceCtrl = TextEditingController();

  int? _selectedOrderStatus;
  int? _selectedPaymentStatus;
  int? _selectedUserId;

  List<User> _filterUsers = [];
  bool _loadingFilterUsers = false;

  final List<int> _orderStatusOptions = [0, 1, 2, 3];

  final List<int> _paymentStatusOptions = [0, 1, 2];

  Timer? _debounce;
  static const _debounceMs = 450;

  bool _loadingOrders = false;

  @override
  void initState() {
    super.initState();
    loadOrderUsersFromApi();
    loadOrdersFromApi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _totalPriceCtrl.dispose();
    super.dispose();
  }

  String formatShortDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return "$dd.$mm.$yyyy";
  }

  OrderTypeDart _tabToOrderType(String tab) {
    switch (tab) {
      case "NARUDZBE":
        return OrderTypeDart.Purchase;
      case "REZERVACIJA":
        return OrderTypeDart.Reservation;
      case "ARHIVA":
        return OrderTypeDart.Archive;
      default:
        return OrderTypeDart.Purchase;
    }
  }

  int _orderTypeToInt(OrderTypeDart type) {
    switch (type) {
      case OrderTypeDart.Purchase:
        return 0;
      case OrderTypeDart.Reservation:
        return 1;
      case OrderTypeDart.Archive:
        return 2;
    }
  }

  Future<void> loadOrderUsersFromApi() async {
    try {
      if (mounted) setState(() => _loadingFilterUsers = true);

      final fetched = await ApiService.fetchUsers(includeTotalCount: false);

      if (!mounted) return;
      setState(() {
        _filterUsers = fetched
            .map<User>(
              (m) => User(
                id: m['id'],
                firstName: m['name'] ?? '',
                lastName: '',
                username: '',
                email: m['email'] ?? '',
                isActive: true,
              ),
            )
            .toList();
      });
    } catch (e) {
      debugPrint("Greška pri dohvaćanju korisnika za filter narudžbi: $e");
    } finally {
      if (mounted) setState(() => _loadingFilterUsers = false);
    }
  }

  Future<void> loadOrdersFromApi({
    int? userId,
    double? totalPrice,
    int? orderStatus,
    int? paymentStatus,
  }) async {
    try {
      if (mounted) {
        setState(() => _loadingOrders = true);
      }

      final typeEnum = _tabToOrderType(selectedSidebar);
      final typeInt = _orderTypeToInt(typeEnum);

      final fetched = await ApiService.fetchOrders(
        type: typeInt,
        userId: userId,
        totalPrice: totalPrice,
        orderStatus: orderStatus,
        paymentStatus: paymentStatus,
      );

      if (mounted) {
        setState(() {
          orders = fetched;
        });
      }
    } catch (e) {
      print("Greška: $e");
    } finally {
      if (mounted) {
        setState(() => _loadingOrders = false);
      }
    }
  }

  void _onOrderFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;

      final totalPriceText = _totalPriceCtrl.text.trim();

      final int? userId = _selectedUserId;

      double? totalPrice;
      if (totalPriceText.isNotEmpty) {
        final normalized = totalPriceText.replaceAll(',', '.');
        totalPrice = double.tryParse(normalized);
      }

      final allEmpty =
          userId == null &&
          totalPrice == null &&
          _selectedOrderStatus == null &&
          _selectedPaymentStatus == null;

      if (allEmpty) {
        loadOrdersFromApi();
      } else {
        loadOrdersFromApi(
          userId: userId,
          totalPrice: totalPrice,
          orderStatus: _selectedOrderStatus,
          paymentStatus: _selectedPaymentStatus,
        );
      }
    });
  }

  void showOrderDetailsDialog(BuildContext context, OrderResponse order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.shopping_cart,
                color: Color.fromARGB(255, 181, 156, 74)),
            SizedBox(width: 8),
            Text("Detalji narudžbe"),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow("Kupac", order.user?.fullName ?? "Nepoznato"),
                _infoRow("Datum narudžbe", formatShortDate(order.orderDate)),
                _infoRow("Status", orderStatusText(order.orderStatus)),
                _infoRow("Plaćanje", paymentStatusText(order.paymentStatus)),
                _infoRow("Tip", orderTypeText(order.type)),
                const Divider(),
                const Text(
                  "Knjige:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.orderItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📖 ${item.book?.name ?? 'Nepoznata knjiga'}"),
                        Text("Količina: ${item.quantity}"),
                        Text(
                          "Cijena po komadu: ${item.unitPrice.toStringAsFixed(2)} KM",
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ukupno: ${order.totalPrice.toStringAsFixed(2)} KM",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Zatvori"),
          ),
        ],
      ),
    );
  }

  void showEditOrderDialog(BuildContext context, OrderResponse order) {
    int selectedStatus = order.orderStatus;
    final List<int> possibleStatuses = [0, 1, 2, 3];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.edit,
                      color: Color.fromARGB(255, 181, 156, 74)),
                  SizedBox(width: 8),
                  Text("Uredi narudžbu"),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow("Kupac", order.user?.fullName ?? "Nepoznato"),
                      _infoRow("Datum", formatShortDate(order.orderDate)),
                      _infoRow(
                          "Plaćanje", paymentStatusText(order.paymentStatus)),
                      _infoRow("Tip", orderTypeText(order.type)),
                      const SizedBox(height: 12),
                      const Text(
                        "Status",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButtonFormField<int>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: possibleStatuses
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(orderStatusText(s)),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedStatus = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const Text(
                        "Knjige:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...order.orderItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "📖 ${item.book?.name ?? 'Nepoznata knjiga'}"),
                              Text("Količina: ${item.quantity}"),
                              Text(
                                "Cijena: ${item.unitPrice.toStringAsFixed(2)} KM",
                              ),
                              const Divider(),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        "Ukupno: ${order.totalPrice.toStringAsFixed(2)} KM",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Otkaži"),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await ApiService.updateOrder(order.id, {
                        'orderStatus': selectedStatus,
                      });

                      if (mounted) {
                        Navigator.pop(dialogCtx);
                        await loadOrdersFromApi();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Status narudžbe ažuriran."),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Greška: $e")),
                        );
                      }
                    }
                  },
                  child: const Text("Spasi"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 212, 217, 246),
                  Color.fromARGB(255, 141, 158, 219),
                  Color.fromARGB(255, 181, 156, 74),
                ],
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Row(
                  children: [
                    _buildSidebar(),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            const SizedBox(height: 8),
                            if (_loadingOrders)
                              const LinearProgressIndicator(minHeight: 3),
                            const SizedBox(height: 16),
                            Expanded(child: _buildContent()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      color: Colors.white.withOpacity(0.8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                "eKnjiga",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(width: 50),
              navTab("KORISNICI", context),
              const SizedBox(width: 32),
              navTab("KNJIGE", context),
              const SizedBox(width: 32),
              navTab("NARUDŽBE", context, isActive: true),
              const SizedBox(width: 32),
              navTab("FORUM", context),
            ],
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 181, 156, 74),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Odjavi se"),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 180,
      color: Colors.white.withOpacity(0.8),
      padding: const EdgeInsets.only(top: 32, left: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sidebarOption("NARUDZBE", Icons.shopping_cart),
          const SizedBox(height: 24),
          sidebarOption("REZERVACIJA", Icons.event_note),
          const SizedBox(height: 24),
          sidebarOption("ARHIVA", Icons.archive),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            value: _selectedUserId,
            decoration: InputDecoration(
              labelText: "Korisnik",
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("Svi korisnici"),
              ),
              ..._filterUsers.map(
                (u) => DropdownMenuItem<int?>(
                  value: u.id,
                  child: Text(
                    u.lastName.isNotEmpty
                        ? "${u.firstName} ${u.lastName}"
                        : u.firstName,
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedUserId = value);
              _onOrderFilterChanged();
            },
          ),
        ),
        _orderFilterField(
          label: "Total cijena (tačno)",
          controller: _totalPriceCtrl,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: false,
          ),
          onChanged: (_) => _onOrderFilterChanged(),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            value: _selectedOrderStatus,
            decoration: InputDecoration(
              labelText: "Status narudžbe",
              prefixIcon: const Icon(Icons.info_outline),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("Svi statusi"),
              ),
              ..._orderStatusOptions.map(
                (s) => DropdownMenuItem<int?>(
                  value: s,
                  child: Text(orderStatusText(s)),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedOrderStatus = value);
              _onOrderFilterChanged();
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            value: _selectedPaymentStatus,
            decoration: InputDecoration(
              labelText: "Status plaćanja",
              prefixIcon: const Icon(Icons.payment),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("Sva plaćanja"),
              ),
              ..._paymentStatusOptions.map(
                (p) => DropdownMenuItem<int?>(
                  value: p,
                  child: Text(paymentStatusText(p)),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedPaymentStatus = value);
              _onOrderFilterChanged();
            },
          ),
        ),
        TextButton.icon(
          onPressed: () {
            _totalPriceCtrl.clear();
            setState(() {
              _selectedUserId = null;
              _selectedOrderStatus = null;
              _selectedPaymentStatus = null;
            });
            _onOrderFilterChanged();
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text("Reset"),
        ),
      ],
    );
  }

  Widget _orderFilterField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedSidebar) {
      case "NARUDZBE":
      case "REZERVACIJA":
      case "ARHIVA":
        if (_loadingOrders && orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orders.isEmpty) {
          return const Center(child: Text("Nema podataka za odabrani tip."));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            final icon = selectedSidebar == "NARUDZBE"
                ? Icons.shopping_cart
                : selectedSidebar == "REZERVACIJA"
                    ? Icons.event_note
                    : Icons.archive;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: userCard(
                "Narudžba #${order.id}",
                "${order.user?.fullName ?? "Nepoznat korisnik"} • "
                "${orderStatusText(order.orderStatus)} • "
                "${formatShortDate(order.orderDate)}",
                icon,
                onTap: () => showOrderDetailsDialog(context, order),
                onEdit: () => showEditOrderDialog(context, order),
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Potvrda brisanja"),
                      content: const Text(
                        "Da li sigurno želiš obrisati ovu narudžbu?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Otkaži"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Obriši"),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      await ApiService.deleteOrder(order.id);
                      await loadOrdersFromApi();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Narudžba uspješno obrisana"),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Greška pri brisanju: $e")),
                        );
                      }
                    }
                  }
                },
              ),
            );
          },
        );

      default:
        return const Center(child: Text("Odaberi stavku iz menija"));
    }
  }

  Widget navTab(String label, BuildContext context, {bool isActive = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (label == "KORISNICI") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserPage()),
            );
          } else if (label == "KNJIGE") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const BooksPage()),
            );
          } else if (label == "NARUDŽBE") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OrderPage()),
            );
          } else if (label == "FORUM") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ForumPage()),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color.fromARGB(255, 181, 156, 74)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget sidebarOption(String label, IconData icon) {
    final bool isActive = selectedSidebar == label;

    return InkWell(
      onTap: () {
        _debounce?.cancel(); 

        setState(() {
          selectedSidebar = label;

          _totalPriceCtrl.clear();
          _selectedUserId = null;
          _selectedOrderStatus = null;
          _selectedPaymentStatus = null;

          orders = [];
          _loadingOrders = true;
        });

        loadOrdersFromApi();
      },
      hoverColor: Colors.white.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.black : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userCard(
    String name,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
