import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';
import 'package:su_track/screens/od/odHistory.dart';
import '../../services/auth/loggedIn.dart';
import '../../services/od/applyOd.dart';
import '../../services/od/getStatesAndCities.dart';
import '../navBar.dart';

class OdApplicationScreen extends StatefulWidget {
  const OdApplicationScreen({super.key});

  @override
  _OdApplicationScreenState createState() => _OdApplicationScreenState();
}

class _OdApplicationScreenState extends State<OdApplicationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ODFormPage(),
    ODHistoryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        drawer: NavBar(),
        backgroundColor: themeProvider.backgroundColor,
        appBar: AppBar(
          iconTheme: IconThemeData(color: themeProvider.iconColor),
          surfaceTintColor: Colors.transparent,
          title: Text(
            'OD Application',
            style: TextStyle(color: themeProvider.textColor),
          ),
          backgroundColor: themeProvider.appBarColor,
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: themeProvider.bottomNavBarColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: 'Apply OD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: themeProvider.bottomBarSelectedColor,
          unselectedItemColor: themeProvider.bottomBarUnselectedColor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ODFormPage extends StatefulWidget {
  const ODFormPage({super.key});

  @override
  _ODFormPageState createState() => _ODFormPageState();
}

class _ODFormPageState extends State<ODFormPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _odDocumentPath;
  final TextEditingController _departureTimeController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  final TextEditingController _odLocationController = TextEditingController();
  final TextEditingController _odContactNoController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _noOfHoursController = TextEditingController();
  bool _gatePass = false;
  bool _isHours = false; // Toggle between Full Day and Hours
  final timeFormat = DateFormat("HH:mm"); // Assuming input format is "HH:mm"
  List<Map<String, String>> _states = [];
  List<Map<String, String>> _cities = [];
  String? _selectedState;
  String? _selectedCity;
  int? _totalDays;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    try {
      final states = await fetchStates();
      setState(() {
        _states = states;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadCities(String stateId) async {
    try {
      final cities = await fetchCities(stateId);
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _selectDate(BuildContext context, bool isFromDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: themeProvider.primaryColor,
                onPrimary: Colors.white,
                surface: themeProvider.cardColor,
                onSurface: themeProvider.textColor,
                background: themeProvider.backgroundColor,
              ),
              dialogBackgroundColor: themeProvider.cardColor,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: themeProvider.primaryColor,
                ),
              ),
            ),
            child: child ?? Container(),
          ),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = pickedDate;
        }
        if (_isHours) {
          _toDate = _fromDate;
        } else {
          _toDate = pickedDate;
        }
        _calculateTotalDays();
      });
    }
  }

  void _calculateTotalDays() {
    if (_fromDate != null && _toDate != null) {
      _totalDays = _toDate!.difference(_fromDate!).inDays + 1;
    } else {
      _totalDays = null;
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: themeProvider.primaryColor,
                onPrimary: Colors.white,
                surface: themeProvider.cardColor,
                onSurface: themeProvider.textColor,
                background: themeProvider.backgroundColor,
              ),
              dialogBackgroundColor: themeProvider.cardColor,
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: themeProvider.primaryColor,
                ),
              ),
            ),
            child: child ?? Container(),
          ),
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        // Format time as HH:mm
        final hour = pickedTime.hour.toString().padLeft(2, '0');
        final minute = pickedTime.minute.toString().padLeft(2, '0');
        controller.text = '$hour:$minute';

        if (_departureTimeController.text.isNotEmpty && _arrivalTimeController.text.isNotEmpty) {
          _calculateTotalHours();
        }
      });
    }
  }

  void _calculateTotalHours() {
    if (_departureTimeController.text.isNotEmpty && _arrivalTimeController.text.isNotEmpty) {
      try {
        final departureTime = _departureTimeController.text.split(':');
        final arrivalTime = _arrivalTimeController.text.split(':');
        final departureHour = int.parse(departureTime[0]);
        final departureMinute = int.parse(departureTime[1]);
        final arrivalHour = int.parse(arrivalTime[0]);
        final arrivalMinute = int.parse(arrivalTime[1]);
        final departureTotalMinutes = departureHour * 60 + departureMinute;
        final arrivalTotalMinutes = arrivalHour * 60 + arrivalMinute;

        final totalMinutes = (arrivalTotalMinutes >= departureTotalMinutes)
            ? arrivalTotalMinutes - departureTotalMinutes
            : (1440 - departureTotalMinutes) + arrivalTotalMinutes;
        final totalHours = totalMinutes / 60;
        _noOfHoursController.text = totalHours.toStringAsFixed(2);
      } catch (e) {
        _noOfHoursController.text = "Invalid Time";
      }
    }
  }

  Future<void> _selectDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _odDocumentPath = result.files.single.path;
      });
    }
  }

  void _submitForm() async {
    if (_isHours) {
      if (_departureTimeController.text == _arrivalTimeController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Departure and arrival times cannot be the same')),
        );
        return;
      }
    }
    final authData = await LoggedIn.getAuthData();
    if (_formKey.currentState!.validate()) {
      if (_odDocumentPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading a file is necessary')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final formData = {
          'um_id': authData['um_Id'],
          'username': authData['universal_Id'],
          'db': authData['db'],
          'applied_on_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'from_date': _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : '',
          'to_date': _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : '',
          'no_of_days': _isHours ? '0' : _totalDays.toString(),
          'gate_pass': _gatePass ? 'Y' : 'N',
          'reason': _reasonController.text,
          'od_duration': _isHours ? 'hrs' : 'full-day',
          'od_location': _odLocationController.text,
          'od_contact_no': _odContactNoController.text,
          'state': _selectedState,
          'city': _selectedCity,
        };

        if (_isHours) {
          formData['departure_time'] = _departureTimeController.text;
          formData['arrival_time'] = _arrivalTimeController.text;
          formData['no_of_hrs'] = _noOfHoursController.text;
        }

        await applyOd(formData, _odDocumentPath, context);
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit your OD application here',
                    style: TextStyle(color: themeProvider.textColor, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Date Selection Row with proper alignment
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From Date',
                              style: TextStyle(
                                color: themeProvider.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // From Date picker with consistent styling
                            GestureDetector(
                              onTap: () => _selectDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: themeProvider.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: themeProvider.inputBorderColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: themeProvider.textColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _fromDate == null
                                          ? 'Select Date'
                                          : DateFormat('dd/MM/yyyy').format(_fromDate!),
                                      style: TextStyle(
                                        color: themeProvider.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isHours) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To Date',
                                style: TextStyle(
                                  color: themeProvider.textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectDate(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: themeProvider.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: themeProvider.inputBorderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: themeProvider.textColor, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _toDate == null
                                            ? 'Select Date'
                                            : DateFormat('dd/MM/yyyy').format(_toDate!),
                                        style: TextStyle(color: themeProvider.textColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Hours Toggle with consistent styling
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeProvider.inputBorderColor),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Hours',
                        style: TextStyle(color: themeProvider.textColor, fontSize: 14),
                      ),
                      value: _isHours,
                      onChanged: (bool value) {
                        setState(() {
                          _isHours = value;
                          if (_isHours) {
                            _toDate = _fromDate;
                          }
                        });
                      },
                      activeColor: themeProvider.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time Selection Fields (Only shown when Hours is selected)
                  if (_isHours) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Departure Time',
                                style: TextStyle(
                                  color: themeProvider.textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectTime(context, _departureTimeController),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: themeProvider.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: themeProvider.inputBorderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: themeProvider.textColor, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _departureTimeController.text.isEmpty
                                            ? 'Select Time'
                                            : _departureTimeController.text,
                                        style: TextStyle(color: themeProvider.textColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Arrival Time',
                                style: TextStyle(
                                  color: themeProvider.textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _selectTime(context, _arrivalTimeController),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: themeProvider.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: themeProvider.inputBorderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: themeProvider.textColor, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _arrivalTimeController.text.isEmpty
                                            ? 'Select Time'
                                            : _arrivalTimeController.text,
                                        style: TextStyle(color: themeProvider.textColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Number of Hours field
                    Text(
                      'Number of Hours',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: themeProvider.inputBorderColor),
                      ),
                      child: TextFormField(
                        controller: _noOfHoursController,
                        cursorColor: themeProvider.primaryColor,
                        enabled: false,
                        style: TextStyle(color: themeProvider.textColor),
                        decoration: InputDecoration(
                          hintText: 'Calculated Hours',
                          hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // State and City Dropdowns Row
                  Row(
                    children: [
                      // State Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('State', style: TextStyle(color: themeProvider.textColor, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: themeProvider.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: themeProvider.inputBorderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedState,
                                  isExpanded: true,
                                  dropdownColor: themeProvider.cardColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  items: _states.map((state) {
                                    return DropdownMenuItem<String>(
                                      value: state['state_id'],
                                      child: Text(
                                        state['state_name'] ?? '',
                                        style: TextStyle(color: themeProvider.textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedState = newValue;
                                      _selectedCity = null;
                                      _cities = [];
                                      if (newValue != null) {
                                        _loadCities(newValue);
                                      }
                                    });
                                  },
                                  hint: Text('Select State', style: TextStyle(color: themeProvider.secondaryTextColor)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('City', style: TextStyle(color: themeProvider.textColor, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: themeProvider.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: themeProvider.inputBorderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCity,
                                  isExpanded: true,
                                  dropdownColor: themeProvider.cardColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  items: _cities.map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city['city_id'],
                                      child: Text(
                                        city['city_name'] ?? '',
                                        style: TextStyle(color: themeProvider.textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCity = newValue;
                                    });
                                  },
                                  hint: Text('Select City', style: TextStyle(color: themeProvider.secondaryTextColor)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // OD Location field moved here
                  Text(
                    'OD Location',
                    style: TextStyle(
                      color: themeProvider.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _odLocationController,
                    cursorColor: themeProvider.primaryColor,
                    style: TextStyle(color: themeProvider.textColor),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: themeProvider.inputFillColor,
                      hintText: 'Enter OD Location',
                      hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.inputBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.primaryColor),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter OD location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Contact Number field with exact 10 digit validation
                  Text(
                    'Contact Number',
                    style: TextStyle(
                      color: themeProvider.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _odContactNoController,
                    cursorColor: themeProvider.primaryColor,
                    style: TextStyle(color: themeProvider.textColor),
                    keyboardType: TextInputType.phone,
                    maxLength: 10, // Limit input to 10 characters
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: themeProvider.inputFillColor,
                      hintText: 'Enter Contact Number',
                      hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                      counterText: '', // Hide the character counter
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.inputBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.primaryColor),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter contact number';
                      }
                      if (value.length != 10) {
                        return 'Contact number must be exactly 10 digits';
                      }
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Please enter valid 10 digit number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Reason TextField
                  Text(
                    'Reason',
                    style: TextStyle(
                      color: themeProvider.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    cursorColor: themeProvider.primaryColor,
                    style: TextStyle(color: themeProvider.textColor),
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: themeProvider.inputFillColor,
                      hintText: 'Enter your reason',
                      hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.inputBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: themeProvider.primaryColor),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a reason';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Gate Pass Switch
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeProvider.inputBorderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gate Pass Required',
                          style: TextStyle(
                            color: themeProvider.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: _gatePass,
                          onChanged: (bool value) {
                            setState(() {
                              _gatePass = value;
                            });
                          },
                          activeColor: themeProvider.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Document Upload with clear button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeProvider.inputBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'OD Document',
                              style: TextStyle(
                                color: themeProvider.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _selectDocument,
                              icon: Icon(Icons.upload_file, color: themeProvider.primaryColor),
                              label: Text(
                                'Upload File',
                                style: TextStyle(color: themeProvider.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        if (_odDocumentPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Selected: ${_odDocumentPath!.split('/').last}',
                                    style: TextStyle(
                                      color: themeProvider.secondaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: themeProvider.errorColor,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _odDocumentPath = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: themeProvider.primaryButtonStyle,
                      child: _isSubmitting
                          ? Center(
                        child: Image.asset(
                          'assets/images/loading.gif', // Replace with your GIF
                          height: 70,
                          width: double.infinity,
                          color: themeProvider.lionColor,
                        ),
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
    );
  }

  @override
  void dispose() {
    // Dispose controllers
    _departureTimeController.dispose();
    _arrivalTimeController.dispose();
    _odLocationController.dispose();
    _odContactNoController.dispose();
    _reasonController.dispose();
    _noOfHoursController.dispose();
    super.dispose();
  }
}
