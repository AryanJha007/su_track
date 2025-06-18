import 'dart:async';
import 'dart:io';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:su_track/screens/auth/login.dart';
import 'package:su_track/screens/dashBoard.dart';
import 'package:su_track/services/auth/loggedIn.dart';
import 'package:su_track/services/backgroundService.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

@pragma('vm:entry-point')
Future<bool> onBackgroundServiceStart(ServiceInstance service) async {
  await Future.delayed(Duration(seconds: 600));
  Timer.periodic(Duration(seconds: 600), (timer) {
    Backgroundservice().getCurrentLocationNowCustom();
  });

  return true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OneSignal.initialize("0841534d-f0cc-4231-8604-e0df77e4069c");
  OneSignal.Notifications.requestPermission(true);

  await requestLocationPermission();
  final isLoggedIn = await LoggedIn.isLoggedIn();

  if (isLoggedIn) {
    final authData = await LoggedIn.getAuthData();
    constants.device_token = authData['token'];
    constants.um_id = authData['um_Id'];
    constants.aadhar = authData['aadhar'];
    constants.punch_status = authData['punch_status'] ?? '0';

    if (await LoggedIn.isPunchedIn()) {
      await LocationServiceManager.startLocationService();
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

Future<void> requestLocationPermission() async {
  PermissionStatus locationPermission = await Permission.location.request();
  if (locationPermission != PermissionStatus.granted) {
    requestLocationPermission();
  }

  if (Platform.isAndroid) {
    PermissionStatus backgroundPermission = await Permission.locationAlways.request();
    if (backgroundPermission != PermissionStatus.granted) {
      requestLocationPermission();
    }
  }
}

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SplashScreen({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MyApp(isLoggedIn: widget.isLoggedIn),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: 'assets/images/loadingNew.gif',
      nextScreen: widget.isLoggedIn ? DashboardPage() : LoginPage(),
      backgroundColor: Color(0xFF2C2C2E),
      splashTransition: SplashTransition.scaleTransition,
      duration: 1200, // Duration for splash screen
    );
  }
}



class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'SU Track',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: themeProvider.backgroundColor,
            cardColor: themeProvider.cardColor,
            primaryColor: themeProvider.primaryColor,
            appBarTheme: AppBarTheme(
              backgroundColor: themeProvider.appBarColor,
              iconTheme: IconThemeData(color: themeProvider.iconColor),
              titleTextStyle: TextStyle(
                color: themeProvider.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: themeProvider.textColor),
              bodyMedium: TextStyle(color: themeProvider.textColor),
              titleMedium: TextStyle(color: themeProvider.textColor),
              labelLarge: TextStyle(color: themeProvider.textColor),
            ),
            iconTheme: IconThemeData(
              color: themeProvider.iconColor,
            ),
            inputDecorationTheme: themeProvider.inputDecorationTheme,
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: themeProvider.bottomNavBarColor,
              selectedItemColor: themeProvider.primaryColor,
              unselectedItemColor: themeProvider.secondaryTextColor,
            ),
            dividerColor: themeProvider.dividerColor,
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return themeProvider.switchActiveColor;
                }
                return themeProvider.switchInactiveColor;
              }),
              trackColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return themeProvider.switchActiveColor.withOpacity(0.5);
                }
                return themeProvider.switchInactiveColor.withOpacity(0.5);
              }),
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            MonthYearPickerLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: SplashScreen(isLoggedIn: isLoggedIn),
        );
      },
    );
  }
}
