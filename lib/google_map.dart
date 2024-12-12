import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RealTimeLocationApp extends StatefulWidget {
  @override
  _RealTimeLocationAppState createState() => _RealTimeLocationAppState();
}

class _RealTimeLocationAppState extends State<RealTimeLocationApp> {
  GoogleMapController? _mapController;
  Marker? _startMarker;
  Marker? _endMarker;
  List<LatLng> _polylineCoordinates = [];
  Polyline? _polyline;
  LatLng? _currentPosition;
  CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(22.370021, 91.845063), // Default initial location
    zoom: 16,
  );

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
   
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permission permanently denied.");
    }

 
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _updateCurrentPosition(LatLng(position.latitude, position.longitude));
  }

  void _updateCurrentPosition(LatLng position) {
    setState(() {
      _currentPosition = position;

      _initialCameraPosition = CameraPosition(target: position, zoom: 16);


      _startMarker = Marker(
        markerId: MarkerId("start_location"),
        position: position,
        infoWindow: InfoWindow(
          title: "My Current Location",
          snippet: "Lat: ${position.latitude}, Lng: ${position.longitude}",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    });


    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 16),
      ),
    );
  }

  void _onMapTapped(LatLng tappedPosition) {
    setState(() {
      if (_startMarker == null) {
   
        _startMarker = Marker(
          markerId: MarkerId("start_location"),
          position: tappedPosition,
          infoWindow: InfoWindow(
            title: "Start Location",
            snippet: "Lat: ${tappedPosition.latitude}, Lng: ${tappedPosition.longitude}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );
      } else if (_endMarker == null) {
        // Add the second marker and draw the polyline
        _endMarker = Marker(
          markerId: MarkerId("end_location"),
          position: tappedPosition,
          infoWindow: InfoWindow(
            title: "End Location",
            snippet: "Lat: ${tappedPosition.latitude}, Lng: ${tappedPosition.longitude}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );

        
        _polylineCoordinates.add(_startMarker!.position);
        _polylineCoordinates.add(_endMarker!.position);

        _polyline = Polyline(
          polylineId: PolylineId("route"),
          points: _polylineCoordinates,
          color: Colors.blue,
          width: 5,
        );
      } else {
      
        _startMarker = null;
        _endMarker = null;
        _polylineCoordinates.clear();
        _polyline = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Real-Time Location Tracker"),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (controller) {
          _mapController = controller;
          if (_currentPosition != null) {
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: _currentPosition!, zoom: 16),
              ),
            );
          }
        },
        markers: {
          if (_startMarker != null) _startMarker!,
          if (_endMarker != null) _endMarker!,
        },
        polylines: {
          if (_polyline != null) _polyline!,
        },
        onTap: _onMapTapped,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
