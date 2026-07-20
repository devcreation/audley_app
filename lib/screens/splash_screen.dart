import 'package:flutter/material.dart';
import '../core/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.teal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo centered
            ClipOval(
              child: Image.asset(
                'assets/icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flight_takeoff, size: 52, color: AppTheme.goldLight),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator below logo
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppTheme.goldLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
