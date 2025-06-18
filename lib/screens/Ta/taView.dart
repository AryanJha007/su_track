import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';
import '../../services/dailyReporting/getTaReport.dart';
import '../../services/dailyReporting/saveTa.dart';
import '../../services/dailyReporting/getApprovedTa.dart';
import '../navBar.dart';
import '../../widgets/loading_button.dart'; // Make sure you have this

class TAView extends StatefulWidget {
  const TAView({super.key});

  @override
  State<TAView> createState() => _TAViewState();
}

class _TAViewState extends State<TAView> {
  DateTime? selectedMonth;
  bool _isLoading = false;
  bool _isSubmitting = false;
  int approvedTA = 0;
  List<Map<String, dynamic>> taList = [];

  void _pickMonth(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: themeProvider.lionColor,
              surface: themeProvider.cardColor,
              onSurface: themeProvider.textColor,
              secondary: themeProvider.lionColor,
              error: themeProvider.errorColor,
            ),
            dialogBackgroundColor: themeProvider.backgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedMonth = picked;
      });
      _fetchTAData();
    }
  }

  void _clearMonth() {
    setState(() {
      selectedMonth = null;
      taList = [];
      approvedTA = 0;
    });
  }

  Future<void> _fetchTAData() async {
    if (selectedMonth == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await fetchTAReport(
        month: selectedMonth!.month,
        year: selectedMonth!.year,
      );

      final approved = await fetchApprovedTA(
        month: selectedMonth!.month,
        year: selectedMonth!.year,
      );

      setState(() {
        approvedTA = approved;
        taList = data.map((e) {
          return {
            'range': '${e['distance']} KM',
            'cost': '₹${e['cost_per_km']}',
            'calculated': '₹${e['calculated_cost']}',
          };
        }).toList();
      });
    } catch (e) {
      setState(() {
        taList = [];
        approvedTA = 0;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _calculateTotal() {
    int total = 0;
    for (var item in taList) {
      final value = item['calculated'].toString().replaceAll(RegExp(r'[^\d]'), '');
      total += int.tryParse(value) ?? 0;
    }
    return '₹$total';
  }

  Future<void> _submitTotalTA() async {
    if (selectedMonth == null) return;

    setState(() => _isSubmitting = true);
    int total = int.parse(_calculateTotal().replaceAll(RegExp(r'[^\d]'), ''));

    bool success = await submitTotalTA(
      calculatedTa: total,
      month: selectedMonth!.month.toInt(),
      year: selectedMonth!.year.toInt(),
    );

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'TA submitted successfully' : 'Submission failed'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildTATable(ThemeProvider themeProvider) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeProvider.dividerColor),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 32,
                dataRowColor: MaterialStateProperty.all(themeProvider.inputFillColor),
                border: TableBorder.all(color: themeProvider.dividerColor),
                headingRowHeight: 56,
                dataRowHeight: 52,
                columns: [
                  DataColumn(label: Text('Sr.', style: TextStyle(color: themeProvider.textColor))),
                  DataColumn(label: Text('Range', style: TextStyle(color: themeProvider.textColor))),
                  DataColumn(label: Text('Cost', style: TextStyle(color: themeProvider.textColor))),
                  DataColumn(label: Text('Calculated', style: TextStyle(color: themeProvider.textColor))),
                ],
                rows: taList.asMap().entries.map((entry) {
                  return DataRow(cells: [
                    DataCell(Text((entry.key + 1).toString())),
                    DataCell(Text(entry.value['range'])),
                    DataCell(Text(entry.value['cost'])),
                    DataCell(Text(entry.value['calculated'])),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Calculated: ${_calculateTotal()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: themeProvider.textColor,
                  ),
                ),
                if (approvedTA > 0)
                  Text(
                    'Approved TA: ₹$approvedTA',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.textColor.withOpacity(0.8),
                    ),
                  ),
                // const SizedBox(height: 8),
                // SizedBox(
                //   height: 50,
                //   width: double.infinity,
                //   child: LoadingButton(
                //     isLoading: _isSubmitting,
                //     onPressed: _submitTotalTA,
                //     backgroundColor: themeProvider.primaryColor,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //     child: Text(
                //       'Submit TA',
                //       style: TextStyle(
                //         color: themeProvider.buttonColor2,
                //         fontSize: 16,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => Scaffold(
        drawer: NavBar(),
        backgroundColor: themeProvider.backgroundColor,
        appBar: AppBar(
          iconTheme: IconThemeData(color: themeProvider.iconColor),
          backgroundColor: themeProvider.appBarColor,
          elevation: 0,
          title: Text('TA Report', style: TextStyle(color: themeProvider.textColor, fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Travel Allowance Summary',
                  style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 14)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeProvider.inputBorderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickMonth(context),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: themeProvider.iconColor),
                            const SizedBox(width: 12),
                            Text(
                              selectedMonth == null
                                  ? 'Select Month'
                                  : '${selectedMonth!.year}-${selectedMonth!.month.toString().padLeft(2, '0')}',
                              style: TextStyle(color: themeProvider.textColor, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedMonth != null)
                      IconButton(
                        icon: Icon(Icons.clear, color: themeProvider.secondaryTextColor),
                        onPressed: _clearMonth,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? Center(
                child: CircularProgressIndicator(color: themeProvider.lionColor),
              )
                  : taList.isEmpty
                  ? Center(
                child: Text('No TA data found for selected month.',
                    style: TextStyle(color: themeProvider.textColor)),
              )
                  : _buildTATable(themeProvider),
            ],
          ),
        ),
      ),
    );
  }
}
