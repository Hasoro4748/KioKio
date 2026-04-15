import 'package:intl/intl.dart';

class TextUtil {
  static String money(int price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }
}
