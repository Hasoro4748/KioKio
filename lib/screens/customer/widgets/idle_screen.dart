import 'dart:io'; // File 클래스를 위해 추가
import 'package:flutter/material.dart';
import 'package:kiosk/theme/common_theme.dart';

class IdleScreen extends StatelessWidget {
  final VoidCallback onStart;
  final String welcomeMessage;
  final String logoPath; // 1. 로고 경로 필드 추가

  const IdleScreen({
    super.key,
    required this.onStart,
    required this.welcomeMessage,
    required this.logoPath, // 생성자 추가
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PageColors.cateBack,
      body: InkWell(
        onTap: onStart,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2. 로고 표시 로직 적용 (asset vs file 분기)
              SizedBox(
                width: 250,
                child: logoPath.isEmpty
                    ? Image.asset('assets/img/logo/logo1.png') // 기본 로고
                    : (logoPath.startsWith('assets/')
                        ? Image.asset(logoPath)
                        : Image.file(File(logoPath))), // 원격에서 받은 로고
              ),
              const SizedBox(height: 40),
              Text(
                welcomeMessage,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
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
