import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:su_track/services/leave/getAppliedLeaves.dart';
import 'package:su_track/util/constants.dart' as constants;
import '../../services/auth/loggedIn.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';

class LeaveHistoryPage extends StatefulWidget {
  const LeaveHistoryPage({super.key});

  @override
  _LeaveHistoryPageState createState() => _LeaveHistoryPageState();
}

class _LeaveHistoryPageState extends State<LeaveHistoryPage> {
  late Future<List<Map<String, dynamic>>> _leavesFuture;
  bool _isRefreshing = false;

  // Cache status colors
  final Map<String, Color> _statusColors = {
    'approved': Colors.green,
    'pending': Colors.orange,
    'rejected': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _leavesFuture = fetchAppliedLeaves(context, constants.um_id);
  }

  Future<void> _refreshLeaves() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final authData = await LoggedIn.getAuthData();
      final leaves = await fetchAppliedLeaves(context, authData['um_Id']);
      setState(() {
        _leavesFuture = Future.value(leaves);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Color getStatusColor(String status, ThemeProvider themeProvider) {
    switch (status.toLowerCase()) {
      case 'approved':
        return themeProvider.approvedColor;
      case 'rejected':
        return themeProvider.rejectedColor;
      case 'cancelled':
        return themeProvider.warningColor;
      default:
        return themeProvider.primaryColor;
    }
  }

  String capitalize(String word) {
    if (word.isEmpty) return word ?? '';
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => RefreshIndicator(
        onRefresh: _refreshLeaves,
        color: themeProvider.primaryColor,
        child: Container(
          color: themeProvider.backgroundColor,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _leavesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !_isRefreshing) {
                return Center(
                  child: Image.asset(
                    'assets/images/loading.gif',
                    height: 70,
                    width: double.infinity,
                    color: themeProvider.lionColor,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'No leave History.',
                    style: TextStyle(color: themeProvider.textColor),
                  ),
                );
              }

              final leaves = snapshot.data ?? [];
              if (leaves.isEmpty) {
                return Center(
                  child: Text(
                    'No leaves found',
                    style: TextStyle(color: themeProvider.textColor),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: leaves.length,
                itemBuilder: (context, index) {
                  final leave = leaves[index];
                  final status = leave['fstatus'] ?? 'Pending';
                  final statusColor = getStatusColor(status, themeProvider);

                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: statusColor,
                          width: 6,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: themeProvider.textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${leave['applied_from_date'].toString().substring(5)} - ${leave['applied_to_date'].toString().substring(5)}',
                                style: TextStyle(
                                  color: themeProvider.secondaryTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.event, color: themeProvider.secondaryTextColor, size: 18),
                              SizedBox(width: 8),
                              if(leave['Ltype']!=null)
                              Text(
                                capitalize(leave['Ltype']) ?? 'N/A',
                                style: TextStyle(
                                  color: themeProvider.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if(leave['Ltype']==null)
                              Text(
                                capitalize('LWP') ?? 'N/A',
                                style: TextStyle(
                                  color: themeProvider.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.timelapse, color: themeProvider.secondaryTextColor, size: 18),
                              SizedBox(width: 8),
                              Text(
                                capitalize(leave['leave_duration']).toString() ?? 'N/A',
                                style: TextStyle(
                                  color: themeProvider.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.comment, color: themeProvider.secondaryTextColor, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  capitalize(leave['reason'] ?? 'No reason provided'),
                                  style: TextStyle(
                                    color: themeProvider.secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel any pending futures
    super.dispose();
  }
}
