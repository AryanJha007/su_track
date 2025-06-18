import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';
import 'package:su_track/services/dailyReporting/getWorkTypes.dart';
import 'package:su_track/services/dailyReporting/getStatuses.dart';
import 'package:su_track/services/dailyReporting/addDailyReport.dart';
import '../../services/dailyReporting/getVehicleTypes.dart';
import '../navBar.dart';
import 'dailyReportingView.dart';
import 'package:image_picker/image_picker.dart';

class DailyReportingScreen extends StatefulWidget {
  const DailyReportingScreen({super.key});

  @override
  _DailyReportingScreenState createState() => _DailyReportingScreenState();
}

class _DailyReportingScreenState extends State<DailyReportingScreen> {
  int _selectedIndex = 0;
  bool _isSubmitting = false;

  final List<Widget> _pages = [
    DailyReportingForm(),
    DailyReportingView(),
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
          backgroundColor: themeProvider.backgroundColor,
          title: Text(
            'Daily Reporting',
            style: TextStyle(
                color: themeProvider.textColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: themeProvider.bottomNavBarColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.remove_red_eye),
              label: 'View',
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

class DailyReportingForm extends StatefulWidget {
  @override
  _DailyReportingFormState createState() => _DailyReportingFormState();
}

class _DailyReportingFormState extends State<DailyReportingForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  XFile? selectedFile;
  String? selectedWorkType;
  String? selectedWorkTypeId;
  String? selectedStatusId;
  List<Map<String, String>> workTypes = [];
  List<Map<String, String>> statuses = [];
  // PlatformFile? selectedFile;
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _KilometersController = TextEditingController();
  String? selectedVehicleId;
  List<Map<String, String>> vehicles = [];
  final TextEditingController _vehicleNoController = TextEditingController();
  static final _inputDecoration = InputDecoration(
    filled: true,
    fillColor: const Color(0xFF2C2C2E),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Colors.blue),
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadWorkTypes();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicleList = await fetchVehicleTypes(context);
      setState(() {
        vehicles = vehicleList;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load vehicle types')),
      );
    }
  }

  Future<void> _loadWorkTypes() async {
    try {
      final types = await fetchWorkTypes(context);
      setState(() {
        workTypes = types;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load work types')),
      );
    }
  }

  Future<void> _loadStatuses(String workTypeId) async {
    try {
      final statusList = await fetchStatuses(workTypeId, context);
      setState(() {
        statuses = statusList;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load statuses')),
      );
    }
  }

  Future<void> _pickFile() async {
    final ImagePicker _picker = ImagePicker();

    // Pick an image using the camera only (no gallery access)
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      // Camera only, so no gallery access
    );

    if (pickedFile != null) {
      setState(() {
        selectedFile = pickedFile; // Store the captured image
      });
    }
  }

  void _removeFile() {
    setState(() {
      selectedFile = null;
    });
  }

  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        if (selectedWorkTypeId == null || selectedStatusId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please fill all the required fields')),
          );
          return;
        }
        if (selectedFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
              'Image is required! Please upload an image.',
              style: TextStyle(color: Colors.red),
            )),
          );
          return;
        }
        await submitDailyReport(
          context: context,
          workTypeId: selectedWorkTypeId!,
          status: selectedStatusId!,
          remarks:
              _remarkController.text.isNotEmpty ? _remarkController.text : null,
          file: selectedFile,
          vehicleType: selectedVehicleId,
          vehicleNo: _vehicleNoController.text.isNotEmpty
              ? _vehicleNoController.text
              : null,
          kilometers: _KilometersController.text.isNotEmpty
              ? _KilometersController.text
              : null,
          onSuccess: (message) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          },
          onError: (message) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          },
        );
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
    DateTime now = DateTime.now();
    String formattedDate = '${now.toLocal()}'.split(' ')[0];
    String formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit your daily report',
                    style:
                        TextStyle(color: themeProvider.textColor, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Current Date and Time (Read-only)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          initialValue: formattedDate,
                          style: TextStyle(color: themeProvider.textColor),
                          decoration: InputDecoration(
                            labelText: 'Date',
                            labelStyle:
                                TextStyle(color: themeProvider.textColor),
                            filled: true,
                            fillColor: themeProvider.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: themeProvider.inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: themeProvider.inputBorderColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          initialValue: formattedTime,
                          style: TextStyle(color: themeProvider.textColor),
                          decoration: InputDecoration(
                            labelText: 'Time',
                            labelStyle:
                                TextStyle(color: themeProvider.textColor),
                            filled: true,
                            fillColor: themeProvider.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: themeProvider.inputBorderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: themeProvider.inputBorderColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Work Type Selection
                  Text(
                    'Work Type',
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedWorkType,
                        isExpanded: true,
                        dropdownColor: themeProvider.cardColor,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        items: workTypes
                            .map((workType) => workType['work_type'])
                            .toSet()
                            .map((workType) {
                          return DropdownMenuItem(
                            value: workType,
                            child: Text(
                              workType!,
                              style: TextStyle(color: themeProvider.textColor),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedWorkType = value;
                            selectedWorkTypeId = workTypes.firstWhere(
                                (workType) =>
                                    workType['work_type'] ==
                                    value)['work_type_id'];
                            selectedStatusId = null;
                            _loadStatuses(selectedWorkTypeId!);
                          });
                        },
                        hint: Text('Select Work Type',
                            style: TextStyle(color: themeProvider.textColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Selection
                  if (selectedWorkType != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Status',
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
                        border:
                            Border.all(color: themeProvider.inputBorderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatusId,
                          isExpanded: true,
                          dropdownColor: themeProvider.cardColor,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          items: statuses.map((status) {
                            return DropdownMenuItem(
                              value: status['status_id'],
                              child: Text(
                                status['status_name']!,
                                style:
                                    TextStyle(color: themeProvider.textColor),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStatusId = value;
                            });
                          },
                          hint: Text(
                            'Select Status',
                            style: TextStyle(
                                color: themeProvider.secondaryTextColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (selectedWorkTypeId == '1' &&
                      (selectedStatusId == '1' || selectedStatusId == '6')) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Vehicle',
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
                        border:
                            Border.all(color: themeProvider.inputBorderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedVehicleId,
                          isExpanded: true,
                          dropdownColor: themeProvider.cardColor,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          items: vehicles.map((vehicle) {
                            return DropdownMenuItem(
                              value: vehicle['vehicle_type_id'],
                              child: Text(
                                vehicle['vehicle_type']!,
                                style:
                                    TextStyle(color: themeProvider.textColor),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedVehicleId = value;
                            });
                          },
                          hint: Text(
                            'Select Vehicle',
                            style: TextStyle(
                                color: themeProvider.secondaryTextColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (selectedVehicleId != null)
                  const SizedBox(height: 24),
                  if (selectedVehicleId != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Vehicle Number',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _vehicleNoController,
                      style: TextStyle(color: themeProvider.textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter vehicle number',
                        hintStyle: themeProvider.inputDecorationTheme.hintStyle,
                        filled: true,
                        fillColor: themeProvider.inputDecorationTheme.fillColor,
                        border: themeProvider.inputDecorationTheme.border,
                        enabledBorder:
                            themeProvider.inputDecorationTheme.enabledBorder,
                        focusedBorder:
                            themeProvider.inputDecorationTheme.focusedBorder,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vehicle number is required';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (selectedWorkTypeId == '1' && selectedStatusId != null)
                    const SizedBox(height: 24),
                  if (selectedWorkTypeId == '1' && selectedStatusId != null)
                    Text(
                      'Kilometers',
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (selectedWorkTypeId == '1' && selectedStatusId != null) const SizedBox(height: 8),
                  if (selectedWorkTypeId == '1' && selectedStatusId != null)
                    TextFormField(
                      controller: _KilometersController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ], // only allow digits
                      cursorColor: themeProvider.cursorColor,
                      style: TextStyle(color: themeProvider.textColor),
                      maxLines: 1, // only 1 line for compact height
                      decoration: InputDecoration(
                        filled: themeProvider.inputDecorationTheme.filled,
                        fillColor: themeProvider.inputDecorationTheme.fillColor,
                        border: themeProvider.inputDecorationTheme.border,
                        enabledBorder:
                            themeProvider.inputDecorationTheme.enabledBorder,
                        focusedBorder:
                            themeProvider.inputDecorationTheme.focusedBorder,
                        labelStyle:
                            themeProvider.inputDecorationTheme.labelStyle,
                        hintStyle: themeProvider.inputDecorationTheme.hintStyle,
                        hintText: 'Enter Kilometers',
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16), // reduce field height
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter Kilometers';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  if (selectedWorkTypeId == '1' && selectedStatusId != null)
                  const SizedBox(height: 24),
                  // Remarks
                  if (selectedStatusId != null)
                    Text(
                      'Remarks',
                      style: TextStyle(
                        color: themeProvider.secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (selectedStatusId != null) const SizedBox(height: 8),
                  if (selectedStatusId != null)
                    TextFormField(
                      cursorColor: themeProvider.cursorColor,
                      controller: _remarkController,
                      style: TextStyle(color: themeProvider.textColor),
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: themeProvider.inputDecorationTheme.filled,
                        fillColor: themeProvider.inputDecorationTheme.fillColor,
                        border: themeProvider.inputDecorationTheme.border,
                        enabledBorder:
                            themeProvider.inputDecorationTheme.enabledBorder,
                        focusedBorder:
                            themeProvider.inputDecorationTheme.focusedBorder,
                        labelStyle:
                            themeProvider.inputDecorationTheme.labelStyle,
                        hintStyle: themeProvider.inputDecorationTheme.hintStyle,
                        hintText: 'Enter remarks',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter remarks';
                        }
                        return null;
                      },
                    ),
                  if (selectedStatusId != null) const SizedBox(height: 32),

                  // Document Upload
                  if (selectedStatusId != null)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: themeProvider.dividerColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upload Speedometer',
                            style: TextStyle(
                              color: themeProvider.textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickFile,
                            icon: Icon(Icons.speed_sharp,
                                color: themeProvider.primaryColor,size: 28,),
                            label: Text(
                              'Click Here',
                              style:
                                  TextStyle(color: themeProvider.primaryColor),
                            ),
                          ),
                          if (selectedFile != null)
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedFile!.name,
                                      style: TextStyle(
                                          color:
                                              themeProvider.secondaryTextColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close,
                                        color: themeProvider.errorColor),
                                    onPressed: _removeFile,
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (selectedStatusId != null) const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
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
    _remarkController.dispose();
    super.dispose();
  }
}
