import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:su_track/screens/expense/expense.dart';
import 'package:su_track/screens/navBar.dart';
import 'package:su_track/screens/userScreen/notification.dart';
import 'package:su_track/screens/userScreen/profile.dart';
import '../main.dart';
import '../services/auth/loggedIn.dart';
import '../services/backgroundService.dart';
import '../services/punchingLog/updateStatus.dart';
import 'dailyReporting/getAttendence.dart';
import 'leave/applyLeave.dart';
import 'od/odApply.dart';
import 'package:su_track/services/punchingLog/insertPunchingLog.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';
import 'package:geolocator/geolocator.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with WidgetsBindingObserver {
  bool isToggledIn = constants.punch_status == '1';
  DateTime lastToggleDate = DateTime.now();
  int selectedIndex = 0;
  bool value1 = constants.punch_status == '1';
  bool _isTogglingPunch = false;
  List<String> welcomeMessages = [
    'Want a leave? We got you covered!',
    'Want to see your attendance? We got you covered!',
    'Want to apply OD? We got you covered!',
    'Want to see Expenses? We got you covered!'
  ];

  int currentMessageIndex = 0;
  bool showMessage = false;
  bool _isMessageVisible = true;
  List<bool> tileVisibility = [false, false, false, false];
  String? userName;

  // Cache the welcome message widget
  late final List<Widget> _welcomeMessageWidgets = welcomeMessages.map((msg) =>
      Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => Text(
          msg,
          style: TextStyle(
            color: themeProvider.textColor,
            fontSize: 14,
          ),
        ),
      ),
  ).toList();

  static const _tileDecoration = BoxDecoration(
    color: Color(0xFF2C2C2E),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  Timer? _messageTimer;
  Timer? _fadeTimer;
  Timer? _locationCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadToggleState();
    _startMessageLoop();
    _fetchUserName();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadToggleState();
    }
  }

  Future<void> _loadToggleState() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? savedToggleState = prefs.getBool('isToggledIn');
    final String? savedToggleDate = prefs.getString('lastToggleDate');
    lastToggleDate = DateTime.parse(savedToggleDate ?? DateTime.now().toIso8601String());
    if(lastToggleDate.day != DateTime.now().day)
    {
      value1 = await updateStatus(context: context, status: "0");
    }
    setState(()  {
      isToggledIn = savedToggleState ?? false;
      if (lastToggleDate.day != DateTime.now().day) {
        isToggledIn = false;
        lastToggleDate = DateTime.now();
        LoggedIn.savePunchingStatus(false);
        print(isToggledIn);
      }
      if (isToggledIn) {
        _startLocationServiceMonitoring();
      }
    });
  }

  Future<void> _fetchUserName() async {
    final name = await LoggedIn.getUserName();
    if (mounted) {
      setState(() {
        userName = name;
      });
    }
  }

  Future<void> _saveToggleState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isToggledIn', value);
    await prefs.setString('lastToggleDate', DateTime.now().toIso8601String());
    await LoggedIn.savePunchingStatus(value);
  }

  Future<void> _handleToggleChange(bool value) async {
    final authData = await LoggedIn.getAuthData();
    if (_isTogglingPunch) return;
    setState(() => _isTogglingPunch = true);
    try {
      if (value) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
          if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Location permission is required to punch in')),
            );
            return;
          }
        }
        bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!isLocationServiceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enable location services to punch in')),
          );
          return;
        }
        dynamic result = '';
        result = await insertPunchingLog(context: context,direction: 1);
        value1 = await updateStatus(context: context, status: "1");
        await LoggedIn.savePunchingStatus(true);
        await requestLocationPermission();
        await LocationServiceManager.startLocationService();
        if (result['success']) {
          setState(() {
            isToggledIn = value1;
            _saveToggleState(value1);
            _startLocationServiceMonitoring();
          });
        } else {
          setState(() {
            isToggledIn = value1;
            _saveToggleState(value1);
            _startLocationServiceMonitoring();
          });
        }
      } else {
        await _punchOut();
        _saveToggleState(false);
      }
    } finally {
      if (mounted) setState(() => _isTogglingPunch = false);
    }
  }

  Future<void> _punchOut() async {
    final authData = await LoggedIn.getAuthData();
    dynamic result ;
    bool value1 = await updateStatus(context: context, status: "0");
      result = await insertPunchingLog(context: context,direction: 2);
    await LoggedIn.savePunchingStatus(false);
    await LocationServiceManager.stopLocationService();
    setState(() {
      isToggledIn = !value1;
      _saveToggleState(!value1);
      _locationCheckTimer?.cancel();
    });
  }

  void _startMessageLoop() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showMessage = true;
          tileVisibility[currentMessageIndex] = true;
        });
      }
    });

    _messageTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          showMessage = false;
        });

        _fadeTimer = Timer(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              currentMessageIndex = (currentMessageIndex + 1) % welcomeMessages.length;
              showMessage = true;
              tileVisibility[currentMessageIndex] = true;

              if (tileVisibility.every((visible) => visible)) {
                Future.delayed(Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() {
                      tileVisibility = [false, false, false, false];
                      currentMessageIndex = 0;
                    });
                  }
                });
              }
            });
          }
        });
      }
    });
  }

  void _startLocationServiceMonitoring() {
    if (!isToggledIn) return;

    _locationCheckTimer?.cancel();
    _locationCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (!isToggledIn) {
        timer.cancel();
        return;
      }

      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services disabled. Punching out.')),
        );
        await _punchOut();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        drawer: NavBar(),
        backgroundColor: themeProvider.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Dashboard',
            style: TextStyle(color: themeProvider.textColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: themeProvider.backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: themeProvider.iconColor),
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: themeProvider.textColor,
              ),
              onPressed: () {
                themeProvider.toggleTheme();
              },
            ),
            Row(
              children: [
                Text(
                  isToggledIn ? 'In' : 'Out',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: isToggledIn ? themeProvider.primaryColor : themeProvider.textColor,
                  ),
                ),
                _isTogglingPunch
                    ? SizedBox(
                  width: 50,
                  height: 25,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isToggledIn ? themeProvider.primaryColor : themeProvider.secondaryTextColor,
                      ),
                    ),
                  ),
                )
                    : Switch(
                  activeColor: themeProvider.primaryColor,
                  inactiveTrackColor: themeProvider.textColor,
                  inactiveThumbColor: themeProvider.secondaryTextColor,
                  value: isToggledIn,
                  onChanged: _handleToggleChange,
                ),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeProvider.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userName != null)
                      Text(
                        'Welcome, $userName!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textColor,
                        ),
                      )
                    else
                      Text(
                        'Welcome, Loading...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textColor,
                        ),
                      ),
                    SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: showMessage ? 1.0 : 0.0,
                      duration: Duration(seconds: 1),
                      child: Text(
                        welcomeMessages[currentMessageIndex],
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDashboardGrid(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          backgroundColor: themeProvider.bottomNavBarColor,
          selectedItemColor: themeProvider.bottomBarSelectedColor,
          unselectedItemColor: themeProvider.bottomBarUnselectedColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Notification',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });

            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        AnimatedOpacity(
          opacity: tileVisibility[0] ? 1.0 : 0.0,
          duration: Duration(seconds: 1),
          child: _buildDashboardTile(
              context, 'Leave Form', Icons.edit,
                  (context) => const LeaveApplicationScreen()),
        ),
        AnimatedOpacity(
          opacity: tileVisibility[1] ? 1.0 : 0.0,
          duration: Duration(seconds: 1),
          child: _buildDashboardTile(
              context, 'Attendance', Icons.thumb_up,
                  (context) => attendenceView()),
        ),
        AnimatedOpacity(
          opacity: tileVisibility[2] ? 1.0 : 0.0,
          duration: Duration(seconds: 1),
          child: _buildDashboardTile(
              context, 'OD Form', Icons.description,
                  (context) => const OdApplicationScreen()),
        ),
        AnimatedOpacity(
          opacity: tileVisibility[3] ? 1.0 : 0.0,
          duration: Duration(seconds: 1),
          child: _buildDashboardTile(
              context, 'Expense', Icons.monetization_on_outlined,
                  (context) => ExpenseScreen()),
        ),
      ],
    );
  }

  Widget _buildDashboardTile(BuildContext context, String title, IconData icon,
      WidgetBuilder screenBuilder) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: screenBuilder),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeProvider.dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: themeProvider.primaryColor),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _fadeTimer?.cancel();
    _locationCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
