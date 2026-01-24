import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/navigation/controller/navigation_controller.dart';
import 'features/navigation/presentation/screens/navigation_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NavigationController(),
        ),
      ],
      child: const NavigationMap(),
    ),
  );
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
