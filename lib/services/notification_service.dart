import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true; // Default: enabled
  }

  // Set notification preference
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    print('📱 Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  // Show in-app notification
  static void showInAppNotification(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.notifications,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) async {
    // Check if notifications are enabled
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('📱 Notification suppressed (notifications disabled)');
      return;
    }

    if (!context.mounted) return;

    // Show overlay notification
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlay(
        title: title,
        message: message,
        icon: icon,
        backgroundColor: backgroundColor ?? Colors.orangeAccent,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // Show recipe added notification
  static void showRecipeAddedNotification(BuildContext context, String recipeName) {
    showInAppNotification(
      context,
      title: '🎉 Recipe Added!',
      message: '"$recipeName" has been added to your recipes.',
      icon: Icons.restaurant_menu,
      backgroundColor: Colors.green,
    );
  }

  // Show simple snackbar notification (fallback)
  static void showSnackbarNotification(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
  }) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Custom notification overlay widget
class _NotificationOverlay extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onDismiss;

  const _NotificationOverlay({
    required this.title,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.onDismiss,
  });

  @override
  State<_NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<_NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _dismiss,
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
