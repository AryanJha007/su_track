import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:su_track/services/od/getAppliedOd.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:su_track/providers/theme_provider.dart';

class ODHistoryPage extends StatefulWidget {
  const ODHistoryPage({super.key});

  @override
  _ODHistoryPageState createState() => _ODHistoryPageState();
}

class _ODHistoryPageState extends State<ODHistoryPage> {
  late Future<List<Map<String, dynamic>>> _odHistoryFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _odHistoryFuture = fetchAppliedOd(context);
  }

  Future<void> _refreshOdHistory() async {
    setState(() {
      _isRefreshing = true;
    });
    try {
      final odHistory = await fetchAppliedOd(context);
      setState(() {
        _odHistoryFuture = Future.value(odHistory);
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
    final Map<String, Color> statusColors = {
      'approved': themeProvider.approvedColor,
      'pending': themeProvider.pendingColor,
      'rejected': themeProvider.rejectedColor,
    };
    return statusColors[status.toLowerCase()] ?? Colors.grey;
  }

  String capitalize(String word) {
    if (word.isEmpty) return '';
    return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  Future<void> _openDocument(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: RefreshIndicator(
          onRefresh: _refreshOdHistory,
          color: themeProvider.primaryColor,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _odHistoryFuture,
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
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No OD history available.',
                    style: TextStyle(color: themeProvider.textColor),
                  ),
                );
              }

              final odHistory = snapshot.data!;
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: odHistory.length,
                itemBuilder: (context, index) {
                  final od = odHistory[index];
                  final status = od['fstatus'] ?? 'Pending';
                  final statusColor = getStatusColor(status, themeProvider);
                  final fromDate = od['applied_from_date'] ?? 'N/A';
                  final toDate = od['applied_to_date'] ?? 'N/A';
                  final reason = capitalize(od['reason'] ?? '');
                  final type = capitalize(od['leave_duration'] ?? 'N/A');
                  final hrs = od['no_hrs'] ?? 'N/A';
                  final timeD = od['departure_time'].toString() ?? 'N/A';
                  final timeA = od['arrival_time'].toString() ?? 'N/A';

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
                                '$fromDate - $toDate',
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
                              Icon(Icons.work_outline, color: themeProvider.secondaryTextColor, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: themeProvider.textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.timer, color: themeProvider.secondaryTextColor, size: 18),
                              SizedBox(width: 8),
                              Text(
                                type == 'Hrs' ? '$hrs hrs' : 'Full-day',
                                style: TextStyle(
                                  color: themeProvider.textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // if (type == 'Hrs') ...[
                              //   Text(
                              //     ' ($timeD-$timeA)',
                              //     style: TextStyle(
                              //       color: themeProvider.secondaryTextColor,
                              //       fontSize: 14,
                              //     ),
                              //   ),
                              // ],
                            ],
                          ),
                          if (od['od_document'] != null) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.attach_file, color: themeProvider.primaryColor, size: 18),
                                GestureDetector(
                                  onTap: () => _openDocument(od['od_document']),
                                  child: Text(
                                    ' View Document',
                                    style: TextStyle(
                                      color: themeProvider.primaryColor,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    // Cancel any pending futures/timers if needed
    super.dispose();
  }
}
