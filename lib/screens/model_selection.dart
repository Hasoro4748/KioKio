import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/screens/counter/counter_page.dart';
import 'package:kiosk/screens/customer/product_list.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:path_provider/path_provider.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({super.key});

  Future<void> resetAllData() async {
    final db = AppDatabase();
    db.resetProducts();
    print('데이터 초기화 완료');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: PageColors.cateBack,
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon/appIcon2.png',
                    width: 200,
                  ),
                  const SizedBox(height: 16),
                  Text('편리하게 이용하는 키오스크 & POS 앱',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 32),
                  _buildModeButton(
                    context,
                    'POS 모드',
                    Icons.store,
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => CounterMainScreen()),
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildModeButton(context, '키오스크 모드', Icons.person, () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CustomerHomeScreen()));
                  }),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      await resetAllData();
                    },
                    child: Text('초기화'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await resetAllData();
                    },
                    child: Text('임의조정'),
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

  Widget _buildModeButton(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
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
