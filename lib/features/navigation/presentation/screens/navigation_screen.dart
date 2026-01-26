import 'package:flaperon/features/navigation/controller/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  String _mapStyle = "";
  bool _showNavigation = false;
  GoogleMapController? _mapController;

  final _startController = TextEditingController();
  final _endController = TextEditingController();

  String remainingTimeStr = "--";
  int speedKmPerHour = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    DefaultAssetBundle.of(context)
        .loadString('assets/map_style.json')
        .then((value) {
      setState(() => _mapStyle = value);
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _onStartNavigation() async {
    if (_startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both locations")),
      );
      return;
    }
    final controller = context.read<NavigationController>();

    await controller.startNavigation(
      _startController.text,
      _endController.text,
    );

    controller.fitRouteBounds();
    controller.startFakeMovement(); // start movement after route is ready

    setState(() {
      _showNavigation = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navController = context.watch<NavigationController>();
    final navState = navController.state;
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Google Map
            GoogleMap(
              style: _mapStyle,
              initialCameraPosition: const CameraPosition(
                target: LatLng(26.205913876718085, 78.15043985986162),
                zoom: 12.8,
              ),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                context.read<NavigationController>().mapController =
                    _mapController;
              },
              polylines: navState.remainingRoute.length < 2
                  ? {}
                  : {
                      Polyline(
                        polylineId: const PolylineId("route1"),
                        points: navState.remainingRoute,
                        color: Colors.yellowAccent.withAlpha(200),
                        width: 4,
                        jointType: JointType.round,
                        startCap: Cap.roundCap,
                        endCap: Cap.roundCap,
                        geodesic: true,
                      ),
                    },
              markers: navState.markers,
              onCameraMoveStarted: () {
                context.read<NavigationController>().setUserInteracted();
              },
            ),
            !_showNavigation
                ? Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _locationField(
                            controller: _startController,
                            hint: "Start location",
                            icon: Icons.trip_origin,
                          ),
                          const SizedBox(height: 12),
                          _locationField(
                            controller: _endController,
                            hint: "End location",
                            icon: Icons.location_on,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _onStartNavigation();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.yellowAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Start Navigation"),
                                navState.isLoading
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation(
                                                Colors.yellowAccent),
                                          ),
                                        ),
                                      )
                                    : SizedBox()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                :
                // 2. Top Navigation Card
                Stack(
                    children: [
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
                                    child: Icon(Icons.arrow_upward,
                                        color: Colors.yellow),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _startController.text,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF202124),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 20,
                                          ),
                                        ),
                                        Text(
                                          "Towards ${_endController.text}",
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF202124),
                                            fontWeight: FontWeight.w300,
                                            fontSize: 14,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
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
                              Text(speedKmPerHour.toString(),
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
                        child: _circularButton(
                            Icons.explore_outlined, Colors.white),
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
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(40)),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 10)
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Exit Button (Close)
                              GestureDetector(
                                onTap: () {
                                  context.read<NavigationController>().reset();
                                  setState(() => _showNavigation = false);
                                  _startController.clear();
                                  _endController.clear();
                                },
                                child: _iconCircle(
                                  Icons.close,
                                ),
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
                                    navState.remainingTime,
                                    style: GoogleFonts.manrope(
                                      color: const Color(0xFF29BF53),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "${navState.remainingDistance.toStringAsPrecision(2)} km to destination",
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
                      )
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _locationField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
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
