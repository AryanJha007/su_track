import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:su_track/screens/dailyReporting/dailyReporting.dart';
import 'package:su_track/screens/dashBoard.dart';
import 'package:su_track/screens/expense/expense.dart';
import 'package:su_track/screens/leave/applyLeave.dart';
import 'package:su_track/screens/od/odApply.dart';

import '../services/auth/logout.dart';
import 'Ta/taView.dart';
import 'dailyReporting/getAttendence.dart';
import '../providers/theme_provider.dart';
import 'map/location_map.dart';

class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
  });

  // Cache decoration

  // Use const for static items
  static const _navItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard},
    {'title': 'Leave', 'icon': Icons.event_note},
    {'title': 'OD', 'icon': Icons.work},
    // ... other items
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Drawer(
        backgroundColor: themeProvider.backgroundColor,
        child: Container(
          width: 30.0,
          child: ListView(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (themeProvider.isDarkMode)
                      SizedBox(
                        width: 150.0,
                        height: 105.0,
                        child: Image.asset(
                          'assets/images/lion.png',
                        ),
                      ),
                    if (!themeProvider.isDarkMode)
                      SizedBox(
                        width: 150.0,
                        height: 105.0,
                        child: Image.asset(
                          'assets/images/lion_light.png',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildNavItem(
                themeProvider: themeProvider,
                icon: Icons.calendar_today,
                title: "Daily Reporting",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DailyReportingScreen()),
                  );
                },
              ),
              _buildNavItem(
                themeProvider: themeProvider,
                icon: Icons.monetization_on_outlined,
                title: "Expense",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ExpenseScreen()),
                  );
                },
              ),
              _buildNavItem(
                themeProvider: themeProvider,
                icon: Icons.trending_up,
                title: "Leave",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LeaveApplicationScreen()),
                  );
                },
              ),
              _buildNavItem(
                themeProvider: themeProvider,
                icon: Icons.info,
                title: "OD",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OdApplicationScreen()),
                  );
                },
              ),
              _buildNavItem(
                themeProvider: themeProvider,
                icon: Icons.dashboard,
                title: "Dash Board",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardPage()),
                  );
                },
              ),
          _buildNavItem(
            themeProvider: themeProvider,
            icon: Icons.travel_explore_rounded,
            title: "TA",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => TAView()),
              );
            },
          ),
              _buildNavItem(
                themeProvider: themeProvider,
                icon: Icons.thumb_up,
                title: "Attendance",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => attendenceView()),
                  );
                },
              ),
              _buildNavItem(
                  themeProvider: themeProvider,
                  icon: Icons.location_history,
                  title: "Location",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LocationMapScreen()),
                    );
                  }),
              _buildNavItem(
                themeProvider: themeProvider,
                icon: Icons.logout,
                title: "LogOut",
                onTap: () {
                  logout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required ThemeProvider themeProvider,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // decoration: BoxDecoration(
      //   color: themeProvider.cardColor,
      //   borderRadius: BorderRadius.all(Radius.circular(12)),
      // ),
      child: ListTile(
        leading: Icon(icon, color: themeProvider.iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: themeProvider.textColor,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(12),
        // ),
      ),
    );
  }
}
