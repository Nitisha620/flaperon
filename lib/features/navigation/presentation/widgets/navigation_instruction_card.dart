import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NavigationInstructionCard extends StatelessWidget {
  final String start;
  final String end;

  const NavigationInstructionCard({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
              borderRadius: const BorderRadius.only(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        start,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF202124),
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        "Towards $end",
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
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Then take",
                  style: GoogleFonts.manrope(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.turn_right, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
