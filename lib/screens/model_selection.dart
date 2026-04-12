import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiosk/screens/counter/counter_page.dart';
import 'package:kiosk/screens/customer/product_list.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange[400]!, Colors.orange[700]!],
          ),
        ),
        child: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 120, color: Colors.white),
            SizedBox(height: 32),
            const Text(
              '키오스크 앱',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 64),
            _buildModeButton(
              context,
              '카운터 모드',
              Icons.store,
              Colors.blue,
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => CounterHomeScreen()),
              ),
            ),
            SizedBox(height: 24),
            _buildModeButton(context, '키오스크 모드', Icons.person, Colors.green,
                () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => CustomerHomeScreen()));
            })
          ],
        )),
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return Container(
      width: 280,
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
