import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/auth/loggedIn.dart';
import '../navBar.dart';
import 'leaveHistory.dart';
import 'package:su_track/services/leave/getLeaveTypes.dart';
import 'package:su_track/util/constants.dart' as constants;
import 'package:su_track/services/leave/applyLeave.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

class LeaveApplicationScreen extends StatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  _LeaveApplicationScreenState createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    LeaveFormPage(),
    LeaveHistoryPage(),
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
          backgroundColor: themeProvider.appBarColor,
          title: Text(
            'Leave Application',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: themeProvider.textColor),
          ),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: themeProvider.bottomNavBarColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: 'Apply Leave',
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
}

class LeaveFormPage extends StatefulWidget {
  @override
  _LeaveFormPageState createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends State<LeaveFormPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fromDate;
  DateTime? _toDate;
  int? _totalDays;
  int _halfDayType = 0; // 0: None, 1: Morning, 2: Afternoon
  bool _passRequired = false;
  List<Map<String, String>> leaveTypes = [];
  String? selectedLeaveTypeId;
  final TextEditingController _reasonController = TextEditingController();
  String? _medicalDocumentPath;
  bool _isSubmitting = false;
  bool _canApply = true;
  double _availableLeaves = 0;
  bool _hasEnoughLeaves = true;
  String _leaveValidationMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  Future<void> _loadLeaveTypes() async {
    try {
      final types = await fetchLeaveTypes(context);
      setState(() {
        leaveTypes = types;
      });
    } catch (e) {}
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
      if (_halfDayType != 0) {
        _totalDays = (_totalDays! - 0.5).toInt();
      }

      if (selectedLeaveTypeId != null && selectedLeaveTypeId != 'LWP' && selectedLeaveTypeId != '0') {
        final selectedType = leaveTypes
            .firstWhere((type) => type['leave_id'] == selectedLeaveTypeId);
        _hasEnoughLeaves = _totalDays! <= _availableLeaves;
        _leaveValidationMessage = _hasEnoughLeaves
            ? ''
            : 'You only have $_availableLeaves leaves available but requested $_totalDays days';
        _canApply = _hasEnoughLeaves && _availableLeaves > 0;
      } else {
        _hasEnoughLeaves = true;
        _leaveValidationMessage = '';
        _canApply = true;
      }
    } else {
      _totalDays = null;
    }
  }

  Future<void> _selectDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _medicalDocumentPath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An problem occurred while selecting document. Try again later')),
      );
    }
  }

  void _submitForm() async {
    if (_fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a "From" date')),
      );
      return;
    }

    if (_toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a "To" date')),
      );
      return;
    }

    if (selectedLeaveTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a leave type')),
      );
      return;
    }

    if (!_canApply) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('You do not have enough leaves to apply for this type')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      final authData = await LoggedIn.getAuthData();
      try {
        final appliedOnDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final fromDate = DateFormat('yyyy-MM-dd').format(_fromDate!);
        final toDate =
        _halfDayType != 0 ? fromDate : DateFormat('yyyy-MM-dd').format(_toDate!);
        final noOfDays = (_halfDayType != 0) ? 0.5.toString() : _totalDays.toString();
        final gatePass = _passRequired ? 'Y' : 'N';
        final leaveDuration = _halfDayType != 0 ? 'half-day' : 'full-day';
        String leaveId = selectedLeaveTypeId ?? 'LWP';
        if(authData['db']!=3) {
          if (selectedLeaveTypeId == '0') {
            leaveId = 'LWP';
          }
        }
        await applyLeave(
            leaveId: leaveId,
            appliedOnDate: appliedOnDate,
            fromDate: fromDate,
            toDate: toDate,
            noOfDays: noOfDays,
            gatePass: gatePass,
            leaveType: leaveId == 'LWP' ? 'LWP' : selectedLeaveTypeId ?? '',
            reason: _reasonController.text,
            leaveDuration: leaveDuration,
            halfDayType: _halfDayType.toString(),
            context: context,
            medicalDocument: _medicalDocumentPath);
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Leave Types Cards
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: leaveTypes.length,
                    itemBuilder: (context, index) {
                      final type = leaveTypes[index];
                      final isLWP = type['leave_type'] == 'LWP';
                      final availableLeaves =
                          double.tryParse(type['leaves_allocated'] ?? '0') ?? 0;

                      return Container(
                        width: 100,
                        margin: EdgeInsets.only(right: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeProvider.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border:
                          Border.all(color: themeProvider.inputBorderColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              type['leave_type'] ?? '',
                              style: TextStyle(
                                color: themeProvider.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (!isLWP || type['leave_type']!="LWP")
                              Text(
                                '${availableLeaves <= 0 ? '0' : type['leaves_allocated']} days',
                                style: TextStyle(
                                  color: themeProvider.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Submit your leave application here',
                  style: TextStyle(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // First Row - Date Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _halfDayType == 0 ? 'From Date' : 'On Date',
                            style: TextStyle(
                              color: themeProvider.textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _selectDate(context, true),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                              decoration: BoxDecoration(
                                color: themeProvider.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: themeProvider.inputBorderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: themeProvider.secondaryTextColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _fromDate == null
                                        ? 'Select Date'
                                        : DateFormat('dd/MM/yyyy')
                                        .format(_fromDate!),
                                    style: TextStyle(
                                        color: themeProvider.textColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_halfDayType == 0) ...[
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
                                padding: EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: themeProvider.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: themeProvider.inputBorderColor),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: themeProvider.secondaryTextColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _toDate == null
                                          ? 'Select Date'
                                          : DateFormat('dd/MM/yyyy')
                                          .format(_toDate!),
                                      style: TextStyle(
                                          color: themeProvider.textColor),
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

                // Second Row - Half Day Toggles
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Half Day Options',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Half Day (Morning) Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Half Day Morning',
                          style: TextStyle(
                              color: themeProvider.textColor, fontSize: 14),
                        ),
                        value: _halfDayType == 1,
                        onChanged: selectedLeaveTypeId != null
                            ? (bool? value) {
                          final selectedType = leaveTypes.firstWhere(
                                  (type) =>
                              type['leave_id'] ==
                                  selectedLeaveTypeId);
                          final availableLeaves = double.tryParse(
                              selectedType['leaves_allocated'] ??
                                  '0') ??
                              0;

                          if (availableLeaves != 0.5 || value == true) {
                            setState(() {
                              _halfDayType = value == true ? 1 : 0;
                              _calculateTotalDays();
                              if (_halfDayType != 0 && _fromDate != null) {
                                _toDate = _fromDate;
                              }
                            });
                          }
                        }
                            : null,
                        activeColor: themeProvider.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Half Day (Afternoon) Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Half Day Afternoon',
                          style: TextStyle(
                              color: themeProvider.textColor, fontSize: 14),
                        ),
                        value: _halfDayType == 2,
                        onChanged: selectedLeaveTypeId != null
                            ? (bool? value) {
                          final selectedType = leaveTypes.firstWhere(
                                  (type) =>
                              type['leave_id'] ==
                                  selectedLeaveTypeId);
                          final availableLeaves = double.tryParse(
                              selectedType['leaves_allocated'] ??
                                  '0') ??
                              0;

                          if (availableLeaves != 0.5 || value == true) {
                            setState(() {
                              _halfDayType = value == true ? 2 : 0;
                              _calculateTotalDays();
                              if (_halfDayType != 0 && _fromDate != null) {
                                _toDate = _fromDate;
                              }
                            });
                          }
                        }
                            : null,
                        activeColor: themeProvider.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Leave Type Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leave Type',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: themeProvider.inputBorderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLeaveTypeId,
                          isExpanded: true,
                          dropdownColor: themeProvider.cardColor,
                          hint: Text('Leave Type',
                              style: TextStyle(
                                  color:
                                  themeProvider.secondaryTextColor)),
                          items: [
                            ...leaveTypes.map((type) {
                              final availableLeaves = double.tryParse(
                                  type['leaves_allocated'] ?? '0') ??
                                  0;
                              return DropdownMenuItem<String>(
                                value: type['leave_id'],
                                enabled: type['leave_type'] == 'LWP' ||
                                    availableLeaves > 0,
                                child: Text(
                                  type['leave_type'] ?? '',
                                  style: TextStyle(
                                    color: (type['leave_type'] == 'LWP' ||
                                        availableLeaves > 0)
                                        ? themeProvider.textColor
                                        : themeProvider
                                        .secondaryTextColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              final selectedType = leaveTypes.firstWhere(
                                      (type) => type['leave_id'] == newValue);
                              final availableLeaves = double.tryParse(
                                  selectedType['leaves_allocated'] ??
                                      '0') ??
                                  0;

                              setState(() {
                                selectedLeaveTypeId = newValue;
                                _availableLeaves = availableLeaves;
                                // If available leaves is 0.5, force half day
                                if (availableLeaves == 0.5) {
                                  _halfDayType = 1;
                                }
                                // Disable full day option if only 0.5 leaves available
                                _canApply = availableLeaves > 0 ||
                                    selectedType['leave_type'] == 'LWP';
                                if (_totalDays != null &&
                                    selectedType['leave_type'] != 'LWP') {
                                  _hasEnoughLeaves =
                                  (_totalDays! <= availableLeaves);
                                  _leaveValidationMessage = _hasEnoughLeaves
                                      ? ''
                                      : 'You only have $_availableLeaves leaves available but requested $_totalDays days';
                                } else {
                                  _hasEnoughLeaves = true;
                                  _leaveValidationMessage = '';
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // After leave type selection and before reason field
                if (selectedLeaveTypeId != null &&
                    leaveTypes.firstWhere((type) =>
                    type['leave_id'] ==
                        selectedLeaveTypeId)['leave_type'] ==
                        'ML') ...[
                  const SizedBox(height: 24),
                  Text(
                    'Medical Document',
                    style: TextStyle(
                      color: themeProvider.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeProvider.inputBorderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: _selectDocument,
                              icon: Icon(Icons.attach_file,
                                  color: themeProvider.primaryColor),
                              label: Text(
                                'Upload Medical Document',
                                style: TextStyle(
                                    color: themeProvider.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        if (_medicalDocumentPath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Selected: ${_medicalDocumentPath!.split('/').last}',
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
                                      _medicalDocumentPath = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

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
                    hintStyle:
                    TextStyle(color: themeProvider.secondaryTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: themeProvider.inputBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: themeProvider.inputBorderColor),
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
                const SizedBox(height: 32),

                // Gate Pass Toggle
                Container(
                  padding: EdgeInsets.all(16),
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
                        value: _passRequired,
                        onChanged: (bool value) {
                          setState(() {
                            _passRequired = value;
                          });
                        },
                        activeColor: themeProvider.primaryColor,
                      ),
                    ],
                  ),
                ),
                if (_leaveValidationMessage.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeProvider.errorColor),
                    ),
                    child: Text(
                      _leaveValidationMessage,
                      style: TextStyle(
                        color: themeProvider.errorColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _canApply ? _submitForm : null,
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
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
