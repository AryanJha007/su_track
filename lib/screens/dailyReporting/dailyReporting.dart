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
    final TextEditingController _remarkController = TextEditingController();
    final TextEditingController _KilometersController = TextEditingController();
    String? selectedVehicleId;
    List<Map<String, String>> vehicles = [];
    final TextEditingController _vehicleNoController = TextEditingController();

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
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          selectedFile = pickedFile;
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
              const SnackBar(content: Text('Please fill all the required fields')),
            );
            return;
          }

          await submitDailyReport(
            context: context,
            workTypeId: selectedWorkTypeId!,
            status: selectedStatusId!,
            remarks: _remarkController.text.isNotEmpty ? _remarkController.text : null,
            file: selectedFile,
            vehicleType: selectedVehicleId,
            vehicleNo: _vehicleNoController.text.isNotEmpty
                ? _vehicleNoController.text
                : null,
            kilometers: _KilometersController.text.isNotEmpty
                ? _KilometersController.text
                : null,
            onSuccess: (message) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
            },
            onError: (message) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
      final theme = Provider.of<ThemeProvider>(context);
      DateTime now = DateTime.now();
      String formattedDate = '${now.toLocal()}'.split(' ')[0];
      String formattedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submit your daily report', style: TextStyle(color: theme.textColor, fontSize: 14)),
                const SizedBox(height: 32),

                // Date and Time
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: formattedDate,
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          labelText: 'Date',
                          labelStyle: TextStyle(color: theme.textColor),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.inputBorderColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        initialValue: formattedTime,
                        style: TextStyle(color: theme.textColor),
                        decoration: InputDecoration(
                          labelText: 'Time',
                          labelStyle: TextStyle(color: theme.textColor),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.inputBorderColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Work Type
                Text('Work Type', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.inputBorderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedWorkType,
                      isExpanded: true,
                      dropdownColor: theme.cardColor,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      items: workTypes.map((workType) => workType['work_type']).toSet().map((workType) {
                        return DropdownMenuItem(
                          value: workType,
                          child: Text(workType!, style: TextStyle(color: theme.textColor)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWorkType = value;
                          selectedWorkTypeId = workTypes.firstWhere((e) => e['work_type'] == value)['work_type_id'];
                          selectedStatusId = null;
                          selectedVehicleId = null;
                          _vehicleNoController.clear();
                          _loadStatuses(selectedWorkTypeId!);
                        });
                      },
                      hint: Text('Select Work Type', style: TextStyle(color: theme.textColor)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status
                if (selectedWorkTypeId != null) ...[
                  Text('Status', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.inputBorderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatusId,
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        items: statuses.map((status) {
                          return DropdownMenuItem(
                            value: status['status_id'],
                            child: Text(status['status_name']!, style: TextStyle(color: theme.textColor)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatusId = value;
                            if (value != '1') {
                              selectedVehicleId = null;
                              _vehicleNoController.clear();
                            }
                          });
                        },
                        hint: Text('Select Status', style: TextStyle(color: theme.secondaryTextColor)),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Vehicle Details (only if status == 1)
                if (selectedWorkTypeId == '1' && selectedStatusId == '1') ...[
                  const SizedBox(height: 24),
                  Text('Vehicle', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.inputBorderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedVehicleId,
                        isExpanded: true,
                        dropdownColor: theme.cardColor,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        items: vehicles.map((vehicle) {
                          return DropdownMenuItem(
                            value: vehicle['vehicle_type_id'],
                            child: Text(vehicle['vehicle_type']!, style: TextStyle(color: theme.textColor)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedVehicleId = value;
                          });
                        },
                        hint: Text('Select Vehicle', style: TextStyle(color: theme.secondaryTextColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Vehicle Number', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _vehicleNoController,
                    style: TextStyle(color: theme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Enter vehicle number',
                      hintStyle: theme.inputDecorationTheme.hintStyle,
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                      border: theme.inputDecorationTheme.border,
                      enabledBorder: theme.inputDecorationTheme.enabledBorder,
                      focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vehicle number is required';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Kilometers
                if (selectedWorkTypeId == '1')...[
                Text('Kilometers', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _KilometersController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: theme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter Kilometers',
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter Kilometers';
                    if (double.tryParse(value) == null) return 'Please enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],
                // Remarks
                Text('Remarks', style: TextStyle(color: theme.textColor, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _remarkController,
                  style: TextStyle(color: theme.textColor),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter remarks',
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter remarks' : null,
                ),

                const SizedBox(height: 24),

                // Optional Speedometer Upload
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Upload Speedometer',
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickFile,
                        icon: Icon(Icons.speed, color: theme.primaryColor,size: 22,),
                        label: Text('Click Here', style: TextStyle(color: theme.primaryColor)),
                      ),
                      if (selectedFile != null)
                        IconButton(
                          icon: Icon(Icons.close, color: theme.errorColor),
                          onPressed: _removeFile,
                          constraints: BoxConstraints(), // optional: reduce icon padding
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: theme.primaryButtonStyle,
                    child: _isSubmitting
                        ? CircularProgressIndicator(color: theme.lionColor)
                        : Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
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
      _remarkController.dispose();
      _KilometersController.dispose();
      _vehicleNoController.dispose();
      super.dispose();
    }
  }