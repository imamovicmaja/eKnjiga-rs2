import 'package:flutter/material.dart';
import './../Home/home_page.dart';
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

  void loadComments() async {
    try {
      final fetched = await ApiService.fetchComments();
      setState(() {
        comments = fetched;
      });
    } catch (e) {
      print("Error fetching comments: $e");
      return;
    }

    try {
      final my = await ApiService.fetchMyReactions(currentUserId);

      if (my == null) {
        return;
      }

      final dynamic rawItems = my['items'];

      if (rawItems is! List) {
        return;
      }

      final List items = rawItems;

      myCommentReactions.clear();
      myReactions.clear();

      for (final raw in items) {
        if (raw is! Map) continue;

        final Map e = raw;

        final int? commentId = e['commentId'] as int?;
        final int? commentAnswerId = e['commentAnswerId'] as int?;
        final bool? isLike = e['isLike'] as bool?;

        if (commentId != null && isLike != null) {
          myCommentReactions[commentId] = isLike;
        }
        if (commentAnswerId != null && isLike != null) {
          myReactions[commentAnswerId] = isLike;
        }
      }

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
        currentUserId,
        replyToCommentId: replyToCommentId,
      );
      loadComments();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error adding reply: $e")));
    }
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete confirmation"),
            content: const Text(
              "Are you sure you want to delete this comment?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete confirmation"),
            content: const Text("Are you sure you want to delete this reply?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
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
        await ApiService.deleteCommentReaction(
          userId: currentUserId,
          commentAnswerId: reply.id,
        );
        myReactions[reply.id] = null;
      } else {
        await ApiService.addCommentReaction(
          userId: currentUserId,
          commentAnswerId: reply.id,
          isLike: isLike,
        );
        myReactions[reply.id] = isLike;
      }

      loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error with reaction: $e")),
      );
    }
  }

  Future<void> _toggleCommentReaction(Comment comment, bool isLike) async {
    final current = myCommentReactions[comment.id];
    try {
      if (current == isLike) {
        await ApiService.deleteCommentReaction(
          userId: currentUserId,
          commentId: comment.id,
        );
        myCommentReactions[comment.id] = null;
      } else {
        await ApiService.addCommentReaction(
          userId: currentUserId,
          commentId: comment.id,
          isLike: isLike,
        );
        myCommentReactions[comment.id] = isLike;
      }

      loadComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error with reaction: $e")),
      );
    }
  }

  Future<void> _reportComment(Comment comment) async {
    final TextEditingController reasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Prijavi komentar"),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Opišite zašto prijavljujete ovaj komentar...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Otkaži"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Prijavi"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter a reason for the report."),
          ),
        );
        return;
      }

      try {
        await ApiService.reportComment(
          userReportedId: comment.user.id,
          reason: reason,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hvala vam, vaša prijava je uspjesna."),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Greška prilikom prijave komentara: $e"),
          ),
        );
      }
    }
  }

  Future<void> _reportReply(CommentReply reply) async {
    final TextEditingController reasonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Prijavi odgovor"),
        content: TextField(
          controller: reasonController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: "Opišite zašto prijavljujete ovaj odgovor...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Otkaži"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Prijavi"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Molimo unesite razlog prijave."),
          ),
        );
        return;
      }

      final reportedUserId = reply.user?.id ?? reply.userId;

      if (reportedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nije moguće prijaviti ovaj odgovor."),
          ),
        );
        return;
      }

      try {
        await ApiService.reportComment(
          userReportedId: reportedUserId,
          reason: reason,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Hvala vam, vaša prijava je uspješna."),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Greška prilikom prijave odgovora: $e"),
          ),
        );
      }
    }
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
            Text('eBook', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ...comments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final comment = entry.value;
                  return _commentCard(index, comment);
                }),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: "Napiši komentar...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5, top: 6),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          size: 25,
                          color: Colors.black,
                        ),
                        onPressed: () => _addComment(commentController.text),
                      ),
                    ),
                  ],
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
              Text(
                "${comment.user.firstName} ${comment.user.lastName}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                "${comment.createdAt.toLocal()}".split(' ')[0],
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),

              if (!_isOwnerOfComment(comment))
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.black87),
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
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                "${reply.createdAt.toLocal()}".split(' ')[0],
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),

              if (!_isOwnerOfReply(reply))
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.black87),
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
