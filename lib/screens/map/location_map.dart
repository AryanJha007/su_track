import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:su_track/providers/theme_provider.dart';
import 'package:su_track/services/auth/loggedIn.dart';
import 'package:su_track/services/geolocation/updateGeolocation.dart';
import 'dart:async';

import '../../services/backgroundService.dart';
import '../../services/geolocation/getTodaysRoute.dart';
import '../../services/geolocation/postTodaysRoute.dart';
import '../navBar.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({Key? key}) : super(key: key);

  @override
  _LocationMapScreenState createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  String _currentDate = DateTime.now().toString().split(' ')[0];
  Timer? _midnightTimer;
  StreamSubscription<Position>? _positionStream;
  bool _isFollowingUser = true;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
    _fetchTodayRoute();
    _setupMidnightReset();
  }

  void _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2018),
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
        _currentDate =
        pickedDate.toString().split(' ')[0];
      });

      await _fetchTodayRoute();
    } else {
      setState(() {
        _currentDate =
        DateTime.now().toString().split(' ')[0];
      });

      await _fetchTodayRoute();
    }
  }

  Future<void> _initializeLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission is required')),
      );
      return;
    }

    _getCurrentLocation();
    if (await LoggedIn.isLoggedIn() && await LoggedIn.isPunchedIn()) {
      await LocationServiceManager.startLocationService();
    } else {
      await LocationServiceManager.startLocationService();
    }
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() async {
        _currentPosition = position;
        _routePoints.add(LatLng(position.latitude, position.longitude));
        _polylines = {
          Polyline(
            polylineId: PolylineId('today_route'),
            points: _routePoints,
            color: Colors.black,
            width: 5,
          ),
        };
      });

      if (_isFollowingUser && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    });
  }

  Future<void> _fetchTodayRoute() async {
    print(_currentDate);
    if (_currentDate == DateTime.now().toString().split(' ')[0]) {
      List<LatLng> route = await LoggedIn.fetchRoutePoints();
      setState(() {
        _routePoints = route;
        _polylines = {
          Polyline(
            polylineId: PolylineId('today_route'),
            points: _routePoints,
            color: Colors.black,
            width: 5,
          ),
        };
      });
    } else {
      List<LatLng> route = await fetchRoute(_currentDate);
      setState(() {
        _routePoints = route;
        _polylines = {
          Polyline(
            polylineId: PolylineId('today_route'),
            points: _routePoints,
            color: Colors.black,
            width: 5,
          ),
        };
      });
    }
  }

  void _setupMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      setState(() {
        _currentDate = DateTime.now().toString().split(' ')[0];
        _routePoints.clear();
        _polylines.clear();
      });
      _fetchTodayRoute();
      _setupMidnightReset();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      if (_routePoints.isEmpty) {
        _updateCameraToCurrentLocation();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  Future<void> _updateCameraToCurrentLocation() async {
    if (_mapController == null || _currentPosition == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 17,
        ),
      ),
    );
  }

  Future<void> _updateCameraToFitRoute() async {
    if (_mapController == null || _routePoints.isEmpty) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: _routePoints.reduce(
            (value, element) => LatLng(
          value.latitude < element.latitude ? value.latitude : element.latitude,
          value.longitude < element.longitude
              ? value.longitude
              : element.longitude,
        ),
      ),
      northeast: _routePoints.reduce(
            (value, element) => LatLng(
          value.latitude > element.latitude ? value.latitude : element.latitude,
          value.longitude > element.longitude
              ? value.longitude
              : element.longitude,
        ),
      ),
    );

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _midnightTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        drawer: NavBar(),
        appBar: AppBar(
          title: Text('Today\'s Route'),
          backgroundColor: themeProvider.appBarColor,
          iconTheme: IconThemeData(color: themeProvider.iconColor),
          titleTextStyle: TextStyle(
            color: themeProvider.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: _isLoading
            ? Center(
          child: Image.asset(
            'assets/images/loading.gif', // Replace with your GIF
            height: 70,
            width: double.infinity,
            color: themeProvider.lionColor,
          ),
        )
            : Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                )
                    : LatLng(20.5937, 78.9629),
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_routePoints.isNotEmpty) {
                  _updateCameraToFitRoute();
                } else if (_currentPosition != null) {
                  _updateCameraToCurrentLocation();
                }
              },
              onCameraMove: (_) {
                setState(() => _isFollowingUser = false);
              },
              markers: _currentPosition == null
                  ? {}
                  : {
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  infoWindow: InfoWindow(title: 'Current Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Text(
                    'Date: $_currentDate'.substring(0, 16),
                    style: TextStyle(
                      color: themeProvider.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                setState(() => _isFollowingUser = true);
                _updateCameraToCurrentLocation();
              },
              backgroundColor: _isFollowingUser
                  ? themeProvider.primaryColor
                  : themeProvider.cardColor,
              heroTag: 'location',
              child: Icon(
                Icons.my_location,
                color: _isFollowingUser
                    ? themeProvider.buttonColor2
                    : themeProvider.primaryColor,
              ),
            ),
            SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () {
                _fetchTodayRoute();
                if (_routePoints.isNotEmpty) {
                  _updateCameraToFitRoute();
                }
              },
              backgroundColor: themeProvider.cardColor,
              heroTag: 'refresh',
              child: Icon(
                Icons.refresh,
                color: themeProvider.primaryColor,
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      );
    });
  }
}
