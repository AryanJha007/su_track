import 'package:flutter/material.dart';
import 'package:su_track/services/dailyReporting/getDailyReporting.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

class DailyReportingView extends StatefulWidget {
  const DailyReportingView({super.key});

  @override
  _DailyReportingViewState createState() => _DailyReportingViewState();
}

class _DailyReportingViewState extends State<DailyReportingView> {
  List<Map<String, dynamic>> _reportDetails = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Cache commonly used styles and colors
  BoxDecoration _getCardDecoration(ThemeProvider themeProvider) => BoxDecoration(
    color: themeProvider.cardColor,
    borderRadius: const BorderRadius.all(Radius.circular(12)),
  );

  TextStyle _getTextStyle(ThemeProvider themeProvider) => TextStyle(
    color: themeProvider.textColor,
    fontSize: 16,
  );

  // Cache status colors
  final Map<String, Color> _statusColors = {
    'approved': Colors.green,
    'rejected': Colors.red,
    'cancelled': Colors.orangeAccent,
  };

  // Update grey text style to use theme colors
  TextStyle _getGreyTextStyle(ThemeProvider themeProvider) => TextStyle(
    fontSize: 12,
    color: themeProvider.secondaryTextColor,
  );

  @override
  void initState() {
    super.initState();
    _getDailyReporting();
  }

  void _getDailyReporting() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await fetchDailyReporting(context);
      setState(() {
        _reportDetails = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No daily Reporting History.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    return _statusColors[status.toLowerCase()] ?? Colors.red;
  }

  String capitalize(String word) {
    if (word.isEmpty) return '';
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  @override
  void dispose() {
    // Cancel any pending futures
    super.dispose();
  }

  // Optimize list view builder
  Widget _buildReportCard(Map<String, dynamic> report, ThemeProvider themeProvider) {
    final status = report['status_name'] ?? 'Pending';
    final statusColor = getStatusColor(status);
    final date = report['date'] ?? 'N/A';
    final time = report['time'] ?? 'N/A';
    final remark = capitalize(report['remark'] ?? '');
    final workType = capitalize(report['work_type'] ?? 'N/A');
    final vehicleNo = report['vehicle_no'];
    final kilometers = report['kilometers'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _getCardDecoration(themeProvider).copyWith(
        border: Border(left: BorderSide(color: statusColor, width: 6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: themeProvider.secondaryTextColor),
                    const SizedBox(width: 4),
                    Text(time, style: _getGreyTextStyle(themeProvider)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Work type
            Row(
              children: [
                Icon(Icons.work_outline, color: themeProvider.secondaryTextColor, size: 18),
                Text(' $workType', style: TextStyle(fontSize: 16, color: themeProvider.textColor)),
              ],
            ),
            const SizedBox(height: 4),

            // Date
            Row(
              children: [
                Icon(Icons.calendar_today, color: themeProvider.secondaryTextColor, size: 18),
                Text(' $date', style: TextStyle(color: themeProvider.textColor)),
              ],
            ),

            // Remarks (if any)
            if (remark.isNotEmpty) const SizedBox(height: 4),
            if (remark.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.comment, color: themeProvider.secondaryTextColor, size: 18),
                  Expanded(
                    child: Text(
                      ' $remark',
                      style: TextStyle(fontSize: 14, color: themeProvider.textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            // Vehicle number (if any)
            if (vehicleNo != null && vehicleNo != '0' && vehicleNo.toString().trim().isNotEmpty) const SizedBox(height: 4),
            if (vehicleNo != null && vehicleNo != '0' && vehicleNo.toString().trim().isNotEmpty)
              Row(
                children: [
                  Icon(Icons.directions_car, color: themeProvider.secondaryTextColor, size: 18),
                  Text(
                    ' $vehicleNo',
                    style: TextStyle(fontSize: 14, color: themeProvider.textColor),
                  ),
                ],
              ),


            if (kilometers != null &&
                kilometers.toString().isNotEmpty &&
                kilometers.toString() != '0') const SizedBox(height: 4),
            if (kilometers != null &&
                kilometers.toString().isNotEmpty &&
                kilometers.toString() != '0')
              Row(
                children: [
                  Icon(Icons.speed, color: themeProvider.secondaryTextColor, size: 18),
                  Text(
                    ' $kilometers km',
                    style: TextStyle(fontSize: 14, color: themeProvider.textColor),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: _isLoading
            ? Center(
          child: Image.asset(
            'assets/images/loading.gif', // Replace with your GIF
            height: 70,
            width: double.infinity,
            color: themeProvider.lionColor,
          ),
        )
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: themeProvider.errorColor),
                    ),
                  )
                : _reportDetails.isEmpty
                    ? Center(
                        child: Text(
                          'No daily reports available.',
                          style: TextStyle(color: themeProvider.textColor),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        itemCount: _reportDetails.length,
                        itemBuilder: (context, index) {
                          final report = _reportDetails[index];
                          return _buildReportCard(report, themeProvider);
                        },
                      ),
      ),
    );
  }
}
