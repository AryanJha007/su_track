import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'package:su_track/services/profile/updateAadhaar.dart';

import '../providers/theme_provider.dart';
import '../widgets/loading_button.dart'; // Import the updateAadhaar service

class AadhaarPage extends StatefulWidget {
  const AadhaarPage({super.key});

  @override
  _AadhaarPageState createState() => _AadhaarPageState();
}

class _AadhaarPageState extends State<AadhaarPage> {
  final TextEditingController _aadharController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        appBar: AppBar(
          iconTheme: IconThemeData(color: themeProvider.iconColor),
          surfaceTintColor: Colors.transparent,
          backgroundColor: themeProvider.appBarColor,
          title: Text(
            'Aadhar Verification',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit your Aadhar details here',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: themeProvider.inputBorderColor),
                      ),
                      child: TextFormField(
                        controller: _aadharController,
                        cursorColor: themeProvider.primaryColor,
                        style: TextStyle(color: themeProvider.textColor),
                        keyboardType: TextInputType.number,
                        maxLength: 12, // Set the maximum length to 12 digits
                        decoration: InputDecoration(
                          hintText: 'Enter Aadhar Number',
                          hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                          prefixIcon: Icon(Icons.credit_card, color: themeProvider.primaryColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                          counterText: '', // Hide the default counter text if you want to style it yourself
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Aadhar number';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUpdating ? null : _handleSubmit,
                        style: themeProvider.primaryButtonStyle,
                        child: _isUpdating
                            ? Image.asset(
                          'assets/images/loading.gif',
                          height: 70,
                          width: double.infinity,
                          color: themeProvider.lionColor,
                        )
                            : Text(
                          'Submit',
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

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isUpdating = true;
      });

      try {
        await updateAadhaar(_aadharController.text, context);
        setState(() {
          constants.aadhar = _aadharController.text;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update Aadhaar: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
      }
    }
  }
}
