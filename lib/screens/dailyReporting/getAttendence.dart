import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:su_track/services/dailyReporting/getAttendance.dart';
import 'package:su_track/util/constants.dart' as constants;
import '../../widgets/loading_button.dart';
import '../navBar.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

// ✅ Excel-related packages with alias
import 'package:excel/excel.dart' as xls;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

import 'dart:io';

class attendenceView extends StatefulWidget {
  const attendenceView({super.key});

  @override
  _attendenceViewState createState() => _attendenceViewState();
}

class _attendenceViewState extends State<attendenceView> {
  DateTime? selectedMonth;
  List<Map<String, dynamic>> _attendanceDetails = [];
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSubmitting = false;

  static const _tableHeaderStyle = TextStyle(fontWeight: FontWeight.bold);
  static const _tableCellStyle = TextStyle();

  void _getAttendance() async {
    if (selectedMonth == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSubmitting = true;
    });

    try {
      final yearMonth =
          '${selectedMonth!.year}-${selectedMonth!.month.toString().padLeft(2, '0')}';
      final data =
      await fetchAttendance(constants.um_id, yearMonth, context);
      _processAttendanceData(data);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load attendance data';
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      selectedMonth = null;
      _attendanceDetails = [];
    });
  }

  String capitalize(String word) {
    if (word.isEmpty) return '----------';
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  void _processAttendanceData(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _attendanceDetails =
      List<Map<String, dynamic>>.from(data['attendance_details']);
      _isLoading = false;
    });
  }

  Future<void> _exportToExcel() async {
    final hasDistance = _attendanceDetails.any(
            (e) => e['distance'] != null && e['distance'].toString() != '0');
    final hasCost = _attendanceDetails.any(
            (e) => e['calculated_cost'] != null && e['calculated_cost'].toString() != '0');

    var excel = xls.Excel.createExcel();
    xls.Sheet sheet = excel['Attendance'];

    List<String> headers = ['Date', 'In Time', 'Out Time', 'Status', 'Remark'];
    if (hasDistance) headers.add('Distance (KM)');
    if (hasCost) headers.add('Cost');

    sheet.appendRow(headers);

    for (var row in _attendanceDetails) {
      List<dynamic> rowData = [
        row['date'],
        row['Intime'],
        row['Outtime'],
        capitalize(row['status']),
        capitalize(row['remark']),
      ];
      if (hasDistance) rowData.add(row['distance'] ?? 0);
      if (hasCost) rowData.add(row['calculated_cost'] ?? 0);
      sheet.appendRow(rowData);
    }

    // Permissions
    var storage = await Permission.storage.request();
    var manageStorage = await Permission.manageExternalStorage.request();

    if (!storage.isGranted && !manageStorage.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission denied')));
      return;
    }

    // Save to Downloads
    final dir = Directory('/storage/emulated/0/Download');
    final filePath = '${dir.path}/attendance_report.xlsx';
    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Excel exported to $filePath')));

    await OpenFile.open(filePath);
  }


  Widget _buildAttendanceTable(ThemeProvider themeProvider) {
    final showDistance = _attendanceDetails.any(
            (e) => e['distance'] != null && e['distance'].toString() != '0');
    final showCost = _attendanceDetails.any((e) =>
    e['calculated_cost'] != null && e['calculated_cost'].toString() != '0');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(themeProvider.cardColor),
        dataRowColor: MaterialStateProperty.all(themeProvider.inputFillColor),
        columns: [
          DataColumn(
              label: Text('Date',
                  style: _tableHeaderStyle.copyWith(
                      color: themeProvider.secondaryTextColor))),
          DataColumn(
              label: Text('In',
                  style: _tableHeaderStyle.copyWith(
                      color: themeProvider.secondaryTextColor))),
          DataColumn(
              label: Text('Out',
                  style: _tableHeaderStyle.copyWith(
                      color: themeProvider.secondaryTextColor))),
          DataColumn(
              label: Text('Status',
                  style: _tableHeaderStyle.copyWith(
                      color: themeProvider.secondaryTextColor))),
          DataColumn(
              label: Text('Remark',
                  style: _tableHeaderStyle.copyWith(
                      color: themeProvider.secondaryTextColor))),
          if (showDistance)
            DataColumn(
                label: Text('KM',
                    style: _tableHeaderStyle.copyWith(
                        color: themeProvider.secondaryTextColor))),
          if (showCost)
            DataColumn(
                label: Text('Cost',
                    style: _tableHeaderStyle.copyWith(
                        color: themeProvider.secondaryTextColor))),
        ],
        rows: _attendanceDetails.map((attendance) {
          final cells = <DataCell>[
            DataCell(Text(
              attendance['date'].toString().substring(8),
              style: _tableCellStyle.copyWith(color: themeProvider.textColor),
            )),
            DataCell(Text(
              attendance['Intime'],
              style: _tableCellStyle.copyWith(color: themeProvider.textColor),
            )),
            DataCell(Text(
              attendance['Outtime'],
              style: _tableCellStyle.copyWith(color: themeProvider.textColor),
            )),
            DataCell(Text(
              capitalize(attendance['status']),
              style: _tableCellStyle.copyWith(color: themeProvider.textColor),
            )),
            DataCell(Text(
              capitalize(attendance['remark']),
              style: _tableCellStyle.copyWith(color: themeProvider.textColor),
            )),
          ];

          if (showDistance) {
            cells.add(DataCell(Text(
              attendance['distance']?.toStringAsFixed(2) ?? '0.00',
              style: _tableCellStyle.copyWith(color: themeProvider.textColor),
            )));
          }

          if (showCost) {
            cells.add(DataCell(Text(
              attendance['calculated_cost']?.toStringAsFixed(2) ?? '0.00',
              style: _tableCellStyle.copyWith(color: themeProvider.textColor),
            )));
          }

          return DataRow(cells: cells);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        drawer: NavBar(),
        backgroundColor: themeProvider.backgroundColor,
        appBar: AppBar(
          iconTheme: IconThemeData(color: themeProvider.iconColor),
          backgroundColor: themeProvider.appBarColor,
          elevation: 0,
          title: Text(
            'Attendance Report',
            style: TextStyle(
                color: themeProvider.textColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('View your attendance details',
                    style: TextStyle(
                        color: themeProvider.secondaryTextColor, fontSize: 14)),
                const SizedBox(height: 24),

                // Month selector
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: themeProvider.inputBorderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final pickedMonth = await showMonthYearPicker(
                              context: context,
                              initialDate: selectedMonth ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: ColorScheme(
                                      brightness: Brightness.dark,
                                      primary: themeProvider.lionColor,
                                      surface: themeProvider.cardColor,
                                      onSurface: themeProvider.textColor,
                                      onPrimary: Colors.black,
                                      secondary: themeProvider.lionColor,
                                      onSecondary: Colors.black,
                                      error: themeProvider.errorColor,
                                      onError: themeProvider.errorColor,
                                    ),
                                    dialogBackgroundColor: themeProvider.backgroundColor,
                                    highlightColor: themeProvider.lionColor,
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedMonth != null) {
                              setState(() => selectedMonth = pickedMonth);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: themeProvider.iconColor, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  selectedMonth == null
                                      ? 'Select Month'
                                      : '${selectedMonth!.year}-${selectedMonth!.month.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      color: themeProvider.textColor,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (selectedMonth != null)
                        IconButton(
                          icon: Icon(Icons.clear,
                              color: themeProvider.secondaryTextColor),
                          onPressed: _clearSelection,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Get button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: LoadingButton(
                    isLoading: _isSubmitting,
                    onPressed: _getAttendance,
                    backgroundColor: themeProvider.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      'Get Attendance',
                      style: TextStyle(
                        color: themeProvider.buttonColor2,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (_attendanceDetails.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _exportToExcel,
                        icon: Icon(Icons.download,
                            color: themeProvider.buttonColor2),
                        label: Text(
                          'Export to Excel',
                          style: TextStyle(
                              color: themeProvider.buttonColor2,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                if (_isLoading)
                  Center(
                      child: CircularProgressIndicator(
                          color: themeProvider.lionColor))
                else if (_errorMessage.isNotEmpty)
                  Text(_errorMessage, style: TextStyle(color: Colors.red))
                else if (_attendanceDetails.isEmpty)
                    Text('Attendance Not Found',
                        style: TextStyle(
                            color: themeProvider.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))
                  else
                    _buildAttendanceTable(themeProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
