import 'dart:ui';

import 'package:flutter/material.dart';

Color statusColor(String status) {
  switch (status) {
    case '처리중':
      return Colors.orange;
    case '승인':
      return Colors.green;
    case '취소':
      return Colors.red;
    default:
      return Colors.black;
  }
}

Color statusBackgroundColor(String status) {
  switch (status) {
    case '처리중':
      return Colors.orange.shade50;
    case '승인':
      return Colors.green.shade50;
    case '취소':
      return Colors.red.shade50;
    default:
      return Colors.white;
  }
}
