import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiosk/providers/product_providers.dart';
import 'package:kiosk/screens/customer/product_list.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CustomerHomeScreen();
  }
}
