import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './../HOME/home_page.dart';
import './../BOOKS/books_page.dart';
import './../SHOP/shop_page.dart';
import './../SETTINGS/settings_page.dart';
import '../models/comment.dart';
import '../services/api_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selectedIndex = 3;
  List<Comment> comments = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 3;

  final TextEditingController commentController = TextEditingController();

  int get currentUserId => ApiService.userID;
  bool get isAdmin => ApiService.isAdmin;
  final Map<int, bool?> myReactions = {};
  final Map<int, bool?> myCommentReactions = {};

  @override
  void initState() {
    super.initState();
    loadComments();
  }

  bool _isOwnerOfComment(Comment c) {
    final uid = c.user.id;
    return uid == currentUserId;
  }

  bool _isOwnerOfReply(CommentReply r) {
    final uid = (r.user?.id ?? r.userId);
    return uid == currentUserId;
  }

  bool _canDeleteComment(Comment c) => isAdmin || _isOwnerOfComment(c);
  bool _canDeleteReply(CommentReply r) => isAdmin || _isOwnerOfReply(r);

  Future<void> loadComments({bool reset = true}) async {
    if (_isLoading || _isLoadingMore) return;

    if (reset) {
      setState(() {
        _isLoading = true;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (!_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await ApiService.fetchCommentsPaged(
        page: _page,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          comments = result.items;
        } else {
          comments.addAll(result.items);
        }

        _hasMore = result.hasMore;
        _page++;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });

      print("Error fetching comments: $e");
      return;
    }

    try {
      final my = await ApiService.fetchMyReactions(currentUserId);

      if (my == null) return;

      final dynamic rawItems = my['items'];
      if (rawItems is! List) return;

      myCommentReactions.clear();
      myReactions.clear();

      for (final raw in rawItems) {
        if (raw is! Map) continue;

        final int? commentId = raw['commentId'] as int?;
        final int? commentAnswerId = raw['commentAnswerId'] as int?;
        final bool? isLike = raw['isLike'] as bool?;

        if (commentId != null && isLike != null) {
          myCommentReactions[commentId] = isLike;
        }

        if (commentAnswerId != null && isLike != null) {
          myReactions[commentAnswerId] = isLike;
        }
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print("Error fetching my reactions: $e");
    }
  }

  void _addComment(String content) async {
    if (content.trim().isEmpty) return;

    try {
      await ApiService.addComment(content);
      commentController.clear();
      loadComments();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding comment: $e")));
    }
  }

  void _addReply(
    int parentCommentId,
    String text, {
    int? replyToCommentId,
  }) async {
    if (text.trim().isEmpty) return;
    try {
      await ApiService.addCommentAnswer(
        parentCommentId,
        text,
        replyToCommentId: replyToCommentId,
      );
      loadComments();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding reply: $e")));
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required IconData icon,
    required String confirmText,
    Color iconColor = Colors.redAccent,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 26),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Otkaži',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF96A6DA),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<String?> _showReportDialog({
    required String title,
    required String hintText,
  }) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 26),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      color: Colors.redAccent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pomozite nam održati zajednicu sigurnom i prijavite neprimjeren sadržaj.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: hintText,
                      filled: true,
                      fillColor: const Color(0xFFF5F1F1),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFF96A6DA),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Otkaži',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              reasonController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF96A6DA),
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const Text(
                            'Prijavi',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    return result;
  }

  void deleteComment(int id) async {
    final c = comments.firstWhere(
      (x) => x.id == id,
      orElse: () => null as dynamic,
    );
    if (c == null || !_canDeleteComment(c)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You don't have permission to delete this comment."),
        ),
      );
      return;
    }
    final confirmed = await _showConfirmDialog(
      title: 'Obrisati komentar?',
      message: 'Ova radnja se ne može poništiti.',
      icon: Icons.delete_outline,
      confirmText: 'Obriši',
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteComment(id);
        loadComments();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void deleteCommentAnswer(int id) async {
    CommentReply? r;
    for (final c in comments) {
      r = c.replies.firstWhere(
        (x) => x.id == id,
        orElse: () => null as dynamic,
      );
      if (r != null) break;
    }
    if (r == null || !_canDeleteReply(r)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You don't have permission to delete this reply."),
        ),
      );
      return;
    }
    final confirmed = await _showConfirmDialog(
      title: 'Obrisati odgovor?',
      message: 'Ova radnja se ne može poništiti.',
      icon: Icons.delete_outline,
      confirmText: 'Obriši',
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteCommentAnswer(id);
        loadComments();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _toggleReplyReaction(CommentReply reply, bool isLike) async {
    final current = myReactions[reply.id];

    try {
      if (current == isLike) {
        await ApiService.deleteCommentReaction(commentAnswerId: reply.id);
        myReactions[reply.id] = null;
      } else {
        await ApiService.addCommentReaction(
          commentAnswerId: reply.id,
          isLike: isLike,
        );
        myReactions[reply.id] = isLike;
      }

      loadComments();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error with reaction: $e")));
    }
  }

  Future<void> _toggleCommentReaction(Comment comment, bool isLike) async {
    final current = myCommentReactions[comment.id];

    try {
      if (current == isLike) {
        await ApiService.deleteCommentReaction(commentId: comment.id);
        myCommentReactions[comment.id] = null;
      } else {
        await ApiService.addCommentReaction(
          commentId: comment.id,
          isLike: isLike,
        );
        myCommentReactions[comment.id] = isLike;
      }

      loadComments();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error with reaction: $e")));
    }
  }

  Future<void> _reportComment(Comment comment) async {
    final reason = await _showReportDialog(
      title: 'Prijavi komentar',
      hintText: 'Opišite zašto prijavljujete ovaj komentar...',
    );

    if (reason == null) return;

    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite razlog prijave.')),
      );
      return;
    }

    try {
      await ApiService.reportComment(
        userReportedId: comment.user.id,
        reason: reason.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hvala vam, vaša prijava je uspješna.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška prilikom prijave komentara: $e')),
      );
    }
  }

  Future<void> _reportReply(CommentReply reply) async {
    final reason = await _showReportDialog(
      title: 'Prijavi odgovor',
      hintText: 'Opišite zašto prijavljujete ovaj odgovor...',
    );

    if (reason == null) return;

    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo unesite razlog prijave.')),
      );
      return;
    }

    final reportedUserId = reply.user?.id ?? reply.userId;

    if (reportedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nije moguće prijaviti ovaj odgovor.')),
      );
      return;
    }

    try {
      await ApiService.reportComment(
        userReportedId: reportedUserId,
        reason: reason.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hvala vam, vaša prijava je uspješna.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška prilikom prijave odgovora: $e')),
      );
    }
  }

  String _initials(String? firstName, String? lastName) {
    final f = (firstName ?? '').trim();
    final l = (lastName ?? '').trim();

    String out = '';
    if (f.isNotEmpty) out += f[0].toUpperCase();
    if (l.isNotEmpty) out += l[0].toUpperCase();

    if (out.isEmpty) return '?';
    return out.length > 2 ? out.substring(0, 2) : out;
  }

  Widget _profileAvatar({
    required String initials,
    String? imageUrl,
    double radius = 16,
  }) {
    final url = ApiService.getImageUrl(imageUrl);

    final hasValidUrl = url.isNotEmpty && url.startsWith('http');

    if (hasValidUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF9DAAE0),
        child: ClipOval(
          child: Image.network(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: radius * 0.9,
                    color: Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // fallback ako nema slike
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF9DAAE0),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 212, 217, 246),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('eKnjiga', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'For readers, by bookworms.',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 212, 217, 246),
              Color.fromARGB(255, 141, 158, 219),
              Color.fromARGB(255, 181, 156, 74),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: "Napiši komentar...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          size: 25,
                          color: Colors.black,
                        ),
                        onPressed: () => _addComment(commentController.text),
                      ),
                    ],
                  ),
                ),
                ...comments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final comment = entry.value;
                  return _commentCard(index, comment);
                }),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      onTap:
                          _isLoadingMore
                              ? null
                              : () => loadComments(reset: false),
                      child: Text(
                        _isLoadingMore ? 'Učitavanje...' : 'Učitaj još',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        onTap: (index) {
          if (index == _selectedIndex) return;
          setState(() => _selectedIndex = index);

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BookPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ShopPage()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MessagesPage()),
              );
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 32), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book, size: 32),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag, size: 32),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.comment, size: 32),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 32),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget _commentCard(int index, Comment comment) {
    final TextEditingController replyController = TextEditingController();
    final my = myCommentReactions[comment.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _profileAvatar(
                initials: _initials(
                  comment.user.firstName,
                  comment.user.lastName,
                ),
                imageUrl: comment.user.profileImage,
                radius: 16,
              ),
              const SizedBox(width: 10),
              Text(
                "${comment.user.firstName} ${comment.user.lastName}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat('dd.MM.yyyy').format(comment.createdAt.toLocal()),
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),

              if (!_isOwnerOfComment(comment))
                IconButton(
                  icon: const Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: Colors.black87,
                  ),
                  tooltip: "Prijavi komentar",
                  onPressed: () => _reportComment(comment),
                ),

              if (_canDeleteComment(comment))
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => deleteComment(comment.id),
                  tooltip: "Obriši komentar",
                ),
            ],
          ),

          const SizedBox(height: 6),
          Text(comment.content),

          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  my == true ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  size: 18,
                ),
                onPressed: () => _toggleCommentReaction(comment, true),
                tooltip: "Like",
              ),
              Text("${comment.likes}"),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  my == false
                      ? Icons.thumb_down
                      : Icons.thumb_down_alt_outlined,
                  size: 18,
                ),
                onPressed: () => _toggleCommentReaction(comment, false),
                tooltip: "Dislike",
              ),
              Text("${comment.dislikes}"),
            ],
          ),

          const SizedBox(height: 8),
          ...comment.replies.asMap().entries.map((entry) {
            final replyIndex = entry.key;
            final reply = entry.value;
            return _replyCard(index, replyIndex, reply);
          }),

          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: replyController,
                    decoration: const InputDecoration(
                      hintText: "Napišite komentar...",
                      filled: true,
                      fillColor: Color(0xFF7AC6D2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5, top: 6),
                child: IconButton(
                  icon: const Icon(Icons.send, size: 25, color: Colors.black),
                  onPressed: () => _addReply(comment.id, replyController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _replyCard(int commentIndex, int replyIndex, CommentReply reply) {
    final my = myReactions[reply.id];

    final userName =
        reply.user != null
            ? "${reply.user!.firstName} ${reply.user!.lastName}"
            : "Korisnik #${reply.userId ?? '-'}";

    return Container(
      margin: const EdgeInsets.only(left: 20, top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF94B4C1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _profileAvatar(
                initials:
                    reply.user != null
                        ? _initials(reply.user!.firstName, reply.user!.lastName)
                        : _initials(userName, null), // fallback
                imageUrl: reply.user?.profileImage,
                radius: 14,
              ),
              const SizedBox(width: 10),
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                DateFormat('dd.MM.yyyy').format(reply.createdAt.toLocal()),
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),

              if (!_isOwnerOfReply(reply))
                IconButton(
                  icon: const Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: Colors.black87,
                  ),
                  tooltip: "Prijavi odgovor",
                  onPressed: () => _reportReply(reply),
                ),

              if (_canDeleteReply(reply))
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => deleteCommentAnswer(reply.id),
                  tooltip: "Obriši odgovor",
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(reply.content),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  my == true ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  size: 18,
                ),
                onPressed: () => _toggleReplyReaction(reply, true),
                tooltip: "Like",
              ),
              Text("${reply.likes}"),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  my == false
                      ? Icons.thumb_down
                      : Icons.thumb_down_alt_outlined,
                  size: 18,
                ),
                onPressed: () => _toggleReplyReaction(reply, false),
                tooltip: "Dislike",
              ),
              Text("${reply.dislikes}"),
            ],
          ),
        ],
      ),
    );
  }
}
