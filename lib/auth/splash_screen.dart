import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget is now purely a UI placeholder.
    // The auth listener in `main.dart` handles all navigation logic.
    // When the app starts, this screen is shown while the listener
    // determines if the user is logged in or not, then navigates away automatically.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Loading..."),
          ],
        ),
      ),
    );
  }
}