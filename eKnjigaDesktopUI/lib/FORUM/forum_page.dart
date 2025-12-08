import 'dart:async';
import 'package:flutter/material.dart';

import '../NARUDZBE/order_page.dart';
import '../KNJIGE/books_page.dart';
import '../KORISNICI/user_page.dart';
import '../LOGIN/login_page.dart';

import '../models/comment.dart';
import '../models/commentAnswer.dart';
import '../models/userReport.dart';
import '../services/api_service.dart';

class ForumFilterUser {
  final int id;
  final String firstName;
  final String lastName;

  const ForumFilterUser({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  String get displayName =>
      lastName.isNotEmpty ? '$firstName $lastName' : firstName;
}

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  String selectedSidebar = "KOMENTARI";

  List<Comment> comments = [];
  List<CommentAnswer> commentAnswers = [];
  List<UserReport> reports = [];

  List<ForumFilterUser> _filterUsers = [];
  bool _loadingFilterUsers = false;

  bool _loadingComments = false;
  bool _loadingCommentAnswers = false;
  bool _loadingReports = false;

  final TextEditingController _commentSearchCtrl = TextEditingController();
  final TextEditingController _answerSearchCtrl = TextEditingController();
  final TextEditingController _reportSearchCtrl = TextEditingController();

  int? _selectedCommentUserId;
  int? _selectedAnswerUserId;

  int? _selectedReportStatus;
  int? _selectedReportedUserId;
  int? _selectedReportedByUserId;

  Timer? _debounce;
  static const _debounceMs = 450;

  String formatShortDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return "$dd.$mm.$yyyy";
  }

  @override
  void initState() {
    super.initState();
    print("initState ForumPage");
    _loadFilterUsers();
    loadComments();
    loadCommentAnswers();
    loadUserReports();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _commentSearchCtrl.dispose();
    _answerSearchCtrl.dispose();
    _reportSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFilterUsers() async {
    try {
      if (mounted) setState(() => _loadingFilterUsers = true);

      final fetched = await ApiService.fetchUsers(includeTotalCount: false);

      if (!mounted) return;
      setState(() {
        _filterUsers = fetched
            .map<ForumFilterUser>(
              (m) => ForumFilterUser(
                id: m['id'] as int,
                firstName: (m['name'] ?? '') as String,
                lastName: '',
              ),
            )
            .toList();
      });
    } catch (e) {
      print("Greška pri dohvaćanju korisnika za filtere foruma: $e");
    } finally {
      if (mounted) setState(() => _loadingFilterUsers = false);
    }
  }

  Future<void> loadComments({String? content, int? userId}) async {
    try {
      if (mounted) setState(() => _loadingComments = true);

      // SVE filtriranje prebačeno na backend
      final fetched = await ApiService.fetchComments(
        content: content,
        userId: userId,
      );

      if (mounted) setState(() => comments = fetched);
    } catch (e) {
      print("Greška: $e");
    } finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> loadCommentAnswers({
    String? content,
    int? userId,
    int? parentCommentId,
  }) async {
    try {
      if (mounted) setState(() => _loadingCommentAnswers = true);

      // SVE filtriranje prebačeno na backend
      final fetched = await ApiService.fetchCommentAnswers(
        content: content,
        userId: userId,
        parentCommentId: parentCommentId,
      );

      if (mounted) setState(() => commentAnswers = fetched);
    } catch (e) {
      print("Greška: $e");
    } finally {
      if (mounted) setState(() => _loadingCommentAnswers = false);
    }
  }

  Future<void> loadUserReports({
    String? reason,
    int? status,
    int? userReportedId,
    int? reportedByUserId,
  }) async {
    try {
      if (mounted) setState(() => _loadingReports = true);

      // SVE filtriranje prebačeno na backend
      final fetched = await ApiService.fetchUserReports(
        reason: reason,
        status: status,
        userReportedId: userReportedId,
        reportedByUserId: reportedByUserId,
      );

      if (mounted) setState(() => reports = fetched);
    } catch (e) {
      print("Greška: $e");
    } finally {
      if (mounted) setState(() => _loadingReports = false);
    }
  }

  void _onSearchOrFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;

      if (selectedSidebar == "KOMENTARI") {
        final text = _commentSearchCtrl.text.trim();
        final String? content = text.isEmpty ? null : text;
        loadComments(content: content, userId: _selectedCommentUserId);
      } else if (selectedSidebar == "ODGOVORI") {
        final text = _answerSearchCtrl.text.trim();
        final String? content = text.isEmpty ? null : text;
        loadCommentAnswers(content: content, userId: _selectedAnswerUserId);
      } else if (selectedSidebar == "PRIJAVE") {
        final text = _reportSearchCtrl.text.trim();
        final String? reason = text.isEmpty ? null : text;
        loadUserReports(
          reason: reason,
          status: _selectedReportStatus,
          userReportedId: _selectedReportedUserId,
          reportedByUserId: _selectedReportedByUserId,
        );
      }
    });
  }

  void deleteComment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Potvrda brisanja"),
        content: const Text("Da li sigurno želiš obrisati komentar?"),
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
        await ApiService.deleteComment(id);

        final text = _commentSearchCtrl.text.trim();
        final String? content = text.isEmpty ? null : text;
        await loadComments(content: content, userId: _selectedCommentUserId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Greška: $e")),
          );
        }
      }
    }
  }

  void deleteCommentAnswer(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Potvrda brisanja"),
        content: const Text("Da li sigurno želiš obrisati odgovor?"),
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
        await ApiService.deleteCommentAnswer(id);

        final text = _answerSearchCtrl.text.trim();
        final String? content = text.isEmpty ? null : text;
        await loadCommentAnswers(
          content: content,
          userId: _selectedAnswerUserId,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Greška: $e")),
          );
        }
      }
    }
  }

  void showEditStatusDialog(UserReport report) {
    int selectedStatus = report.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Izmijeni status prijave"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<int>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: "Status"),
                items: const [
                  DropdownMenuItem(value: 0, child: Text("Kreirano")),
                  DropdownMenuItem(value: 1, child: Text("U razmatranju")),
                  DropdownMenuItem(value: 2, child: Text("Riješeno")),
                  DropdownMenuItem(value: 3, child: Text("Odbijeno")),
                ],
                onChanged: (value) => setState(() => selectedStatus = value!),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Otkaži"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.updateUserReport(report, selectedStatus);
                  Navigator.pop(context);

                  final text = _reportSearchCtrl.text.trim();
                  final String? reason = text.isEmpty ? null : text;

                  await loadUserReports(
                    reason: reason,
                    status: _selectedReportStatus,
                    userReportedId: _selectedReportedUserId,
                    reportedByUserId: _selectedReportedByUserId,
                  );
                } catch (e) {
                  if (context.mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController activeSearchCtrl;
    String searchHint;

    if (selectedSidebar == "KOMENTARI") {
      activeSearchCtrl = _commentSearchCtrl;
      searchHint = "Pretraži komentare...";
    } else if (selectedSidebar == "ODGOVORI") {
      activeSearchCtrl = _answerSearchCtrl;
      searchHint = "Pretraži odgovore...";
    } else {
      activeSearchCtrl = _reportSearchCtrl;
      searchHint = "Pretraži prijave (razlog)...";
    }

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
                        navTab("FORUM", context, isActive: true),
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
                        backgroundColor: const Color.fromARGB(
                          255,
                          181,
                          156,
                          74,
                        ),
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
                child: Row(
                  children: [
                    Container(
                      width: 180,
                      color: Colors.white.withOpacity(0.8),
                      padding: const EdgeInsets.only(top: 32, left: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          sidebarOption("KOMENTARI", Icons.comment),
                          const SizedBox(height: 24),
                          sidebarOption("ODGOVORI", Icons.reply),
                          const SizedBox(height: 24),
                          sidebarOption("PRIJAVE", Icons.report),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: TextField(
                                    controller: activeSearchCtrl,
                                    onChanged: (_) => _onSearchOrFilterChanged(),
                                    decoration: InputDecoration(
                                      hintText: searchHint,
                                      prefixIcon: const Icon(Icons.search),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.9),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                ..._buildFiltersWidgets(),
                                TextButton.icon(
                                  onPressed: () {
                                    _commentSearchCtrl.clear();
                                    _answerSearchCtrl.clear();
                                    _reportSearchCtrl.clear();

                                    setState(() {
                                      _selectedCommentUserId = null;
                                      _selectedAnswerUserId = null;
                                      _selectedReportStatus = null;
                                      _selectedReportedUserId = null;
                                      _selectedReportedByUserId = null;
                                    });

                                    if (selectedSidebar == "KOMENTARI") {
                                      loadComments();
                                    } else if (selectedSidebar == "ODGOVORI") {
                                      loadCommentAnswers();
                                    } else {
                                      loadUserReports();
                                    }
                                  },
                                  icon: const Icon(Icons.restart_alt),
                                  label: const Text("Reset"),
                                ),
                              ],
                            ),
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

  List<Widget> _buildFiltersWidgets() {
    if (selectedSidebar == "KOMENTARI") {
      return [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<int?>(
            value: _selectedCommentUserId,
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
                  child: Text(u.displayName),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedCommentUserId = value);
              _onSearchOrFilterChanged();
            },
          ),
        ),
      ];
    } else if (selectedSidebar == "ODGOVORI") {
      return [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<int?>(
            value: _selectedAnswerUserId,
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
                  child: Text(u.displayName),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedAnswerUserId = value);
              _onSearchOrFilterChanged();
            },
          ),
        ),
      ];
    } else if (selectedSidebar == "PRIJAVE") {
      return [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            value: _selectedReportStatus,
            decoration: InputDecoration(
              labelText: "Status prijave",
              prefixIcon: const Icon(Icons.info_outline),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem<int?>(value: null, child: Text("Svi statusi")),
              DropdownMenuItem<int?>(value: 0, child: Text("Kreirano")),
              DropdownMenuItem<int?>(value: 1, child: Text("U razmatranju")),
              DropdownMenuItem<int?>(value: 2, child: Text("Riješeno")),
              DropdownMenuItem<int?>(value: 3, child: Text("Odbijeno")),
            ],
            onChanged: (value) {
              setState(() => _selectedReportStatus = value);
              _onSearchOrFilterChanged();
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            value: _selectedReportedUserId,
            decoration: InputDecoration(
              labelText: "Prijavljen korisnik",
              prefixIcon: const Icon(Icons.person_off),
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
                  child: Text(u.displayName),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedReportedUserId = value);
              _onSearchOrFilterChanged();
            },
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int?>(
            value: _selectedReportedByUserId,
            decoration: InputDecoration(
              labelText: "Prijavio korisnik",
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
                  child: Text(u.displayName),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedReportedByUserId = value);
              _onSearchOrFilterChanged();
            },
          ),
        ),
      ];
    }

    return [];
  }

  Widget sidebarOption(String label, IconData icon) {
    final bool isActive = selectedSidebar == label;

    return InkWell(
      onTap: () {
        setState(() {
          selectedSidebar = label;

          if (label == "PRIJAVE") {
            _selectedReportStatus = 0;
            _selectedReportedUserId = null;
            _selectedReportedByUserId = null;
            _reportSearchCtrl.clear();

            loadUserReports(status: 0);
          } else if (label == "KOMENTARI") {
            _commentSearchCtrl.clear();
            _selectedCommentUserId = null;
            loadComments();
          } else if (label == "ODGOVORI") {
            _answerSearchCtrl.clear();
            _selectedAnswerUserId = null;
            loadCommentAnswers();
          }
        });
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
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.black : Colors.grey[700],
                backgroundColor: isActive
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (selectedSidebar) {
      case "KOMENTARI":
        if (_loadingComments && comments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (comments.isEmpty) {
          return const Center(
            child: Text("Nema komentara za odabrane filtere."),
          );
        }
        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: commentCard(comment),
            );
          },
        );

      case "ODGOVORI":
        if (_loadingCommentAnswers && commentAnswers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (commentAnswers.isEmpty) {
          return const Center(
            child: Text("Nema odgovora za odabrane filtere."),
          );
        }
        return ListView.builder(
          itemCount: commentAnswers.length,
          itemBuilder: (context, index) {
            final reply = commentAnswers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: commentAnswerCard(reply),
            );
          },
        );

      case "PRIJAVE":
        if (_loadingReports && reports.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (reports.isEmpty) {
          return const Center(
            child: Text("Nema prijava za odabrane filtere."),
          );
        }
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: reportCard(report),
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

  Widget commentCard(Comment comment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${comment.user.firstName} ${comment.user.lastName}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(comment.content),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up, size: 16, color: Colors.green),
              Text(" ${comment.likes}"),
              const SizedBox(width: 16),
              const Icon(Icons.thumb_down, size: 16, color: Colors.red),
              Text(" ${comment.dislikes}"),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteComment(comment.id),
              ),
            ],
          ),
          const Divider(),
          ...comment.replies.map(
            (r) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${r.user.firstName} ${r.user.lastName}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(r.content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget commentAnswerCard(CommentAnswer answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${answer.user.firstName} ${answer.user.lastName}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(answer.content),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up, size: 16, color: Colors.green),
              Text(" ${answer.likes}"),
              const SizedBox(width: 16),
              const Icon(Icons.thumb_down, size: 16, color: Colors.red),
              Text(" ${answer.dislikes}"),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteCommentAnswer(answer.id),
              ),
            ],
          ),
          const Divider(),
          Text(
            "Na komentar: ${answer.parentComment.content}",
            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget reportCard(UserReport report) {
    final statusText = switch (report.status) {
      0 => "Kreirano",
      1 => "U razmatranju",
      2 => "Riješeno",
      3 => "Odbijeno",
      _ => "Nepoznato",
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.report_problem_outlined,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Razlog:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Text(report.reason),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Status:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Text(statusText),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Prijavio:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Text(
                        "${report.reportedByUser.firstName} ${report.reportedByUser.lastName}",
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Prijavljen:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Text(
                        "${report.userReported.firstName} ${report.userReported.lastName}",
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Datum prijave:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Text(formatShortDate(report.createdAt)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => showEditStatusDialog(report),
            tooltip: "Izmijeni status",
          ),
        ],
      ),
    );
  }
}
