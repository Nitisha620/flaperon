import 'package:flaperon/features/navigation/notifiers/navigation_notifier.dart';
import 'package:flaperon/features/navigation/presentation/widgets/navigation_instruction_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/models/navigation_state.dart';
import '../widgets/navigation_bottom_sheet.dart';
import '../widgets/navigation_search_card.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  String _mapStyle = "";
  GoogleMapController? _mapController;

  final _startController = TextEditingController();
  final _endController = TextEditingController();

  String remainingTimeStr = "--";
  int speedKmPerHour = 20;

  @override
  void initState() {
    super.initState();
  }

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
    final controller = ref.read(navigationProvider.notifier);

    await controller.startNavigation(
      _startController.text,
      _endController.text,
    );

    controller.fitRouteBounds();
    // controller.startFakeMovement(); // start movement after route is ready
  }

  @override
  Widget build(BuildContext context) {
    final isNavigating =
        ref.watch(navigationProvider.select((s) => s.isNavigating));

    final remainingRoute =
        ref.watch(navigationProvider.select((s) => s.remainingRoute));

    final markers = ref.watch(navigationProvider.select((s) => s.markers));

    final remainingTime =
        ref.watch(navigationProvider.select((s) => s.remainingTime));

    final remainingDistance =
        ref.watch(navigationProvider.select((s) => s.remainingDistance));

    final isLoading = ref.watch(navigationProvider.select((s) => s.isLoading));

    ref.listen<NavigationState>(
      navigationProvider,
      (previous, next) {
        // Navigation just started
        if (previous?.isNavigating == false && next.isNavigating == true) {
          ref.read(navigationProvider.notifier).fitRouteBounds();
          // ref.read(navigationProvider.notifier).startFakeMovement();
        }

        // Navigation ended
        if (previous?.isNavigating == true && next.isNavigating == false) {
          _startController.clear();
          _endController.clear();
        }
      },
    );
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
                ref.read(navigationProvider.notifier).mapController =
                    _mapController;
              },
              polylines: remainingRoute.length < 2
                  ? {}
                  : {
                      Polyline(
                        polylineId: const PolylineId("route1"),
                        points: remainingRoute,
                        color: Colors.yellowAccent.withAlpha(200),
                        width: 4,
                        jointType: JointType.round,
                        startCap: Cap.roundCap,
                        endCap: Cap.roundCap,
                        geodesic: true,
                      ),
                    },
              markers: markers,
              onCameraMoveStarted: () {
                ref.read(navigationProvider.notifier).setUserInteracted();
              },
            ),
            if (!isNavigating)
              NavigationSearchCard(
                startController: _startController,
                endController: _endController,
                isLoading: isLoading,
                onStartNavigation: _onStartNavigation,
              )
            // 2. Top Navigation Card
            else ...[
              NavigationInstructionCard(
                  start: _startController.text, end: _endController.text),
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
                child: _circularButton(Icons.explore_outlined, Colors.white),
              ),

              // 6. Persistent Navigation Overlay
              NavigationBottomSheet(
                remainingTime: remainingTime,
                remainingDistance: remainingDistance,
                onExit: () {
                  ref.read(navigationProvider.notifier).reset();

                  _startController.clear();
                  _endController.clear();
                },
              ),
            ],
          ],
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
}
