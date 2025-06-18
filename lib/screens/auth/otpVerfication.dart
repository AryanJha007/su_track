import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:su_track/services/auth/verifyOtp.dart';
import 'package:su_track/util/constants.dart' as constants;
import '../../providers/theme_provider.dart';
import '../../services/auth/getUniversalId.dart';
import '../../services/geolocation/updateGeolocation.dart';
import '../../widgets/loading_button.dart';
import '../aadhaar.dart';
import '../dashBoard.dart';
import 'otp.dart';

class OTPVerificationCodeScreen extends StatefulWidget {
  OTPVerificationCodeScreen({super.key});

  @override
  State<OTPVerificationCodeScreen> createState() => _OTPVerificationCodeScreenState();
}

class _OTPVerificationCodeScreenState extends State<OTPVerificationCodeScreen> {
  final TextEditingController otpController1 = TextEditingController();
  final TextEditingController otpController2 = TextEditingController();
  final TextEditingController otpController3 = TextEditingController();
  final TextEditingController otpController4 = TextEditingController();
  final TextEditingController otpController5 = TextEditingController();
  final TextEditingController otpController6 = TextEditingController();

  // Add state variable
  bool _isVerifying = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: themeProvider.primaryColor,
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter verification code',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'We have sent you a 6-digit verification code',
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Form(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildOTPTextField(otpController1, true, themeProvider),
                          _buildOTPTextField(otpController2, false, themeProvider),
                          _buildOTPTextField(otpController3, false, themeProvider),
                          _buildOTPTextField(otpController4, false, themeProvider),
                          _buildOTPTextField(otpController5, false, themeProvider),
                          _buildOTPTextField(otpController6, false, themeProvider),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: LoadingButton(
                        isLoading: _isVerifying,
                        onPressed: _handleVerify,
                        backgroundColor: themeProvider.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Verify',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOTPTextField(TextEditingController controller, bool autoFocus, ThemeProvider themeProvider) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeProvider.dividerColor),
      ),
      child: TextField(
        controller: controller,
        autofocus: autoFocus,
        cursorColor: themeProvider.cursorColor,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: themeProvider.textColor,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Center the text vertically
        ),
        onChanged: (value) {
          if (value.length == 1) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  // Update the onPressed method
  void _handleVerify() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      String otp = otpController1.text + otpController2.text +
          otpController3.text + otpController4.text +
          otpController5.text + otpController6.text;
      if (await verifyOtp(otp, context)) {
        if (constants.aadhar != null) {
          getUniversalId(constants.um_id, constants.aadhar!);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AadhaarPage()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OTPVerificationCodeScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }
}
