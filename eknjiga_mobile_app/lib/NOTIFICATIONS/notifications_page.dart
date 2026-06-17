import 'dart:async';
import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const LinearGradient _pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFD4D8F3), Color(0xFF8D9EDB), Color(0xFFB59C4A)],
    stops: [0.0, 0.56, 1.0],
  );

  Timer? _timer;
  bool _isLoading = true;
  String? _error;
  List<AppNotification> _notifications = [];

  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadNotifications(showLoading: false),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({
    bool showLoading = true,
    bool reset = true,
  }) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else if (!reset) {
      if (!_hasMore || _isLoadingMore) return;

      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await ApiService.fetchNotificationsPaged(
        page: _page,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        if (reset) {
          _notifications = result.items;
        } else {
          _notifications.addAll(result.items);
        }

        _hasMore = result.hasMore;
        _page++;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await ApiService.markNotificationAsRead(notification.id);
      await _loadNotifications(showLoading: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  IconData _iconForTitle(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('plać') || lower.contains('plac')) {
      return Icons.payment;
    }

    if (lower.contains('rezerv')) {
      return Icons.bookmark_border;
    }

    if (lower.contains('otkaz')) {
      return Icons.cancel_outlined;
    }

    return Icons.shopping_bag_outlined;
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month.$year. $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4D8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4D8F3),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifikacije',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: _pageGradient),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          'Nemate notifikacija.',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: Center(
              child: InkWell(
                onTap:
                    _isLoadingMore
                        ? null
                        : () => _loadNotifications(
                          showLoading: false,
                          reset: false,
                        ),
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
          );
        }

        final notification = _notifications[index];

        return _NotificationCard(
          notification: notification,
          icon: _iconForTitle(notification.title),
          formattedDate: _formatDate(notification.createdAt),
          onTap: () => _markAsRead(notification),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final String formattedDate;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread ? Colors.white : Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread ? Colors.black87 : Colors.transparent,
              width: unread ? 1.1 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4D8F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.black87, size: 23),
                  ),
                  if (unread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15.5,
                        fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12.5,
                          ),
                        ),
                        const Spacer(),
                        if (unread)
                          const Text(
                            'Označi pročitano',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
