import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NavigationBottomSheet extends StatelessWidget {
  final String remainingTime;
  final double remainingDistance;
  final VoidCallback onExit;

  const NavigationBottomSheet({
    super.key,
    required this.remainingTime,
    required this.remainingDistance,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onExit,
              child: _iconCircle(Icons.close),
            ),
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
                  remainingTime,
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF29BF53),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${remainingDistance.toStringAsPrecision(2)} km to destination",
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF70757A),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            _iconCircle(Icons.call_split),
          ],
        ),
      ),
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.yellowAccent, size: 30),
    );
  }
}
