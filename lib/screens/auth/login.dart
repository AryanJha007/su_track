import 'package:flutter/material.dart';
import 'package:su_track/services/auth/login.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'otpVerfication.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      // If form validation fails, return early
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final username = _usernameController.text;
      final password = _passwordController.text;
      bool isLoggedIn = await login(username, password, context);

      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OTPVerificationCodeScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        appBar: AppBar(
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
            ]),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                AnimatedOpacity(
                  opacity: themeProvider.isDarkMode ? 1.0 : 0.8,
                  duration: Duration(milliseconds: 500),
                  child: Image.asset(
                    themeProvider.isDarkMode
                        ? 'assets/images/lion.png'
                        : 'assets/images/lion_light.png',
                    height: 120,
                    width: 120,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: themeProvider.primaryColor.withOpacity(0.6),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  themeProvider.primaryColor.withOpacity(0.3),
                              blurRadius: 12.0,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          cursorColor: themeProvider.cursorColor,
                          style: TextStyle(color: themeProvider.textColor),
                          decoration: InputDecoration(
                            hintText: 'Enter Username',
                            hintStyle: TextStyle(
                                color: themeProvider.secondaryTextColor),
                            prefixIcon: Icon(Icons.person,
                                color: themeProvider.primaryColor),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter user name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  themeProvider.primaryColor.withOpacity(0.3),
                              blurRadius: 12.0,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          style: TextStyle(color: themeProvider.textColor),
                          cursorColor: themeProvider.cursorColor,
                          decoration: InputDecoration(
                            hintText: 'Enter Password',
                            hintStyle: TextStyle(
                                color: themeProvider.secondaryTextColor),
                            prefixIcon: Icon(Icons.lock,
                                color: themeProvider.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: themeProvider.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _isLoggingIn
                            ? Center(
                                child: Image.asset(
                                  'assets/images/loading.gif', // Replace with your GIF
                                  height: 70,
                                  width: double.infinity,
                                  color: themeProvider.lionColor,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeProvider.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Login →',
                                  style: TextStyle(
                                    color: themeProvider.buttonColor2,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
