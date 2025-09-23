import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Blue background as per the image
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Te Apuesto Club',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                ), // White text for app name
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
