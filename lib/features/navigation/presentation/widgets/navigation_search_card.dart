import 'package:flutter/material.dart';

class NavigationSearchCard extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController endController;
  final bool isLoading;
  final VoidCallback onStartNavigation;

  const NavigationSearchCard({
    super.key,
    required this.startController,
    required this.endController,
    required this.isLoading,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
              controller: startController,
              hint: "Start location",
              icon: Icons.trip_origin,
            ),
            const SizedBox(height: 12),
            _locationField(
              controller: endController,
              hint: "End location",
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onStartNavigation,
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
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.yellowAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
}
