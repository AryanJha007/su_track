import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:su_track/services/expense/getExpenses.dart';
import 'package:su_track/services/expense/uploadFile.dart';
import 'package:su_track/widgets/loading_button.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpenseScreenShow extends StatefulWidget {
  const ExpenseScreenShow({super.key});

  @override
  _ExpenseScreenShowState createState() => _ExpenseScreenShowState();
}

class _ExpenseScreenShowState extends State<ExpenseScreenShow> {
  List<Map<String, dynamic>> expenses = [];
  Map<String, List<PlatformFile>> selectedFilesMap = {};
  Map<String, bool> uploadingMap = {};
  List<List<bool>> _expandedStates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await fetchExpenses(context);
      setState(() {
        expenses = result['expenses'];
        _expandedStates = expenses.map((expense) {
          final expenseTypes = expense['expense_types'] as List;
          return List.generate(expenseTypes.length, (_) => false);
        }).toList();
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectFiles(String expenseTypeId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          // Initialize the list if it doesn't exist
          selectedFilesMap[expenseTypeId] =
              selectedFilesMap[expenseTypeId] ?? [];
          // Add new files to existing list
          selectedFilesMap[expenseTypeId]!.addAll(result.files);
        });
      }
    } catch (e) {
      print('Error selecting files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting files. Please try again.')),
        );
      }
    }
  }

  void _removeFile(String expenseTypeId, int index) {
    setState(() {
      if (selectedFilesMap.containsKey(expenseTypeId) &&
          selectedFilesMap[expenseTypeId]!.length > index) {
        selectedFilesMap[expenseTypeId]!.removeAt(index);
        // Remove the key if no files are left
        if (selectedFilesMap[expenseTypeId]!.isEmpty) {
          selectedFilesMap.remove(expenseTypeId);
        }
      }
    });
  }

  void _handleUpload(String expenseTypeId) async {
    setState(() {
      uploadingMap[expenseTypeId] = true;
    });
    print(expenseTypeId);
    try {
      print(selectedFilesMap[expenseTypeId]);
      await uploadFiles(
        selectedFiles: selectedFilesMap[expenseTypeId] ?? [],
        expenseTypeId: expenseTypeId,
        context: context,
      );
    } finally {
      if (mounted) {
        setState(() {
          uploadingMap[expenseTypeId] = false;
        });
      }
    }
  }

  Future<void> _openDocument(String url) async {
    if (url.isEmpty) {
      // Handle the null or empty URL case, perhaps by showing an error message
      print('Invalid URL');
      return;
    }

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String capitalize(String word) {
    if (word.isEmpty) return '---';
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: RefreshIndicator(
          onRefresh: _loadExpenses,
          color: themeProvider.primaryColor,
          child: _isLoading
              ? Center(
                  child: Image.asset(
                    'assets/images/loading.gif', // Replace with your GIF
                    height: 70,
                    width: double.infinity,
                    color: themeProvider.lionColor,
                  ),
                )
              : expenses.isEmpty
                  ? Center(
                      child: Text(
                        'No expenses available.',
                        style: TextStyle(
                            color: themeProvider.textColor, fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: expenses.length,
                      itemBuilder: (context, expenseIndex) {
                        final expense = expenses[expenseIndex];
                        final isUploading =
                            uploadingMap[expense['expense_id']] ?? false;
                        // Filter out expense types with null expense_type_id
                        final validExpenseTypes = expense['expense_types']
                            .where((expenseType) =>
                                expenseType['expense_type_id'] != null)
                            .toList();

                        // Create a list of cards for each valid expense type
                        return Column(
                          children:
                              validExpenseTypes.map<Widget>((expenseType) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: themeProvider.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: themeProvider.dividerColor),
                              ),
                              child: ExpansionTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense['event_type_name'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.textColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      expenseType['category_type_name'] ??
                                          'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: themeProvider.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${expenseType['total_amount'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeProvider.primaryColor,
                                      ),
                                    ),
                                    Text(
                                      expense['bill_date'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: themeProvider.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: themeProvider.backgroundColor,
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow(
                                            'Vendor',
                                            capitalize(
                                                    expense['vendor_name']) ??
                                                'N/A',
                                            themeProvider),
                                        _buildDetailRow(
                                            'Place',
                                            capitalize(expense['place']) ??
                                                'N/A',
                                            themeProvider),
                                        _buildDetailRow(
                                            'Bill No',
                                            expense['bill_no'] ?? 'N/A',
                                            themeProvider),
                                        _buildDetailRow(
                                            'Particular',
                                            capitalize(expense['particular']) ??
                                                'N/A',
                                            themeProvider),
                                        if (expenseType['remark'] != null)
                                          _buildDetailRow(
                                              'Remark',
                                              capitalize(
                                                      expenseType['remark']) ??
                                                  'N/A',
                                              themeProvider),
                                        SizedBox(height: 16),
                                        _buildSelectedFiles(
                                            expenseType['expense_type_id'],
                                            themeProvider),
                                        if (expenseType['upload_bill'] !=
                                                null &&
                                            expenseType['upload_bill']
                                                is List) ...[
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount:
                                                (expenseType['upload_bill']
                                                        as List)
                                                    .length,
                                            itemBuilder: (context, index) {
                                              final fileUrl =
                                                  (expenseType['upload_bill']
                                                      as List)[index];
                                              return Row(
                                                children: [
                                                  Icon(Icons.attach_file,
                                                      color: themeProvider
                                                          .primaryColor,
                                                      size: 18),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _openDocument(fileUrl),
                                                    child: Text(
                                                      ' View Document.',
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .primaryColor,
                                                        fontSize: 14,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                        SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () async {
                                                  await _selectFiles(
                                                      expenseType[
                                                          'expense_type_id']);
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        themeProvider.cardColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: themeProvider
                                                            .dividerColor),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.attach_file,
                                                          color: themeProvider
                                                              .secondaryTextColor,
                                                          size: 20),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Select Files',
                                                        style: TextStyle(
                                                            color: themeProvider
                                                                .secondaryTextColor),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            if (isUploading)
                                              // Show CircularProgressIndicator if uploading
                                              Image.asset(
                                                'assets/images/loading.gif', // Replace with your GIF
                                                height: 70,
                                                width: double.infinity,
                                                color: themeProvider.lionColor,
                                              )
                                            else
                                              // Show the Upload button when not uploading
                                              LoadingButton(
                                                isLoading: false,
                                                onPressed: isUploading
                                                    ? () {}
                                                    : () => _handleUpload(
                                                        expenseType[
                                                            'expense_type_id']),
                                                backgroundColor:
                                                    themeProvider.primaryColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Upload',
                                                  style: TextStyle(
                                                    color: themeProvider
                                                        .buttonColor2,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, ThemeProvider themeProvider) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFiles(
      String expenseTypeId, ThemeProvider themeProvider) {
    final files = selectedFilesMap[expenseTypeId];
    if (files == null || files.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: files.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value;
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.insert_drive_file,
                  color: themeProvider.primaryColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.name,
                  style: TextStyle(color: themeProvider.textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    color: themeProvider.errorColor, size: 20),
                onPressed: () => _removeFile(expenseTypeId, index),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                splashRadius: 20,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    // Clean up controllers and subscriptions
    super.dispose();
  }
}
