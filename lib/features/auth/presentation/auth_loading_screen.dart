import 'package:flutter/material.dart';
import 'package:flutter_application_1/color.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: mainButtonColor,
            ),
            SizedBox(height: 24),
            Text(
              '로그인 중...',
              style: TextStyle(
                fontSize: 16,
                color: subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}