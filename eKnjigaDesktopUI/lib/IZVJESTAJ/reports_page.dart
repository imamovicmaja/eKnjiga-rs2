import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../FORUM/forum_page.dart';
import '../KNJIGE/books_page.dart';
import '../NARUDZBE/order_page.dart';
import '../LOGIN/login_page.dart';
import '../KORISNICI/user_page.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTimeRange? _dateRange;
  bool _isLoading = false;

  List<OrderResponse> _allOrders = [];
  List<OrderResponse> _filteredOrders = [];

  int _totalOrders = 0;
  int _completedOrders = 0;
  int _cancelledOrders = 0;
  int _paidOrders = 0;
  int _reservationOrders = 0;
  int _purchaseOrders = 0;
  int _archiveOrders = 0;
  int _pdfPurchases = 0;
  int _hardcopyPurchases = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);

      final fetched = await ApiService.fetchOrders();

      setState(() {
        _allOrders = fetched;
      });

      _applyFiltersAndCalculate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Greška pri učitavanju narudžbi: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      helpText: 'Odaberite period',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 181, 156, 74),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 181, 156, 74),
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
                maxHeight: 650,
              ),
              child: child!,
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _applyFiltersAndCalculate();
    }
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
    });
    _applyFiltersAndCalculate();
  }

  void _applyFiltersAndCalculate() {
    final filtered = _allOrders.where((order) {
      final date = order.orderDate;

      if (_dateRange == null) return true;

      final start = DateTime(
        _dateRange!.start.year,
        _dateRange!.start.month,
        _dateRange!.start.day,
      );

      final end = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
        23,
        59,
        59,
      );

      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();

    int completed = 0;
    int cancelled = 0;
    int paid = 0;
    int reservations = 0;
    int purchases = 0;
    int archives = 0;
    int pdfCount = 0;
    int hardcopyCount = 0;
    double revenue = 0;

    for (final order in filtered) {
      if (order.orderStatus == 2) completed++;
      if (order.orderStatus == 3) cancelled++;

      if (order.paymentStatus == 2) paid++;

      if (order.type == 0) purchases++;
      if (order.type == 1) reservations++;
      if (order.type == 2) archives++;

      if (order.paymentStatus == 2) {
        revenue += order.totalPrice;
      }

      for (final item in order.orderItems) {
        if (item.isPdfPurchase) {
          pdfCount += item.quantity;
        } else {
          hardcopyCount += item.quantity;
        }
      }
    }

    setState(() {
      _filteredOrders = filtered;
      _totalOrders = filtered.length;
      _completedOrders = completed;
      _cancelledOrders = cancelled;
      _paidOrders = paid;
      _reservationOrders = reservations;
      _purchaseOrders = purchases;
      _archiveOrders = archives;
      _pdfPurchases = pdfCount;
      _hardcopyPurchases = hardcopyCount;
      _totalRevenue = revenue;
    });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(value);
  }

  String _formatShortDate(DateTime value) {
    return DateFormat('dd.MM.yyyy').format(value);
  }

  Future<void> _generateReport() async {
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite period za izvještaj.'),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Poslovni izvještaj eKnjiga',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Period: ${_formatShortDate(_dateRange!.start)} - ${_formatShortDate(_dateRange!.end)}',
              style: const pw.TextStyle(fontSize: 13),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Sažetak',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Bullet(text: 'Broj svih narudžbi: $_totalOrders'),
                  pw.Bullet(text: 'Broj završenih narudžbi: $_completedOrders'),
                  pw.Bullet(text: 'Broj otkazanih narudžbi: $_cancelledOrders'),
                  pw.Bullet(text: 'Broj plaćenih narudžbi: $_paidOrders'),
                  pw.Bullet(text: 'Broj kupovina: $_purchaseOrders'),
                  pw.Bullet(text: 'Broj rezervacija: $_reservationOrders'),
                  pw.Bullet(text: 'Broj arhiviranih: $_archiveOrders'),
                  pw.Bullet(text: 'Broj PDF kupovina: $_pdfPurchases'),
                  pw.Bullet(text: 'Broj fizičkih kupovina: $_hardcopyPurchases'),
                  pw.Bullet(
                    text: 'Ukupan prihod: ${_totalRevenue.toStringAsFixed(2)} KM',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Pregled narudžbi u periodu',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            if (_filteredOrders.isEmpty)
              pw.Text('Nema narudžbi za odabrani period.')
            else
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: const [
                  'ID',
                  'Datum',
                  'Tip',
                  'Status',
                  'Plaćanje',
                  'Iznos (KM)',
                ],
                data: _filteredOrders.map<List<dynamic>>((order) {
                  return [
                    order.id.toString(),
                    _formatDate(order.orderDate),
                    orderTypeText(order.type),
                    orderStatusText(order.orderStatus),
                    paymentStatusText(order.paymentStatus),
                    order.totalPrice.toStringAsFixed(2),
                  ];
                }).toList(),
              ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Generisano: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      );

      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Downloads folder nije dostupan.');
      }

      final filename =
          'eknjiga_izvjestaj_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$filename');

      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF izvještaj sačuvan: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška pri generisanju izvještaja: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color.fromARGB(255, 181, 156, 74),
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            _statCard(
              title: 'Sve narudžbe',
              value: _totalOrders.toString(),
              icon: Icons.shopping_bag_outlined,
            ),
            _statCard(
              title: 'Completed',
              value: _completedOrders.toString(),
              icon: Icons.check_circle_outline,
            ),
            _statCard(
              title: 'Cancelled',
              value: _cancelledOrders.toString(),
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
        Row(
          children: [
            _statCard(
              title: 'Paid',
              value: _paidOrders.toString(),
              icon: Icons.payments_outlined,
            ),
            _statCard(
              title: 'PDF kupovine',
              value: _pdfPurchases.toString(),
              icon: Icons.picture_as_pdf_outlined,
            ),
            _statCard(
              title: 'Fizičke kupovine',
              value: _hardcopyPurchases.toString(),
              icon: Icons.menu_book_outlined,
            ),
          ],
        ),
        Row(
          children: [
            _statCard(
              title: 'Kupovine',
              value: _purchaseOrders.toString(),
              icon: Icons.shopping_cart_checkout_outlined,
            ),
            _statCard(
              title: 'Rezervacije',
              value: _reservationOrders.toString(),
              icon: Icons.bookmark_outline,
            ),
            _statCard(
              title: 'Ukupan prihod',
              value: '${_totalRevenue.toStringAsFixed(2)} KM',
              icon: Icons.attach_money_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrdersPreview() {
    if (_filteredOrders.isEmpty) {
      return Center(
        child: Text(
          _dateRange == null
              ? 'Nema dostupnih podataka.'
              : 'Nema narudžbi za odabrani period.',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.75)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color.fromARGB(255, 181, 156, 74),
                child: Text(
                  order.id.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  runSpacing: 6,
                  spacing: 18,
                  children: [
                    Text(
                      'Datum: ${_formatDate(order.orderDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text('Tip: ${orderTypeText(order.type)}'),
                    Text('Status: ${orderStatusText(order.orderStatus)}'),
                    Text('Plaćanje: ${paymentStatusText(order.paymentStatus)}'),
                    Text(
                      'Iznos: ${order.totalPrice.toStringAsFixed(2)} KM',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final periodText = _dateRange == null
        ? 'Nije odabran period'
        : '${DateFormat('dd.MM.yyyy').format(_dateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_dateRange!.end)}';

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
              Container(
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
                        navTab("NARUDŽBE", context),
                        const SizedBox(width: 32),
                        navTab("FORUM", context),
                        const SizedBox(width: 32),
                        navTab("IZVJEŠTAJI", context, isActive: true),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("Odjavi se"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Odabrani period: $periodText',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _selectDateRange(context),
                                  icon: const Icon(Icons.date_range),
                                  label: const Text('Odaberi period'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _dateRange == null ? null : _clearDateRange,
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Očisti'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _generateReport,
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Export PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 181, 156, 74),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _loadOrders,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Osvježi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isLoading) const LinearProgressIndicator(minHeight: 3),
                      const SizedBox(height: 12),
                      _buildStatsGrid(),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pregled narudžbi za odabrani period',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(child: _buildOrdersPreview()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}