import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:su_track/screens/expense/expenseShow.dart';
import '../../services/expense/getCategory.dart';
import '../../services/expense/getEvent.dart';
import '../../services/expense/saveExpense.dart';
import '../navBar.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ExpenseScreenState createState() => ExpenseScreenState();
}

class ExpenseScreenState extends State<ExpenseScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ExpenseFormScreen(), // This will show the form
    const ExpenseScreenShow(), // This will show the expense history
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
          elevation: 0,
          title: const Text(
            'Expense',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _pages[_selectedIndex], // Dynamically display selected content
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: themeProvider.bottomNavBarColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: 'Form',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
          ],
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

class ExpenseFormScreen extends StatefulWidget {
  @override
  _ExpenseFormScreenState createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  String? selectedEventId;
  List<Map<String, String>> events = [];
  List<Map<String, String>> categories = [];
  final Map<String, TextEditingController> amountControllers = {};
  final Map<String, TextEditingController> sgstControllers = {};
  final Map<String, TextEditingController> cgstControllers = {};
  final Map<String, TextEditingController> totalAmountControllers = {};
  final Map<String, TextEditingController> remarkControllers = {};
  final TextEditingController _billDateController = TextEditingController();
  final TextEditingController _vendorNameController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _particularController = TextEditingController();
  bool _isSaving = false;

  // Cache commonly used styles
  static const _baseInputDecoration = InputDecoration(
    filled: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  @override
  void initState() {
    super.initState();
    _loadEventTypes();
    _loadCategoryTypes();
  }

  Future<void> _loadEventTypes() async {
    try {
      List<Map<String, String>> fetchedEvents = await fetchEventTypes(context);
      if (mounted) {
        setState(() {
          events = fetchedEvents;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load event types')),
      );
    }
  }

  Future<void> _loadCategoryTypes() async {
    try {
      List<Map<String, String>> fetchedCategories = await fetchCategoryTypes(context);
      if (mounted) {
        setState(() {
          categories = fetchedCategories;
          for (var category in categories) {
            amountControllers.putIfAbsent(
                category['category_type_id']!, () => TextEditingController());
            sgstControllers.putIfAbsent(
                category['category_type_id']!, () => TextEditingController());
            cgstControllers.putIfAbsent(
                category['category_type_id']!, () => TextEditingController());
            totalAmountControllers.putIfAbsent(
                category['category_type_id']!, () => TextEditingController());
            remarkControllers.putIfAbsent(
                category['category_type_id']!, () => TextEditingController());
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load category types: $e')),
      );
    }
  }

  void _calculateTotalAmount(String categoryId) {
    final amount = double.tryParse(amountControllers[categoryId]?.text ?? '0') ?? 0;
    final sgst = double.tryParse(sgstControllers[categoryId]?.text ?? '0') ?? 0;
    final cgst = double.tryParse(cgstControllers[categoryId]?.text ?? '0') ?? 0;
    final total = amount + sgst + cgst;
    totalAmountControllers[categoryId]?.text = total.toStringAsFixed(2);
  }

  void _selectDate(BuildContext context, bool isFromDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
          _billDateController.text = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
        }
      });
    }
  }

  void _saveExpense() async {
    if (selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an event type')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Ensure total_amount is up to date before reading values
      for (var category in categories) {
        final id = category['category_type_id']!;
        _calculateTotalAmount(id);
      }

      List<Map<String, dynamic>> categoryData = categories.map((category) {
        final categoryId = category['category_type_id']!;
        final amount = double.tryParse(amountControllers[categoryId]?.text.trim() ?? '0') ?? 0.0;
        final sgst = double.tryParse(sgstControllers[categoryId]?.text.trim() ?? '0') ?? 0.0;
        final cgst = double.tryParse(cgstControllers[categoryId]?.text.trim() ?? '0') ?? 0.0;

        final totalAmount = amount + sgst + cgst;

        return {
          'category_type_id': int.parse(categoryId),
          'amount': amount,
          'sgst': sgst,
          'cgst': cgst,
          'total_amount': totalAmount,
          'remark': remarkControllers[categoryId]?.text.trim() ?? '',
        };
      }).where((category) => (category['amount'] as double) > 0).toList();

      await saveExpense(
        context: context,
        billDate: _billDateController.text,
        billNo: _billNoController.text.trim(),
        vendorName: _vendorNameController.text.trim(),
        place: _placeController.text.trim(),
        particular: _particularController.text.trim(),
        eventId: selectedEventId!,
        categories: categoryData,
        onSuccess: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
        onError: (message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit your expense details here',
                  style: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Bill Details Section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeProvider.inputBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill Details',
                        style: TextStyle(
                          color: themeProvider.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Bill Date
                      GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: TextFormField(
                          controller: _billDateController,
                          cursorColor: themeProvider.cursorColor,
                          style: TextStyle(color: themeProvider.textColor),
                          enabled: false,
                          decoration: _getInputDecoration('Select Bill Date', themeProvider),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Vendor Name
                      TextFormField(
                        controller: _vendorNameController,
                        cursorColor: themeProvider.cursorColor,
                        style: TextStyle(color: themeProvider.textColor),
                        decoration: _getInputDecoration('Vendor Name', themeProvider),
                      ),
                      const SizedBox(height: 16),
                      // Place
                      TextFormField(
                        controller: _placeController,
                        cursorColor: themeProvider.cursorColor,
                        style: TextStyle(color: themeProvider.textColor),
                        decoration: _getInputDecoration('Place', themeProvider),
                      ),
                      const SizedBox(height: 16),
                      // Bill Number
                      TextFormField(
                        controller: _billNoController,
                        cursorColor: themeProvider.cursorColor,
                        style: TextStyle(color: themeProvider.textColor),
                        decoration: _getInputDecoration('Bill Number', themeProvider),
                      ),
                      const SizedBox(height: 16),
                      // Particular
                      TextFormField(
                        cursorColor: themeProvider.cursorColor,
                        controller: _particularController,
                        style: TextStyle(color: themeProvider.textColor),
                        decoration: _getInputDecoration('Particular', themeProvider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Event Selection
                Container(
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeProvider.inputBorderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedEventId,
                      isExpanded: true,
                      dropdownColor: themeProvider.cardColor,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      items: events.map((event) {
                        return DropdownMenuItem<String>(
                          value: event['event_type_id'],
                          child: Text(
                            event['event_type_name'] ?? '',
                            style: TextStyle(color: themeProvider.textColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedEventId = newValue;
                        });
                      },
                      hint: Text('Select Event Type',
                          style: TextStyle(color: themeProvider.secondaryTextColor)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Category Items Table
                Container(
                  decoration: BoxDecoration(
                    color: themeProvider.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeProvider.inputBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Expense Categories',
                          style: TextStyle(
                            color: themeProvider.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 56,
                          dataRowHeight: 65,
                          columnSpacing: 16,
                          horizontalMargin: 16,
                          headingRowColor:
                          MaterialStateProperty.all(themeProvider.backgroundColor),
                          dataRowColor:
                          MaterialStateProperty.all(themeProvider.cardColor),
                          border: TableBorder(
                            horizontalInside:
                            BorderSide(color: themeProvider.inputBorderColor, width: 1),
                          ),
                          columns: [
                            DataColumn(
                              label: Container(
                                width: 120,
                                child: Text('Category',
                                    style: TextStyle(
                                      color: themeProvider.secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 100,
                                child: Text('Amount',
                                    style: TextStyle(
                                      color: themeProvider.secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 80,
                                child: Text('SGST',
                                    style: TextStyle(
                                      color: themeProvider.secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 80,
                                child: Text('CGST',
                                    style: TextStyle(
                                      color: themeProvider.secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 100,
                                child: Text('Total',
                                    style: TextStyle(
                                      color: themeProvider.secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 150,
                                child: Text('Remarks',
                                    style: TextStyle(
                                      color: themeProvider.secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                          ],
                          rows: categories.map((category) {
                            final categoryId = category['category_type_id'] ?? '';

                            // Initialize controllers if they don't exist
                            if (!amountControllers.containsKey(categoryId)) {
                              amountControllers[categoryId] =
                                  TextEditingController();
                              sgstControllers[categoryId] =
                                  TextEditingController();
                              cgstControllers[categoryId] =
                                  TextEditingController();
                              totalAmountControllers[categoryId] =
                                  TextEditingController();
                              remarkControllers[categoryId] =
                                  TextEditingController();
                            }

                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    width: 120,
                                    child: Text(
                                      category['category_type_name'] ?? '',
                                      style: TextStyle(color: themeProvider.textColor),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    width: 100,
                                    child: TextField(
                                      controller: amountControllers[categoryId],
                                      cursorColor: themeProvider.cursorColor,
                                      style: TextStyle(color: themeProvider.textColor),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^(?:\d{1,6})?\.?\d{0,2}')),
                                      ],
                                      decoration: _tableInputDecoration('Amount', themeProvider),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          final parts = value.split('.');
                                          if (parts[0].length > 6) {
                                            amountControllers[categoryId]!.text = '${parts[0].substring(0, 6)}${parts.length > 1 ? '.${parts[1]}' : ''}';
                                          }
                                          _calculateTotalAmount(categoryId);
                                        }
                                      },
                                      onEditingComplete: () {
                                        // Format to 2 decimal places when field loses focus
                                        if (amountControllers[categoryId]!.text.isNotEmpty) {
                                          final value = double.tryParse(amountControllers[categoryId]!.text) ?? 0;
                                          amountControllers[categoryId]!.text = value.toStringAsFixed(2);
                                        }
                                        _calculateTotalAmount(categoryId);
                                        FocusScope.of(context).nextFocus();
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    width: 80,
                                    child: TextField(
                                      controller: sgstControllers[categoryId],
                                      cursorColor: themeProvider.cursorColor,
                                      style: TextStyle(color: themeProvider.textColor),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^(?:\d{1,6})?\.?\d{0,2}')),
                                      ],
                                      decoration: _tableInputDecoration('SGST', themeProvider),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          final parts = value.split('.');
                                          if (parts[0].length > 6) {
                                            sgstControllers[categoryId]!.text = '${parts[0].substring(0, 6)}${parts.length > 1 ? '.${parts[1]}' : ''}';
                                          }
                                          _calculateTotalAmount(categoryId);
                                        }
                                      },
                                      onEditingComplete: () {
                                        if (sgstControllers[categoryId]!.text.isNotEmpty) {
                                          final value = double.tryParse(sgstControllers[categoryId]!.text) ?? 0;
                                          sgstControllers[categoryId]!.text = value.toStringAsFixed(2);
                                        }
                                        _calculateTotalAmount(categoryId);
                                        FocusScope.of(context).nextFocus();
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    width: 80,
                                    child: TextField(
                                      controller: cgstControllers[categoryId],
                                      cursorColor: themeProvider.cursorColor,
                                      style: TextStyle(color: themeProvider.textColor),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^(?:\d{1,6})?\.?\d{0,2}')),
                                      ],
                                      decoration: _tableInputDecoration('CGST', themeProvider),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          final parts = value.split('.');
                                          if (parts[0].length > 6) {
                                            cgstControllers[categoryId]!.text = '${parts[0].substring(0, 6)}${parts.length > 1 ? '.${parts[1]}' : ''}';
                                          }
                                          _calculateTotalAmount(categoryId);
                                        }
                                      },
                                      onEditingComplete: () {
                                        if (cgstControllers[categoryId]!.text.isNotEmpty) {
                                          final value = double.tryParse(cgstControllers[categoryId]!.text) ?? 0;
                                          cgstControllers[categoryId]!.text = value.toStringAsFixed(2);
                                        }
                                        _calculateTotalAmount(categoryId);
                                        FocusScope.of(context).nextFocus();
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    width: 100,
                                    child: TextField(
                                      controller: totalAmountControllers[categoryId],
                                      style: TextStyle(color: themeProvider.textColor),
                                      enabled: false,
                                      decoration: _tableInputDecoration('Total', themeProvider).copyWith(
                                        fillColor: themeProvider.backgroundColor,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    width: 150,
                                    child: TextField(
                                      controller: remarkControllers[categoryId],
                                      cursorColor: themeProvider.cursorColor,
                                      style: TextStyle(color: themeProvider.textColor),
                                      decoration: _tableInputDecoration('Remarks', themeProvider),
                                      onChanged: (value) {
                                        remarkControllers[categoryId]!.text = value;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
                    onPressed: _isSaving ? null : _saveExpense,
                    style: themeProvider.primaryButtonStyle,
                    child: _isSaving
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

  // Create a method to customize the base decoration
  InputDecoration _getInputDecoration(String hint, ThemeProvider themeProvider) {
    return _baseInputDecoration.copyWith(
      hintText: hint,
      hintStyle: TextStyle(color: themeProvider.secondaryTextColor),
      fillColor: themeProvider.inputFillColor,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: themeProvider.primaryColor),
      ),
    );
  }

  InputDecoration _tableInputDecoration(String hint, ThemeProvider themeProvider) {
    return InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      hintText: hint,
      hintStyle: TextStyle(color: themeProvider.secondaryTextColor, fontSize: 13),
      filled: true,
      fillColor: themeProvider.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: themeProvider.inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: themeProvider.inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: themeProvider.primaryColor),
      ),
    );
  }

  @override
  void dispose() {
    _billDateController.dispose();
    _vendorNameController.dispose();
    _placeController.dispose();
    _billNoController.dispose();
    _particularController.dispose();
    super.dispose();
  }
}
