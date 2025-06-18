import 'package:flutter/material.dart';
import 'package:su_track/screens/dashBoard.dart';
import 'package:su_track/screens/userScreen/profile.dart';
import 'package:su_track/services/notifications/getNotifications.dart';
import 'package:su_track/services/notifications/updateNotificationStatus.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'package:url_launcher/url_launcher.dart';
import '../navBar.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  int _selectedIndex = 1;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = fetchNotifications(context);
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      _notificationsFuture = fetchNotifications(context);
      setState(() {});
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _openNotificationDetails(String id , Map<String , dynamic> notification) async {
    if (notification['is_read']=='0') {
      try {
        await markNotificationAsRead(context, notification['notification_id']);
        setState(() {
          notification['is_read'] = true;
        });
      } catch (e) {
        print('Error marking notification as read: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return AlertDialog(
          backgroundColor: themeProvider.cardColor,
          title: Text(
            notification['title'] ?? 'No Title',
            style: TextStyle(color: themeProvider.textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification['content'] ?? 'No Content',
                style: TextStyle(color: themeProvider.textColor),
              ),
              SizedBox(height: 10),
              Text(
                'Date: ${notification['date'] ?? 'No Date'}',
                style: TextStyle(color: themeProvider.textColor),
              ),
              if (notification['link'] != null)
                TextButton(
                  onPressed: () async {
                    final url = Uri.parse(notification['link']);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    'Open Link',
                    style: TextStyle(color: themeProvider.primaryColor),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: themeProvider.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        drawer: NavBar(),
        backgroundColor: themeProvider.backgroundColor,
        appBar: AppBar(
          iconTheme: IconThemeData(color: themeProvider.iconColor),
          backgroundColor: themeProvider.backgroundColor,
          elevation: 0,
          title: Text(
            'Notifications',
            style: TextStyle(
              color: themeProvider.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: themeProvider.bottomNavBarColor,
          currentIndex: _selectedIndex,
          selectedItemColor: themeProvider.bottomBarSelectedColor,
          unselectedItemColor: themeProvider.bottomBarUnselectedColor,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardPage()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshNotifications,
          color: themeProvider.primaryColor,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !_isRefreshing) {
                return Center(
                  child: Image.asset(
                    'assets/images/loading.gif', // Replace with your GIF
                    height: 70,
                    width: double.infinity,
                    color: themeProvider.lionColor,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'A problem in loading notifications',
                    style: TextStyle(color: themeProvider.textColor),
                  ),
                );
              }

              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return Center(
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 88,
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final title = notification['title'] ?? '';
                  final description = notification['description'] ?? '';
                  final isUnread = notification['is_read'] == '0';
                  final notificationId = notification['notification_id'];

                  return Container(
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeProvider.dividerColor),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      onTap: () => _openNotificationDetails(notificationId, notification),
                      title: Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.textColor,
                                  ),
                                ),
                                if (isUnread == true)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notification_important,
                                        color: themeProvider.primaryColor,
                                      ),
                                    ],
                                  ),
                                if (isUnread == false)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notifications_none_outlined,
                                        color: themeProvider.primaryColor,
                                      ),
                                    ],
                                  ),
                                if (notification['is_expanded'] == true) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeProvider.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
