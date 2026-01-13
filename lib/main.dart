import 'dart:ui' as ui;

import 'package:flaperon/utils/marker_icon.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const NavigationMap());
}

class NavigationMap extends StatelessWidget {
  const NavigationMap({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const NavigationScreen(),
    );
  }
}

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  // Dummy Data
  final List<LatLng> _roadPoints = [
    LatLng(26.20591, 78.15044),
    LatLng(26.20780, 78.15090),
    LatLng(26.20910, 78.15250),
    LatLng(26.21150, 78.15310),
    LatLng(26.21320, 78.15550),
    LatLng(26.21580, 78.15680),
    LatLng(26.21750, 78.15950),
    LatLng(26.21520, 78.16280),
    LatLng(26.21250, 78.16420),
  ];
  Set<Marker> _markers = {};

  String _mapStyle = "";

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    DefaultAssetBundle.of(context)
        .loadString('assets/map_style.json')
        .then((value) {
      setState(() {
        _mapStyle = value;
      });
    });
  }

  List<LatLng> _getCurvedPoints(List<LatLng> points) {
    if (points.length < 3) return points;

    List<Offset> offsets =
        points.map((p) => Offset(p.latitude, p.longitude)).toList();

    final spline = CatmullRomSpline(offsets, tension: 0.3);

    const int samplesPerSegment = 15;
    final int totalSamples = (points.length - 1) * samplesPerSegment;

    List<LatLng> curvedPoints = [];
    for (int i = 0; i <= totalSamples; i++) {
      final double t = i / totalSamples;

      final Offset sampledPoint = spline.transform(t);

      curvedPoints.add(LatLng(sampledPoint.dx, sampledPoint.dy));
    }
    return curvedPoints;
  }

  Future<ui.Image> loadUiImage(String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final list = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(list, targetWidth: 100);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _loadCustomMarkers() async {
    // Load all descriptors in parallely
    final results = await Future.wait([
      loadUiImage('assets/destination.png'),
      getMarkerIcon(Colors.black,
          isIcon: true,
          icon: Icons.motorcycle_outlined,
          iconColor: Colors.yellowAccent),
      getMarkerIcon(const Color(0xFF007AFF),
          isIcon: true, icon: Icons.local_gas_station),
      getMarkerIcon(const Color(0xFF00C853), text: "S"),
      getMarkerIcon(const Color(0xFF00C853), text: "R"),
      getMarkerIcon(Colors.yellow[600]!,
          icon: Icons.handyman_outlined, isIcon: true),
      getMarkerIcon(const Color(0xFF00C853), text: "N"),
    ]);

    final destinationUiImage = results[0] as ui.Image;
    final destDescriptor = await getMarkerIcon(Colors.red,
        isIcon: true, icon: Icons.location_on, customImage: destinationUiImage);

    if (!mounted) return;
    setState(() {
      _markers = {
        Marker(
            markerId: const MarkerId('start'),
            position: _roadPoints[0],
            icon: results[1] as BitmapDescriptor,
            anchor: const Offset(0.6, 0.5)),
        Marker(
            markerId: const MarkerId('gas1'),
            position: _roadPoints[2],
            icon: results[2] as BitmapDescriptor,
            anchor: const Offset(0.5, 1.0)),
        Marker(
            markerId: const MarkerId('ptS'),
            position: _roadPoints[4],
            icon: results[3] as BitmapDescriptor,
            anchor: const Offset(0.5, 1.0)),
        Marker(
            markerId: const MarkerId('ptR'),
            position: _roadPoints[5],
            icon: results[4] as BitmapDescriptor,
            anchor: const Offset(0.5, 1.0)),
        Marker(
            markerId: const MarkerId('mn'),
            position: _roadPoints[6],
            icon: results[5] as BitmapDescriptor,
            anchor: const Offset(0.5, 1.0)),
        Marker(
            markerId: const MarkerId('ptN'),
            position: _roadPoints[7],
            icon: results[6] as BitmapDescriptor,
            anchor: const Offset(0.5, 1.0)),
        Marker(
            markerId: const MarkerId('dest'),
            position: _roadPoints[8],
            icon: destDescriptor,
            anchor: const Offset(0.25, 0.5)),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map
          GoogleMap(
            style: _mapStyle,
            initialCameraPosition: const CameraPosition(
              target: LatLng(
                  26.205913876718085, 78.15043985986162), // Dummy coordinates
              zoom: 14.8,
            ),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {},
            polylines: {
              Polyline(
                  polylineId: const PolylineId("route1"),
                  points: _getCurvedPoints(_roadPoints),
                  color: Colors.yellowAccent.withAlpha(200),
                  width: 4,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  geodesic: true),
            },
            markers: _markers,
          ),

          // 2. Top Navigation Card
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.zero,
                      bottomRight: Radius.circular(25),
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFF2A2A2A),
                        child: Icon(Icons.arrow_upward, color: Colors.yellow),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ABC Street",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF202124),
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            "Towards BCD Street",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF202124),
                              fontWeight: FontWeight.w300,
                              fontSize: 14,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        topLeft: Radius.zero,
                        topRight: Radius.zero,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Then take",
                          style: GoogleFonts.manrope(
                              color: Colors.black,
                              fontWeight: FontWeight.w500)),
                      SizedBox(width: 5),
                      Icon(Icons.turn_right, color: Colors.black),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Action Buttons (Right Side)
          Positioned(
            right: 12,
            top: MediaQuery.of(context).size.height * 0.25,
            child: Column(
              children: [
                _circularButton(Icons.sos, Colors.red,
                    label: "SOS", isText: true),
                const SizedBox(height: 20),
                _circularButton(
                  Icons.keyboard_arrow_down,
                  Colors.white,
                ),
              ],
            ),
          ),

          // 4. Speedometer (Bottom Left)
          Positioned(
            left: 20,
            bottom: 120,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("168",
                      style: GoogleFonts.manrope(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  Text("km/h",
                      style: GoogleFonts.manrope(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 5. Compass (Bottom Right)
          Positioned(
            right: 20,
            bottom: 130,
            child: _circularButton(Icons.explore_outlined, Colors.white),
          ),

          // 6. Persistent Navigation Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Exit Button (Close)
                  _iconCircle(
                    Icons.close,
                  ),
                  // Text Info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "2hr 51min",
                        style: GoogleFonts.manrope(
                          color: const ui.Color.fromARGB(255, 41, 191, 83),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "650 km • 2:40 am",
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF70757A),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Alternative Route
                  _iconCircle(
                    Icons.call_split,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularButton(IconData icon, Color color,
      {String? label, bool isText = false}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: isText ? 2 : 0),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: Center(
        child: isText
            ? Text(label!,
                style: GoogleFonts.manrope(
                    color: Colors.white, fontWeight: FontWeight.bold))
            : Icon(icon,
                color: color == Colors.white ? Colors.black : Colors.white),
      ),
    );
  }

  Widget _iconCircle(
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.yellowAccent.shade100, size: 30),
    );
  }
}
