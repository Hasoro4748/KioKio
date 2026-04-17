import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiosk/screens/counter/counter_page.dart';
import 'package:kiosk/screens/customer/product_list.dart';
import 'package:path_provider/path_provider.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({super.key});
  Future<void> resetAllData() async {
    final dir = await getApplicationDocumentsDirectory();

    final productFile = File('${dir.path}/files/products.json');
    final orderFile = File('${dir.path}/files/orders.json');

    if (await productFile.exists()) {
      await productFile.delete();
    }

    if (await orderFile.exists()) {
      await orderFile.delete();
    }

    print('데이터 초기화 완료');
  }

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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 120, color: Colors.white),
                  SizedBox(height: 32),
                  const Text(
                    'Kio Kio',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text('키오스크앱',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 32),
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
                  _buildModeButton(
                      context, '키오스크 모드', Icons.person, Colors.green, () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CustomerHomeScreen()));
                  }),
                  ElevatedButton(
                    onPressed: () async {
                      await resetAllData();
                    },
                    child: Text('초기화'),
                  )
                ],
              ),
              Positioned(
                bottom: 16,
                left: 16,
                child: Text(
                  "개발자 : 하소로",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
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
