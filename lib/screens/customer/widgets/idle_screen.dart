import 'package:flutter/material.dart';
import 'package:kiosk/theme/common_theme.dart';

class IdleScreen extends StatelessWidget {
  final VoidCallback onStart;
  const IdleScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PageColors.cateBack,
      body: InkWell(
        // 화면 어디든 터치하면 시작
        onTap: onStart,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/icon/appIcon2.png', width: 200),
              const SizedBox(height: 40),
              const Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: const Text(
                  textAlign: TextAlign.center,
                  '터치하여 주문을 시작하세요',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              const Text('Touch to start ordering',
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
