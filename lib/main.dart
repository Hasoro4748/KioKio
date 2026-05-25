import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/db/app_database.dart';
import 'package:kiosk/screens/model_selection.dart';
import 'package:kiosk/theme/common_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  final db = AppDatabase();
  await db.seedProducts();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kioder',
      theme: mTheme(),
      home: ModelSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
