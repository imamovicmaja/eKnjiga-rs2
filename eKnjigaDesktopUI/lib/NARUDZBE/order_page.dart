import 'dart:async';

import 'package:flutter/material.dart';

import '../FORUM/forum_page.dart';
import '../KNJIGE/books_page.dart';
import '../KORISNICI/user_page.dart';
import '../LOGIN/login_page.dart';
import '../IZVJESTAJ/reports_page.dart';

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
  final List<int> _paymentStatusOptions = [0, 1, 2, 3, 4];

  Timer? _debounce;
  static const _debounceMs = 450;

  bool _loadingOrders = false;

  bool get _isAdmin => ApiService.isAdmin;
  bool get _isEmployee => ApiService.isEmployee;

  @override
  void initState() {
    super.initState();

    if (_isAdmin) {
      loadOrderUsersFromApi();
    }

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
    if (!_isAdmin) return;

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

    int? typeInt;

    if (selectedSidebar == "NARUDZBE") {
      typeInt = 0; // Purchase
    } else if (selectedSidebar == "REZERVACIJA") {
      typeInt = 1; // Reservation
    } else if (selectedSidebar == "ARHIVA") {
      typeInt = null; // ne koristi Archive type
    }

    final fetched = await ApiService.fetchOrders(
      type: typeInt,
      userId: userId,
      totalPrice: totalPrice,
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
    );

    List<OrderResponse> filtered = fetched;

    // Tab filter
    if (selectedSidebar == "NARUDZBE") {
      filtered = filtered.where((o) => o.type == 0).toList();
    } else if (selectedSidebar == "REZERVACIJA") {
      filtered = filtered.where((o) => o.type == 1).toList();
    } else if (selectedSidebar == "ARHIVA") {
      filtered = filtered.where((o) => o.orderStatus == 2).toList();
    }

    // Dropdown status filter
    if (_selectedOrderStatus != null) {
      filtered = filtered
          .where((o) => o.orderStatus == _selectedOrderStatus)
          .toList();
    } else {
      // bez izabranog statusa:
      // aktivni tabovi ne prikazuju completed
      if (selectedSidebar == "NARUDZBE" ||
          selectedSidebar == "REZERVACIJA") {
        filtered = filtered.where((o) => o.orderStatus != 2).toList();
      }
    }

    // Payment status filter
    if (_selectedPaymentStatus != null) {
      filtered = filtered
          .where((o) => o.paymentStatus == _selectedPaymentStatus)
          .toList();
    }

    // User filter
    if (_selectedUserId != null) {
      filtered = filtered
          .where((o) => o.user?.id == _selectedUserId)
          .toList();
    }

    // Total price filter
    if (totalPrice != null) {
      filtered = filtered
          .where((o) => o.totalPrice == totalPrice)
          .toList();
    }

    if (mounted) {
      setState(() {
        orders = filtered;
      });
    }
  } catch (e) {
    debugPrint("Greška: $e");
  } finally {
    if (mounted) {
      setState(() => _loadingOrders = false);
    }
  }
}

  Future<void> _reloadWithCurrentFilters() async {
    final totalPriceText = _totalPriceCtrl.text.trim();

    double? totalPrice;
    if (totalPriceText.isNotEmpty) {
      final normalized = totalPriceText.replaceAll(',', '.');
      totalPrice = double.tryParse(normalized);
    }

    await loadOrdersFromApi(
      userId: _selectedUserId,
      totalPrice: totalPrice,
      orderStatus: _selectedOrderStatus,
      paymentStatus: _selectedPaymentStatus,
    );
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

      final allEmpty = userId == null &&
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

  void _resetFilters() {
    _totalPriceCtrl.clear();
    setState(() {
      _selectedUserId = null;
      _selectedOrderStatus = null;
      _selectedPaymentStatus = null;
    });
    _onOrderFilterChanged();
  }

  InputDecoration _filterDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void showOrderDetailsDialog(BuildContext context, OrderResponse order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              selectedSidebar == "REZERVACIJA"
                  ? Icons.event_note
                  : selectedSidebar == "ARHIVA"
                      ? Icons.archive
                      : Icons.shopping_cart,
              color: const Color.fromARGB(255, 181, 156, 74),
            ),
            const SizedBox(width: 8),
            Text(
              selectedSidebar == "REZERVACIJA"
                  ? "Detalji rezervacije"
                  : selectedSidebar == "ARHIVA"
                      ? "Detalji arhive"
                      : "Detalji narudžbe",
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                children: [
                  const Icon(
                    Icons.edit,
                    color: Color.fromARGB(255, 181, 156, 74),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedSidebar == "REZERVACIJA"
                        ? "Uredi rezervaciju"
                        : "Uredi narudžbu",
                  ),
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
                      _infoRow("Plaćanje", paymentStatusText(order.paymentStatus)),
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
                              Text("📖 ${item.book?.name ?? 'Nepoznata knjiga'}"),
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
                        await _reloadWithCurrentFilters();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              selectedSidebar == "REZERVACIJA"
                                  ? "Status rezervacije ažuriran."
                                  : "Status narudžbe ažuriran.",
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withOpacity(0.8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    "eKnjiga",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(width: 40),
                  if (_isAdmin) ...[
                    navTab("KORISNICI", context),
                    const SizedBox(width: 24),
                    navTab("KNJIGE", context),
                    const SizedBox(width: 24),
                  ],
                  navTab("NARUDŽBE", context, isActive: true),
                  if (_isAdmin) ...[
                    const SizedBox(width: 24),
                    navTab("FORUM", context),
                    const SizedBox(width: 24),
                    navTab("IZVJEŠTAJI", context),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 1200;
        final double fieldWidth =
            isNarrow ? constraints.maxWidth.clamp(220.0, 420.0) : 220;

        return Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (_isAdmin)
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedUserId,
                    isExpanded: true,
                    decoration: _filterDecoration("Korisnik", Icons.person),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          "Svi korisnici",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ..._filterUsers.map(
                        (u) => DropdownMenuItem<int?>(
                          value: u.id,
                          child: Text(
                            u.firstName,
                            overflow: TextOverflow.ellipsis,
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

              SizedBox(
                width: fieldWidth,
                child: TextField(
                  controller: _totalPriceCtrl,
                  onChanged: (_) => _onOrderFilterChanged(),
                  decoration: _filterDecoration("Total cijena", Icons.search),
                ),
              ),

              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<int?>(
                  value: _selectedOrderStatus,
                  isExpanded: true,
                  decoration:
                      _filterDecoration("Status narudžbe", Icons.info_outline),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("Svi statusi", overflow: TextOverflow.ellipsis),
                    ),
                    ..._orderStatusOptions.map(
                      (s) => DropdownMenuItem<int?>(
                        value: s,
                        child: Text(
                          orderStatusText(s),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                width: fieldWidth,
                child: DropdownButtonFormField<int?>(
                  value: _selectedPaymentStatus,
                  isExpanded: true,
                  decoration: _filterDecoration(
                    "Status plaćanja",
                    Icons.payment,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("Sva plaćanja", overflow: TextOverflow.ellipsis),
                    ),
                    ..._paymentStatusOptions.map(
                      (p) => DropdownMenuItem<int?>(
                        value: p,
                        child: Text(
                          paymentStatusText(p),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                onPressed: _resetFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text("Reset"),
              ),
            ],
          ),
        );
      },
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

            final title = selectedSidebar == "REZERVACIJA"
                ? "Rezervacija #${order.id}"
                : selectedSidebar == "ARHIVA"
                    ? "Arhiva #${order.id}"
                    : "Narudžba #${order.id}";

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: userCard(
                title,
                "${order.user?.fullName ?? "Nepoznat korisnik"} • "
                "${orderStatusText(order.orderStatus)} • "
                "${formatShortDate(order.orderDate)}",
                icon,
                onTap: () => showOrderDetailsDialog(context, order),
                onEdit: () => showEditOrderDialog(context, order),
                onDelete: _isAdmin
                    ? () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Potvrda brisanja"),
                            content: Text(
                              selectedSidebar == "REZERVACIJA"
                                  ? "Da li sigurno želiš obrisati ovu rezervaciju?"
                                  : "Da li sigurno želiš obrisati ovu narudžbu?",
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

                        if (confirm == true) {
                          try {
                            await ApiService.deleteOrder(order.id);
                            await _reloadWithCurrentFilters();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    selectedSidebar == "REZERVACIJA"
                                        ? "Rezervacija uspješno obrisana"
                                        : "Narudžba uspješno obrisana",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Greška pri brisanju: $e"),
                                ),
                              );
                            }
                          }
                        }
                      }
                    : null,
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
          } else if (label == "IZVJEŠTAJI") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ReportsPage()),
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
        setState(() {
          selectedSidebar = label;
        });
        loadOrdersFromApi();
      },
      hoverColor: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
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
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.black : Colors.grey[700],
                  backgroundColor: isActive
                      ? Colors.white.withOpacity(0.1)
                      : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userCard(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return GestureDetector(
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
            Icon(icon, color: const Color.fromARGB(255, 181, 156, 74)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  String orderStatusText(int status) {
    switch (status) {
      case 0:
        return "Kreirano";
      case 1:
        return "Obrađeno";
      case 2:
        return "Završeno";
      case 3:
        return "Otkazano";
      default:
        return "Nepoznato";
    }
  }

  String paymentStatusText(int status) {
  switch (status) {
    case 0:
      return "Neplaćeno";
    case 1:
      return "Na čekanju";
    case 2:
      return "Plaćeno";
    case 3:
      return "Refundirano";
    case 4:
      return "Neuspjelo";
    default:
      return "Nepoznato";
  }
}

  String orderTypeText(int type) {
    switch (type) {
      case 0:
        return "Narudžba";
      case 1:
        return "Rezervacija";
      case 2:
        return "Arhiva";
      default:
        return "Nepoznato";
    }
  }
}