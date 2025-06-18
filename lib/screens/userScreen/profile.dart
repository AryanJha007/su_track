import 'package:flutter/material.dart';
import 'package:su_track/screens/dashBoard.dart';
import 'package:su_track/screens/navBar.dart';
import 'package:su_track/services/profile/getProfile.dart';
import 'package:su_track/services/profile/updateProfile.dart';
import '../../services/auth/loggedIn.dart';
import '../../widgets/loading_button.dart';
import 'notification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:su_track/util/constants.dart' as constants;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isEditMode = false;
  int _selectedIndex = 2;
  bool _isSaving = false;
  bool _isLoadingProfile = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobilePersonalController =
  TextEditingController();
  final TextEditingController _emailOfficialController =
  TextEditingController();
  final TextEditingController _mobileOfficialController =
  TextEditingController();
  final TextEditingController _panNoController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _adharNoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Update text styles to use theme colors
  TextStyle _getLabelStyle(ThemeProvider themeProvider) => TextStyle(
    color: themeProvider.secondaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  TextStyle _getValueStyle(ThemeProvider themeProvider) => TextStyle(
    color: themeProvider.textColor,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final data = await fetchProfile(context);
      if (data != null) {
        setState(() {
          profileData = data;
          _fullNameController.text = data['full_name'] ?? '';
          _mobilePersonalController.text = data['mobile_personal'] ?? '';
          _emailOfficialController.text = data['email_official'] ?? '';
          _mobileOfficialController.text = data['mobile_official'] ?? '';
          _panNoController.text = data['Pancard'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _adharNoController.text = data['adhar_no'] ?? '';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  void saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      try {
        List<String> nameParts = _fullNameController.text.split(' ');
        String fname = nameParts.isNotEmpty ? nameParts[0] : '';
        String mname = nameParts.length > 2 ? nameParts[1] : '';
        String lname = nameParts.length > 1 ? nameParts.last : '';
        final authData = await LoggedIn.getAuthData();
        Map<String, dynamic> updatedData = {
          "um_id": authData['um_Id'],
          "fname": fname,
          "mname": mname,
          "lname": lname,
          "username": profileData!['username'],
          "mobile_personal": _mobilePersonalController.text,
          "email_official": _emailOfficialController.text,
          "mobile_official": _mobileOfficialController.text,
          "pan_no": _panNoController.text,
          "dob": _dobController.text,
          "adhar_no": _adharNoController.text,
        };

        await updateProfile(updatedData, context);
        toggleEditMode();
      } catch (e) {
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: themeProvider.primaryColor,
              onPrimary: themeProvider.textColor,
              surface: themeProvider.backgroundColor,
              onSurface: themeProvider.textColor,
            ),
            dialogBackgroundColor: themeProvider.backgroundColor,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: themeProvider.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (profileData == null) {
          return Scaffold(
            backgroundColor: themeProvider.backgroundColor,
            appBar: AppBar(
              backgroundColor: themeProvider.backgroundColor,
              title: Text('Profile', style: TextStyle(color: themeProvider.textColor)),
              elevation: 0,
            ),
            body: Center(child: CircularProgressIndicator(color: themeProvider.primaryColor)),
            drawer: NavBar(),
          );
        }

        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeProvider.backgroundColor,
            elevation: 0,
            iconTheme: IconThemeData(color: themeProvider.iconColor),
            title: Text(
              'Profile',
              style: TextStyle(color: themeProvider.textColor, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(isEditMode ? Icons.check : Icons.edit),
                onPressed: isEditMode ? saveProfile : toggleEditMode,
                color: themeProvider.iconColor,
              ),
            ],
          ),
          body: _isLoadingProfile
              ? Center(child: CircularProgressIndicator(color: themeProvider.primaryColor))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: themeProvider.cardColor,
                                  child: Text(
                                    _getInitials(_fullNameController.text),
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Form Fields with your validation logic
                          profileField('Full Name', _fullNameController),
                          const SizedBox(height: 16),
                          profileField(
                              'Mobile Personal', _mobilePersonalController),
                          const SizedBox(height: 16),
                          profileField('Email Official', _emailOfficialController),
                          const SizedBox(height: 16),
                          profileField(
                              'Mobile Official', _mobileOfficialController),
                          const SizedBox(height: 16),
                          profileField('Pancard', _panNoController),
                          const SizedBox(height: 16),
                          profileField('DOB', _dobController, isDate: true),
                          const SizedBox(height: 16),
                          profileField('Adhar No', _adharNoController),

                          if (isEditMode) ...[
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: LoadingButton(
                                isLoading: _isSaving,
                                onPressed: saveProfile,
                                backgroundColor: themeProvider.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: themeProvider.buttonColor2,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
          drawer: NavBar(),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: themeProvider.bottomNavBarColor,
            selectedItemColor: themeProvider.bottomBarSelectedColor,
            unselectedItemColor: themeProvider.bottomBarUnselectedColor,
            currentIndex: _selectedIndex,
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
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage()),
                );
              }
            },
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isNotEmpty) {
      List<String> parts = name.split(' ');
      if (parts.length > 2) {
        return '${parts[0][0].toUpperCase()}${parts[2][0].toUpperCase()}';
      } else if (parts.length == 2) {
        return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
      } else if (parts.isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    return '';
  }

  Widget profileField(String fieldName, TextEditingController controller,
      {bool isDate = false}) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeProvider.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fieldName,
              style: _getLabelStyle(themeProvider),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: fieldName == 'Full Name'
                  ? Text(
                      controller.text,
                      style: _getValueStyle(themeProvider),
                    )
                  : isEditMode
                      ? isDate
                          ? GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: controller,
                                  style: _getValueStyle(themeProvider),
                                  cursorColor: themeProvider.primaryColor,
                                  decoration: InputDecoration(
                                    suffixIcon: Icon(Icons.calendar_today,
                                        color: themeProvider.secondaryTextColor),
                                    border: InputBorder.none,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter $fieldName';
                                    }
                                    if (fieldName == 'DOB' &&
                                        !RegExp(r'^\d{2}/\d{2}/\d{4}$')
                                            .hasMatch(value)) {
                                      return 'Enter a valid date in dd/MM/yyyy format';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            )
                          : TextFormField(
                              controller: controller,
                              cursorColor: themeProvider.primaryColor,
                              style: _getValueStyle(themeProvider),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter $fieldName';
                                }
                                switch (fieldName) {
                                  case 'Full Name':
                                    if (!RegExp(r'^[a-zA-Z\s]+$')
                                        .hasMatch(value)) {
                                      return 'Name must contain only letters and spaces';
                                    }
                                    break;
                                  case 'Mobile Personal':
                                  case 'Mobile Official':
                                    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                      return 'Mobile number must be 10 digits';
                                    }
                                    break;
                                  case 'Email Official':
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                        .hasMatch(value)) {
                                      return 'Enter a valid email address';
                                    }
                                    break;
                                  case 'Pancard':
                                    if (value.length != 10 ||
                                        !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                                            .hasMatch(value)) {
                                      return 'PAN must be 10 characters long and formatted';
                                    }
                                    break;
                                  case 'Adhar No':
                                    if (value.length != 12 ||
                                        !RegExp(r'^\d{12}$').hasMatch(value)) {
                                      return 'Aadhaar must be 12 digits long';
                                    }
                                    break;
                                }
                                return null;
                              },
                            )
                      : Text(
                          controller.text,
                          style: _getValueStyle(themeProvider),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    _fullNameController.dispose();
    _mobilePersonalController.dispose();
    _emailOfficialController.dispose();
    _mobileOfficialController.dispose();
    _panNoController.dispose();
    _dobController.dispose();
    _adharNoController.dispose();
    super.dispose();
  }
}
